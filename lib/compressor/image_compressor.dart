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

/// কম্প্রেশনের ফলাফল মডেল
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
  }) : compressionRatio = originalSizeBytes > 0
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

/// থাম্বনেইল + মেইন ইমেজ রেজাল্ট
class ImageWithThumbnail {
  final CompressionResult mainImage;
  final CompressionResult? thumbnail;

  const ImageWithThumbnail({required this.mainImage, this.thumbnail});
}

/// কম্প্রেশন প্রিসেট কনফিগারেশন
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
  });
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
      'BondhuCompressionException[$type]: $message${originalError != null ? ' | Original: $originalError' : ''}';
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
  static const int _maxIterations = 15;

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

  /// মূল কম্প্রেশন মেথড — সব ফিচার এটি ব্যবহার করে
  Future<CompressionResult> compress({
    required File inputFile,
    CompressPreset? preset,
    void Function(double progress)? onProgress,
  }) async {
    preset ??= postPreset;
    final stopwatch = Stopwatch()..start();

    // 1. ইনপুট ভ্যালিডেশন
    await _validateInput(inputFile);

    final originalSize = await inputFile.length();

    // 2. যদি ইতিমধ্যে ছোট হয় এবং ফরম্যাট ঠিক থাকে, কম্প্রেস স্কিপ
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

    // 3. ট্রান্সপারেন্সি চেক
    final outputFormat =
        _hasTransparency(inputFile.path) && preset.format != CompressFormat.png
        ? CompressFormat.png
        : preset.format;

    // 4. স্মার্ট ইনিশিয়াল স্কেল ক্যালকুলেশন
    double scaleFactor = 1.0;
    if (originalSize > preset.targetSizeBytes) {
      scaleFactor = sqrt(preset.targetSizeBytes / originalSize);
      scaleFactor = scaleFactor.clamp(0.25, 1.0);
    }

    int currentWidth = (preset.maxWidth * scaleFactor).toInt();
    int currentHeight = (preset.maxHeight * scaleFactor).toInt();
    int currentQuality = 88;

    File? resultFile;
    int resultSize = originalSize;
    int iterations = 0;

    // 5. ইটারেটিভ কম্প্রেশন লুপ
    while (resultSize > preset.maxSizeBytes && iterations < _maxIterations) {
      iterations++;
      onProgress?.call(iterations / _maxIterations);

      // FIX #6: ডাইমেনশন চেক কম্প্রেসের আগে — বৃথা ইটারেশন বন্ধ
      if (currentWidth < 320 || currentHeight < 320) break;

      try {
        final compressedBytes = await FlutterImageCompress.compressWithFile(
          inputFile.path,
          minWidth: currentWidth,
          minHeight: currentHeight,
          quality: currentQuality,
          format: outputFormat,
          keepExif: !preset.stripExif,
          autoCorrectionAngle: preset.autoRotate,
        );

        if (compressedBytes == null) {
          throw const BondhuCompressionException(
            'Native compressor returned null. Possibly unsupported format or corrupted file.',
            type: CompressionErrorType.nativeCompressionFailed,
          );
        }

        // নতুন টেম্প ফাইলে লেখা
        final newFile = await _writeTempFile(
          compressedBytes,
          outputFormat,
          iterations,
        );
        resultSize = await newFile.length();

        // FIX #3: শুধু নিজের সেশনের আগের ফাইল ডিলিট — সিস্টেম-ওয়াইড স্ক্যান নয়
        if (resultFile != null) {
          try {
            await resultFile.delete();
          } catch (_) {}
        }
        resultFile = newFile;

        // FIX #2: কোয়ালিটি/ডাইমেনশন কমানো কম্প্রেসের পরে — তাহলে ৮৮ প্রথমেই ব্যবহৃত হবে
        if (resultSize > preset.maxSizeBytes) {
          if (currentQuality > preset.minQuality) {
            currentQuality = (currentQuality - 7).clamp(preset.minQuality, 100);
          } else {
            currentWidth = (currentWidth * 0.82).toInt();
            currentHeight = (currentHeight * 0.82).toInt();
          }
        }
      } catch (e) {
        // FIX #5: ফেইলে টেম্প ফাইল ক্লিনআপ — লিক প্রতিরোধ
        if (resultFile != null) {
          try {
            await resultFile.delete();
          } catch (_) {}
        }
        throw BondhuCompressionException(
          'Compression failed at iteration $iterations',
          type: CompressionErrorType.nativeCompressionFailed,
          originalError: e,
        );
      }
    }

    // 6. ফাইনাল চেক
    if (resultSize > preset.maxSizeBytes || resultFile == null) {
      // FIX #5: ফেইলে টেম্প ফাইল ক্লিনআপ
      if (resultFile != null) {
        try {
          await resultFile.delete();
        } catch (_) {}
      }
      throw BondhuCompressionException(
        'Failed to compress below ${preset.maxSizeBytes ~/ 1024}KB '
        'after $_maxIterations attempts. Final: ${(resultSize / 1024).toStringAsFixed(1)}KB',
        type: CompressionErrorType.unableToReachTarget,
      );
    }

    stopwatch.stop();

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

  Future<CompressionResult> compressForStory(
    File file, {
    void Function(double)? onProgress,
  }) => compress(inputFile: file, preset: storyPreset, onProgress: onProgress);

  Future<CompressionResult> compressForPost(
    File file, {
    void Function(double)? onProgress,
  }) => compress(inputFile: file, preset: postPreset, onProgress: onProgress);

  Future<CompressionResult> compressForChat(
    File file, {
    void Function(double)? onProgress,
  }) => compress(inputFile: file, preset: chatPreset, onProgress: onProgress);

  Future<CompressionResult> compressForAvatar(
    File file, {
    void Function(double)? onProgress,
  }) => compress(inputFile: file, preset: avatarPreset, onProgress: onProgress);

  Future<CompressionResult> compressForBanner(
    File file, {
    void Function(double)? onProgress,
  }) => compress(inputFile: file, preset: bannerPreset, onProgress: onProgress);

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
      onProgress: (p) => onProgress?.call(p * 0.7),
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
        final thumbFile = await _writeTempFile(
          thumbBytes,
          CompressFormat.webp,
          99,
        );
        final thumbSize = await thumbFile.length();

        // FIX #4: আসল অ্যাসপেক্ট রেশিও থেকে হাইট ক্যালকুলেশন
        final aspectRatio = mainResult.height / mainResult.width;
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
      // থাম্বনেইল ফেইল হলে শুধু মেইন ইমেজ রিটার্ন
    }

    return ImageWithThumbnail(mainImage: mainResult);
  }

  // ---------------------------------------------------------------------------
  // BATCH PROCESSING
  // ---------------------------------------------------------------------------

  Future<List<CompressionResult>> compressBatch({
    required List<File> files,
    CompressPreset? preset,
    void Function(int completed, int total)? onBatchProgress,
  }) async {
    final results = <CompressionResult>[];

    for (var i = 0; i < files.length; i++) {
      try {
        final result = await compress(
          inputFile: files[i],
          preset: preset ?? postPreset,
        );
        results.add(result);
      } on BondhuCompressionException catch (e) {
        if (kDebugMode) {
          debugPrint('Batch compression failed for index $i: $e');
        }
      }
      onBatchProgress?.call(i + 1, files.length);
    }

    return results;
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
    final bondhuTemps = tempDir.listSync().whereType<File>().where(
      (f) => p.basename(f.path).startsWith('bondhu_img_'),
    );

    for (final file in bondhuTemps) {
      try {
        await file.delete();
      } catch (_) {}
    }
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
        'File too large: ${(size / 1048576).toStringAsFixed(1)}MB. '
        'Max allowed: ${maxInputSizeBytes ~/ 1048576}MB',
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

  bool _hasTransparency(String filePath) {
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
    final filePath = p.join(tempDir.path, fileName);

    final file = File(filePath);
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
}
