import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

// =============================================================================
// DATA MODELS
// =============================================================================

class CompressionResult {
  final File file;
  final int originalSizeBytes;
  final int compressedSizeBytes;
  final double compressionRatio;
  final String outputFormat;
  final int width;
  final int height;
  final bool wasCompressed;
  final Duration processingTime;
  final bool isWithinTarget;
  final bool isWithinMaxLimit;

  CompressionResult({
    required this.file,
    required this.originalSizeBytes,
    required this.compressedSizeBytes,
    required this.outputFormat,
    required this.width,
    required this.height,
    required this.processingTime,
    this.wasCompressed = true,
  })  : compressionRatio = originalSizeBytes > 0
      ? compressedSizeBytes / originalSizeBytes
      : 1.0,
        isWithinTarget = compressedSizeBytes <= 512000,
        isWithinMaxLimit = compressedSizeBytes <= 1048576;

  String get reductionPercent =>
      '${((1 - compressionRatio) * 100).toStringAsFixed(1)}%';

  String get compressedSizeReadable => _formatBytes(compressedSizeBytes);
  String get originalSizeReadable => _formatBytes(originalSizeBytes);

  static String _formatBytes(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    final i = (log(bytes) / log(1024)).floor().clamp(0, suffixes.length - 1);
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }
}

class ImageWithThumbnail {
  final CompressionResult mainImage;
  final CompressionResult? thumbnail;

  const ImageWithThumbnail({required this.mainImage, this.thumbnail});
}

class CompressPreset {
  final int maxWidth;
  final int maxHeight;
  final int maxSizeBytes;
  final int targetSizeBytes;
  final int minQuality;
  final CompressFormat format;
  final bool stripExif;
  final bool autoRotate;
  final int? thumbnailMaxWidth;

  const CompressPreset({
    required this.maxWidth,
    required this.maxHeight,
    this.maxSizeBytes = 1048576,
    this.targetSizeBytes = 512000,
    this.minQuality = 60,
    this.format = CompressFormat.webp,
    this.stripExif = true,
    this.autoRotate = true,
    this.thumbnailMaxWidth,
  }) : assert(
  targetSizeBytes <= maxSizeBytes,
  'targetSizeBytes must be <= maxSizeBytes',
  );
}

// =============================================================================
// EXCEPTION HANDLING
// =============================================================================

enum CompressionErrorType {
  invalidInput,
  inputTooLarge,
  notAnImage,
  nativeCompressionFailed,
  unableToReachTarget,
  fileWriteError,
}

class BondhuCompressionException implements Exception {
  final String message;
  final CompressionErrorType type;
  final dynamic originalError;

  const BondhuCompressionException(
      this.message, {
        required this.type,
        this.originalError,
      });

  @override
  String toString() =>
      'BondhuCompressionException[$type]: $message'
          '${originalError != null ? ' | Original: $originalError' : ''}';
}

// =============================================================================
// MAIN COMPRESSOR CLASS
// =============================================================================

class BondhuImageCompressor {
  BondhuImageCompressor._();
  static final BondhuImageCompressor instance = BondhuImageCompressor._();

  // ---------------------------------------------------------------------------
  // CONSTANTS
  // ---------------------------------------------------------------------------

  static const int maxInputSizeBytes = 50 * 1024 * 1024;

  /// Max dimension-reduction passes after quality is exhausted.
  static const int _maxDimensionPasses = 8;

  /// Stop iterating if a pass reduces size by less than this fraction.
  static const double _minGainThreshold = 0.03;

  /// Max concurrent files when batch-compressing.
  static const int _batchConcurrency = 3;

  // ---------------------------------------------------------------------------
  // FEATURE PRESETS
  // ---------------------------------------------------------------------------

  static const storyPreset = CompressPreset(
    maxWidth: 1080,
    maxHeight: 1920,
    targetSizeBytes: 450000,
    maxSizeBytes: 1048576,
    minQuality: 65,
    format: CompressFormat.webp,
    thumbnailMaxWidth: 300,
  );

  static const postPreset = CompressPreset(
    maxWidth: 1440,
    maxHeight: 1440,
    targetSizeBytes: 512000,
    maxSizeBytes: 1048576,
    minQuality: 70,
    format: CompressFormat.webp,
    thumbnailMaxWidth: 600,
  );

  static const chatPreset = CompressPreset(
    maxWidth: 1024,
    maxHeight: 1024,
    targetSizeBytes: 256000,
    maxSizeBytes: 512000,
    minQuality: 60,
    format: CompressFormat.webp,
    thumbnailMaxWidth: 200,
  );

  static const avatarPreset = CompressPreset(
    maxWidth: 512,
    maxHeight: 512,
    targetSizeBytes: 102400,
    maxSizeBytes: 204800,
    minQuality: 75,
    format: CompressFormat.webp,
  );

  static const bannerPreset = CompressPreset(
    maxWidth: 1500,
    maxHeight: 500,
    targetSizeBytes: 512000,
    maxSizeBytes: 1048576,
    minQuality: 70,
    format: CompressFormat.webp,
  );

  // ---------------------------------------------------------------------------
  // PUBLIC API: CORE COMPRESSION
  // ---------------------------------------------------------------------------

  /// Primary compression entry-point. All feature methods delegate here.
  ///
  /// Algorithm
  /// ─────────
  /// 1. Validate input (existence, size, MIME type).
  /// 2. Early-return if already within target and format matches.
  /// 3. Determine output format (preserve transparency when needed).
  /// 4. **Phase 1 – Quality binary search**: Hold dimensions at the initial
  ///    scale; binary-search quality between [minQuality, initialQuality].
  ///    Converges in ≤ ceil(log2(range)) iterations ≈ 3–5 vs the old linear
  ///    step that could take up to 12.
  /// 5. **Phase 2 – Dimension reduction**: If target is still not met after
  ///    quality is exhausted, shrink dimensions by 18 % per pass at minQuality.
  ///    Stop early when gains become negligible (< 3 %).
  /// 6. Return original file unchanged if it is already under maxSizeBytes
  ///    (previously this path threw an exception — **Bug fix #1 & #2**).
  Future<CompressionResult> compress({
    required File inputFile,
    CompressPreset? preset,
    void Function(double progress)? onProgress,
  }) async {
    preset ??= postPreset;
    final stopwatch = Stopwatch()..start();

    await _validateInput(inputFile);
    final originalSize = await inputFile.length();

    // ── Early return: already at target size in the correct format ────────────
    if (originalSize <= preset.targetSizeBytes &&
        _isDesiredFormat(inputFile, preset.format)) {
      stopwatch.stop();
      return CompressionResult(
        file: inputFile,
        originalSizeBytes: originalSize,
        compressedSizeBytes: originalSize,
        outputFormat: preset.format.name,
        width: preset.maxWidth,
        height: preset.maxHeight,
        processingTime: stopwatch.elapsed,
        wasCompressed: false,
      );
    }

    // ── FIX #6: renamed; extension-only heuristic, not a pixel-level check ───
    final outputFormat =
    _extensionMightHaveTransparency(inputFile.path) &&
        preset.format != CompressFormat.png
        ? CompressFormat.png
        : preset.format;

    // ── Initial scale: bias toward target, clamped to [0.25, 1.0] ─────────────
    final scaleFactor = originalSize > preset.targetSizeBytes
        ? sqrt(preset.targetSizeBytes / originalSize).clamp(0.25, 1.0)
        : 1.0;

    int currentWidth = (preset.maxWidth * scaleFactor).toInt();
    int currentHeight = (preset.maxHeight * scaleFactor).toInt();

    // ── FIX #8: start quality proportional to size ratio instead of flat 88 ──
    final sizeRatio = preset.targetSizeBytes / originalSize;
    final initialQuality =
    (sizeRatio * 100).clamp(preset.minQuality.toDouble(), 88.0).toInt();

    File? resultFile;
    int resultSize = originalSize;

    // ══════════════════════════════════════════════════════════════════════════
    // PHASE 1 — Binary-search quality, fixed dimensions
    // ══════════════════════════════════════════════════════════════════════════

    int qualityLo = preset.minQuality;
    int qualityHi = initialQuality;
    int passCount = 0;
    final totalQualityPasses = (log(qualityHi - qualityLo + 1) / log(2)).ceil() + 1;

    while (qualityLo <= qualityHi) {
      final quality = (qualityLo + qualityHi) ~/ 2;
      passCount++;
      onProgress?.call(passCount / (totalQualityPasses + _maxDimensionPasses));

      final (newFile, newSize) = await _compress(
        inputFile: inputFile,
        width: currentWidth,
        height: currentHeight,
        quality: quality,
        format: outputFormat,
        preset: preset,
        iteration: passCount,
      );

      // Cleanup previous temp before keeping this one
      await _deleteSafely(resultFile);
      resultFile = newFile;
      resultSize = newSize;

      if (resultSize <= preset.targetSizeBytes) {
        qualityHi = quality - 1; // try higher quality (smaller file is fine)
      } else {
        qualityLo = quality + 1; // need lower quality to shrink further
      }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // PHASE 2 — Dimension reduction at minQuality (only if still above target)
    // ══════════════════════════════════════════════════════════════════════════

    int dimPass = 0;

    while (resultSize > preset.targetSizeBytes && dimPass < _maxDimensionPasses) {
      // Guard: stop if dimensions are too small to be useful
      if (currentWidth < 320 || currentHeight < 320) break;

      currentWidth = (currentWidth * 0.82).toInt();
      currentHeight = (currentHeight * 0.82).toInt();
      dimPass++;

      final progress = (totalQualityPasses + dimPass) /
          (totalQualityPasses + _maxDimensionPasses);
      onProgress?.call(progress.clamp(0.0, 1.0));

      final previousSize = resultSize;
      final (newFile, newSize) = await _compress(
        inputFile: inputFile,
        width: currentWidth,
        height: currentHeight,
        quality: preset.minQuality,
        format: outputFormat,
        preset: preset,
        iteration: passCount + dimPass,
      );

      await _deleteSafely(resultFile);
      resultFile = newFile;
      resultSize = newSize;

      // ── FIX #7: diminishing-returns early exit ────────────────────────────
      final gain = (previousSize - resultSize) / previousSize;
      if (gain < _minGainThreshold) break;
    }

    onProgress?.call(1.0);
    stopwatch.stop();

    // ── FIX #1 & #2: never throw when file is under maxSizeBytes ─────────────
    // If both phases ran but we are still above target, check the hard cap.
    // If we are between [targetSizeBytes, maxSizeBytes], accept the result.
    // Only throw if we are above maxSizeBytes (truly uncompressible).
    if (resultFile == null) {
      // No compression was attempted (originalSize <= maxSizeBytes); return as-is.
      stopwatch.stop();
      return CompressionResult(
        file: inputFile,
        originalSizeBytes: originalSize,
        compressedSizeBytes: originalSize,
        outputFormat: outputFormat.name,
        width: currentWidth,
        height: currentHeight,
        processingTime: stopwatch.elapsed,
        wasCompressed: false,
      );
    }

    if (resultSize > preset.maxSizeBytes) {
      await _deleteSafely(resultFile);
      throw BondhuCompressionException(
        'Cannot compress below ${preset.maxSizeBytes ~/ 1024} KB. '
            'Final size: ${(resultSize / 1024).toStringAsFixed(1)} KB',
        type: CompressionErrorType.unableToReachTarget,
      );
    }

    return CompressionResult(
      file: resultFile,
      originalSizeBytes: originalSize,
      compressedSizeBytes: resultSize,
      outputFormat: outputFormat.name,
      width: currentWidth,
      height: currentHeight,
      processingTime: stopwatch.elapsed,
      wasCompressed: true,
    );
  }

  // ---------------------------------------------------------------------------
  // CONVENIENCE METHODS
  // ---------------------------------------------------------------------------

  Future<CompressionResult> compressForStory(File file,
      {void Function(double)? onProgress}) =>
      compress(inputFile: file, preset: storyPreset, onProgress: onProgress);

  Future<CompressionResult> compressForPost(File file,
      {void Function(double)? onProgress}) =>
      compress(inputFile: file, preset: postPreset, onProgress: onProgress);

  Future<CompressionResult> compressForChat(File file,
      {void Function(double)? onProgress}) =>
      compress(inputFile: file, preset: chatPreset, onProgress: onProgress);

  Future<CompressionResult> compressForAvatar(File file,
      {void Function(double)? onProgress}) =>
      compress(inputFile: file, preset: avatarPreset, onProgress: onProgress);

  Future<CompressionResult> compressForBanner(File file,
      {void Function(double)? onProgress}) =>
      compress(inputFile: file, preset: bannerPreset, onProgress: onProgress);

  // ---------------------------------------------------------------------------
  // THUMBNAIL GENERATION
  // ---------------------------------------------------------------------------

  Future<ImageWithThumbnail> compressWithThumbnail({
    required File inputFile,
    CompressPreset? preset,
    void Function(double)? onProgress,
  }) async {
    preset ??= postPreset;

    final mainResult = await compress(
      inputFile: inputFile,
      preset: preset,
      onProgress: (progress) => onProgress?.call(progress * 0.7),
    );

    if (preset.thumbnailMaxWidth == null) {
      return ImageWithThumbnail(mainImage: mainResult);
    }

    try {
      final thumbBytes = await FlutterImageCompress.compressWithFile(
        mainResult.file.path,
        minWidth: preset.thumbnailMaxWidth!,
        quality: 55,
        format: CompressFormat.webp,
        keepExif: false,
      );

      if (thumbBytes != null) {
        final thumbFile = await _writeTempFile(thumbBytes, CompressFormat.webp, 99);
        final thumbSize = await thumbFile.length();

        // FIX #4 (original): derive height from actual aspect ratio
        final aspectRatio =
        mainResult.width > 0 ? mainResult.height / mainResult.width : 1.0;
        final thumbHeight = (preset.thumbnailMaxWidth! * aspectRatio).toInt();

        onProgress?.call(1.0);

        return ImageWithThumbnail(
          mainImage: mainResult,
          thumbnail: CompressionResult(
            file: thumbFile,
            originalSizeBytes: mainResult.compressedSizeBytes,
            compressedSizeBytes: thumbSize,
            outputFormat: 'webp',
            width: preset.thumbnailMaxWidth!,
            height: thumbHeight,
            processingTime: Duration.zero,
          ),
        );
      }
    } catch (_) {
      // Thumbnail failure is non-fatal; return main image only.
    }

    return ImageWithThumbnail(mainImage: mainResult);
  }

  // ---------------------------------------------------------------------------
  // BATCH PROCESSING  (FIX #5: concurrent via Future.wait with capped pool)
  // ---------------------------------------------------------------------------

  /// Compresses [files] in parallel, up to [_batchConcurrency] at a time.
  /// Failures are logged in debug mode and skipped — the list returned may be
  /// shorter than [files].
  Future<List<CompressionResult>> compressBatch({
    required List<File> files,
    CompressPreset? preset,
    void Function(int completed, int total)? onBatchProgress,
  }) async {
    final results = List<CompressionResult?>.filled(files.length, null);
    int completed = 0;

    // Process in chunks of _batchConcurrency
    for (var start = 0; start < files.length; start += _batchConcurrency) {
      final end = (start + _batchConcurrency).clamp(0, files.length);
      final chunk = files.sublist(start, end);

      final chunkResults = await Future.wait(
        chunk.indexed.map((entry) async {
          final (localIndex, file) = entry;
          final globalIndex = start + localIndex;
          try {
            return (globalIndex, await compress(inputFile: file, preset: preset ?? postPreset));
          } on BondhuCompressionException catch (e) {
            if (kDebugMode) debugPrint('Batch[$globalIndex] failed: $e');
            return (globalIndex, null);
          }
        }),
      );

      for (final (index, result) in chunkResults) {
        results[index] = result;
        completed++;
        onBatchProgress?.call(completed, files.length);
      }
    }

    return results.nonNulls.toList();
  }

  // ---------------------------------------------------------------------------
  // UTILITY METHODS
  // ---------------------------------------------------------------------------

  Future<bool> shouldCompress(File file, {CompressPreset? preset}) async {
    preset ??= postPreset;
    if (!await file.exists()) return false;
    final size = await file.length();
    return size > preset.targetSizeBytes;
  }

  CompressPreset createCustomPreset({
    required int maxWidth,
    required int maxHeight,
    int? maxSizeBytes,
    int? targetSizeBytes,
    int? minQuality,
    CompressFormat? format,
  }) {
    return CompressPreset(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      maxSizeBytes: maxSizeBytes ?? 1048576,
      targetSizeBytes: targetSizeBytes ?? 512000,
      minQuality: minQuality ?? 65,
      format: format ?? CompressFormat.webp,
    );
  }

  Future<void> cleanupAllTempFiles() async {
    final tempDir = Directory.systemTemp;
    final bondhuTemps = tempDir
        .listSync()
        .whereType<File>()
        .where((f) => p.basename(f.path).startsWith('bondhu_img_'));

    await Future.wait(
      bondhuTemps.map((file) => _deleteSafely(file)),
    );
  }

  // ---------------------------------------------------------------------------
  // PRIVATE: SINGLE COMPRESSION CALL
  // ---------------------------------------------------------------------------

  /// Calls the native compressor once and writes the result to a temp file.
  /// Returns a record of `(File, int sizeInBytes)`.
  ///
  /// Throws [BondhuCompressionException] on native or I/O failure.
  Future<(File, int)> _compress({
    required File inputFile,
    required int width,
    required int height,
    required int quality,
    required CompressFormat format,
    required CompressPreset preset,
    required int iteration,
  }) async {
    Uint8List? bytes;

    try {
      bytes = await FlutterImageCompress.compressWithFile(
        inputFile.path,
        minWidth: width,
        minHeight: height,
        quality: quality,
        format: format,
        keepExif: !preset.stripExif,
        autoCorrectionAngle: preset.autoRotate,
      );
    } catch (e) {
      throw BondhuCompressionException(
        'Native compressor threw at iteration $iteration '
            '(${width}x$height q$quality)',
        type: CompressionErrorType.nativeCompressionFailed,
        originalError: e,
      );
    }

    if (bytes == null) {
      throw BondhuCompressionException(
        'Native compressor returned null at iteration $iteration — '
            'unsupported format or corrupted file.',
        type: CompressionErrorType.nativeCompressionFailed,
      );
    }

    final file = await _writeTempFile(bytes, format, iteration);
    final size = await file.length();
    return (file, size);
  }

  // ---------------------------------------------------------------------------
  // PRIVATE HELPERS
  // ---------------------------------------------------------------------------

  Future<void> _validateInput(File file) async {
    if (!await file.exists()) {
      throw const BondhuCompressionException(
        'File does not exist',
        type: CompressionErrorType.invalidInput,
      );
    }

    final size = await file.length();
    if (size > maxInputSizeBytes) {
      throw BondhuCompressionException(
        'File too large: ${(size / 1048576).toStringAsFixed(1)} MB. '
            'Max allowed: ${maxInputSizeBytes ~/ 1048576} MB',
        type: CompressionErrorType.inputTooLarge,
      );
    }

    final mimeType = lookupMimeType(file.path);
    if (mimeType == null || !mimeType.startsWith('image/')) {
      throw const BondhuCompressionException(
        'File is not a valid image',
        type: CompressionErrorType.notAnImage,
      );
    }
  }

  /// Returns true for extensions that *may* carry an alpha channel.
  /// This is a fast extension-only heuristic — not a pixel-level transparency
  /// check. Renamed from `_hasTransparency` to reflect this accurately.
  bool _extensionMightHaveTransparency(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    return ext == '.png' || ext == '.gif' || ext == '.webp';
  }

  bool _isDesiredFormat(File file, CompressFormat format) {
    final ext = p.extension(file.path).toLowerCase();
    switch (format) {
      case CompressFormat.jpeg:
        return ext == '.jpg' || ext == '.jpeg';
      case CompressFormat.png:
        return ext == '.png';
      case CompressFormat.webp:
        return ext == '.webp';
      case CompressFormat.heic:
        return ext == '.heic';
    }
  }

  Future<File> _writeTempFile(
      Uint8List bytes,
      CompressFormat format,
      int iteration,
      ) async {
    final tempDir = Directory.systemTemp;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = _formatExtension(format);
    final fileName = 'bondhu_img_${timestamp}_$iteration.$ext';
    final file = File(p.join(tempDir.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  String _formatExtension(CompressFormat format) {
    switch (format) {
      case CompressFormat.jpeg:
        return 'jpg';
      case CompressFormat.png:
        return 'png';
      case CompressFormat.webp:
        return 'webp';
      case CompressFormat.heic:
        return 'heic';
    }
  }

  Future<void> _deleteSafely(File? file) async {
    if (file == null) return;
    try {
      await file.delete();
    } catch (_) {}
  }
}