import 'dart:io';

import 'package:bondhu/compressor/image_compressor.dart';
import 'package:bondhu/features/stories/models/story_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoryPublishScreen extends StatefulWidget {
  const StoryPublishScreen({super.key});

  @override
  State<StoryPublishScreen> createState() => _StoryPublishScreenState();
}

class _StoryPublishScreenState extends State<StoryPublishScreen> {
  final _textController = TextEditingController();
  final _musicUrlController = TextEditingController();
  final _locationController = TextEditingController();

  // FIX #5: ImagePicker is a stateless utility — one instance per State is correct.
  // Instantiating it inside _pickImage on every call is wasteful.
  final _picker = ImagePicker();

  final _supabase = Supabase.instance.client;

  XFile? _selectedImage;
  bool _isPublishing = false;
  String _selectedFont = 'Roboto';
  String _selectedColor = '#FFFFFF';

  final List<Map<String, String>> _fontOptions = [
    {'name': 'Roboto', 'display': 'Default'},
    {'name': 'Courier', 'display': 'Classic'},
    {'name': 'DancingScript', 'display': 'Cursive'},
    {'name': 'Impact', 'display': 'Bold'},
  ];

  final List<Map<String, String>> _colorOptions = [
    {'name': 'White', 'hex': '#FFFFFF'},
    {'name': 'Red', 'hex': '#FF0000'},
    {'name': 'Cyan', 'hex': '#00FFFF'},
    {'name': 'Yellow', 'hex': '#FFFF00'},
    {'name': 'Black', 'hex': '#000000'},
  ];

  @override
  void dispose() {
    _textController.dispose();
    _musicUrlController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    // FIX #5 (cont.): use the shared _picker field instead of a new instance.
    final image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  void _showImageSourceSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _publish() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    setState(() => _isPublishing = true);

    // FIX #1: Track the compressed file outside the try block so the finally
    // clause can always clean up, even when an exception is thrown after
    // compression but before (or during) the upload or edge function call.
    File? compressedFile;

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // =========================================================================
      // 1. COMPRESS IMAGE
      // =========================================================================
      final originalFile = File(_selectedImage!.path);

      final compressionResult = await BondhuImageCompressor.instance
          .compressForStory(
        originalFile,
        onProgress: (progress) {
          debugPrint('Compressing: ${(progress * 100).toStringAsFixed(0)}%');
        },
      );

      // FIX #1 (cont.): assign here so finally can see it.
      compressedFile = compressionResult.file;
      final String outputFormat = compressionResult.outputFormat;

      debugPrint(
        'Compressed: ${compressionResult.originalSizeReadable} → '
            '${compressionResult.compressedSizeReadable} '
            '(${compressionResult.reductionPercent} reduction)',
      );

      // =========================================================================
      // 2. UPLOAD TO SUPABASE
      // =========================================================================
      final String fileExt = outputFormat == 'jpeg' ? '.jpg' : '.$outputFormat';
      final String contentType = 'image/$outputFormat';
      final filePath =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}$fileExt';

      await _supabase.storage.from('stories').upload(
        filePath,
        compressedFile,
        fileOptions: FileOptions(upsert: false, contentType: contentType),
      );

      // =========================================================================
      // 3. GET URL & CALL EDGE FUNCTION
      // =========================================================================
      final imageUrl =
      _supabase.storage.from('stories').getPublicUrl(filePath);

      final response = await _supabase.functions.invoke(
        'create-story',
        body: {
          'image_url': imageUrl,
          'text_overlay': _textController.text.trim().isEmpty
              ? null
              : _textController.text.trim(),
          'music_url': _musicUrlController.text.trim().isEmpty
              ? null
              : _musicUrlController.text.trim(),
          'location': _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          'font_family': _selectedFont,
          'text_color': _selectedColor,
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to create story: ${response.data}');
      }

      // FIX #2: Guard against a null response.data before passing it to
      // StoryModel.fromJson. The edge function should always return a body on
      // HTTP 200, but a null here would throw a TypeError and skip the finally
      // cleanup, leaking the temp file (compounded with FIX #1).
      final responseData = response.data;
      if (responseData == null) {
        throw Exception('Edge function returned null response data');
      }

      if (mounted) {
        final newStory = StoryModel.fromJson(responseData, user.id);
        Navigator.of(context).pop(newStory);
      }
    } on BondhuCompressionException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Compression failed: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish: $e')),
        );
      }
    } finally {
      // FIX #1 (cont.): always delete the temp compressed file, regardless of
      // whether the upload or edge function succeeded or threw.
      if (compressedFile != null) {
        try {
          await compressedFile.delete();
        } catch (_) {}
      }
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('New Story'),
        actions: [
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: _isPublishing ? null : _publish,
                child: _isPublishing
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text('Publish'),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _selectedImage != null
                ? _buildImagePreview(theme)
                : _buildImagePicker(theme),
          ),
          if (_selectedImage != null) _buildTextInput(theme),
        ],
      ),
    );
  }

  Widget _buildImagePicker(ThemeData theme) {
    return Center(
      child: InkWell(
        onTap: _showImageSourceSheet,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text('Select a photo', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Choose from gallery or take a new photo',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(ThemeData theme) {
    return SingleChildScrollView(
      child: Stack(
        // FIX #3: Stack must not have unbounded height from Positioned children.
        // Using fit: StackFit.loose keeps the Stack sized to its non-Positioned
        // children (the image), while Positioned children overlay correctly.
        fit: StackFit.loose,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: Image.file(
              File(_selectedImage!.path),
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
          // FIX #3 (cont.): replaced Center(heightFactor:2.5) with
          // Positioned.fill + Center so the text is correctly centered over the
          // image regardless of screen size, and does not affect Stack sizing.
          if (_textController.text.trim().isNotEmpty)
            Positioned.fill(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _textController.text.trim(),
                    style: TextStyle(
                      color: _hexToColor(_selectedColor),
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      fontFamily: _selectedFont,
                      shadows: const [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 8,
                          color: Colors.black87,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: ActionChip(
                avatar: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('Change photo'),
                onPressed: _isPublishing ? null : _showImageSourceSheet,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput(ThemeData theme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _textController,
              onChanged: (_) => setState(() {}),
              enabled: !_isPublishing,
              decoration: InputDecoration(
                hintText: 'Add text to your story (optional)',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.6,
                  ),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 1,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    enabled: !_isPublishing,
                    decoration: InputDecoration(
                      hintText: 'Location',
                      prefixIcon: const Icon(
                        Icons.location_on_outlined,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _musicUrlController,
                    enabled: !_isPublishing,
                    decoration: InputDecoration(
                      hintText: 'Music URL',
                      prefixIcon: const Icon(
                        Icons.music_note_outlined,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Font: ', style: TextStyle(fontSize: 12)),
                ..._fontOptions.map(
                      (f) => GestureDetector(
                    onTap: () => setState(() => _selectedFont = f['name']!),
                    child: Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedFont == f['name']
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        f['display']!,
                        style: TextStyle(
                          fontFamily: f['name'],
                          fontSize: 12,
                          color: _selectedFont == f['name']
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Color: ', style: TextStyle(fontSize: 12)),
                ..._colorOptions.map(
                      (c) => GestureDetector(
                    onTap: () => setState(() => _selectedColor = c['hex']!),
                    child: Container(
                      margin: const EdgeInsets.only(left: 8),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _hexToColor(c['hex']!),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == c['hex']
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.send_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: _isPublishing ? null : _publish,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // FIX #4: Added length validation and a safe fallback so a malformed hex
  // string (wrong length, non-hex characters) no longer throws a FormatException
  // and crashes the widget build. Falls back to opaque white.
  Color _hexToColor(String hexString) {
    final hex = hexString.replaceAll('#', '');
    if (hex.length != 6) return Colors.white;
    final value = int.tryParse('FF$hex', radix: 16);
    return value != null ? Color(value) : Colors.white;
  }
}