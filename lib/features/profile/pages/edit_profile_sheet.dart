import 'dart:io';

import 'package:bondhu/compressor/image_compressor.dart';
import 'package:bondhu/config/theme.dart';
import 'package:bondhu/features/profile/models/user_profile.dart';
import 'package:bondhu/features/profile/repositories/profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key, required this.profile});
  final UserProfile profile;

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _displayNameCtl;
  late final TextEditingController _bioCtl;
  late final TextEditingController _websiteCtl;

  String _selectedGender = 'PREFER_NOT_TO_SAY';

  // ── Avatar state ──────────────────────────────────────────────────────────
  /// Locally picked + compressed avatar file, ready to upload on save.
  File?  _pendingAvatarFile;
  bool   _isCompressingAvatar = false;

  // ── Save state ────────────────────────────────────────────────────────────
  bool _isSaving = false;

  static const _genderOptions = {
    'MALE':              'পুরুষ',
    'FEMALE':            'মহিলা',
    'NON_BINARY':        'নন-বাইনারি',
    'OTHER':             'অন্যান্য',
    'PREFER_NOT_TO_SAY': 'বলতে চাই না',
  };

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _displayNameCtl = TextEditingController(text: p.displayName);
    _bioCtl         = TextEditingController(text: p.bio ?? '');
    _websiteCtl     = TextEditingController(text: p.website ?? '');
    _selectedGender = p.gender;
  }

  @override
  void dispose() {
    _displayNameCtl.dispose();
    _bioCtl.dispose();
    _websiteCtl.dispose();
    super.dispose();
  }

  // ── Avatar picking ────────────────────────────────────────────────────────

  /// Shows a bottom sheet for the user to choose camera or gallery, then
  /// picks the image, compresses it with the avatar preset, and stores it
  /// locally until the user taps "সেভ করুন".
  Future<void> _pickAvatar() async {
    final source = await _showImageSourceSheet();
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 95);
    if (picked == null || !mounted) return;

    setState(() => _isCompressingAvatar = true);
    HapticFeedback.selectionClick();

    try {
      final result = await BondhuImageCompressor.instance
          .compressForAvatar(File(picked.path));

      if (mounted) {
        setState(() {
          _pendingAvatarFile    = result.file;
          _isCompressingAvatar  = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCompressingAvatar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ছবি প্রক্রিয়া করতে সমস্যা: $e')),
        );
      }
    }
  }

  /// Shows camera / gallery choice as a compact bottom sheet.
  Future<ImageSource?> _showImageSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final ext = ctx.appColors;
        return Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ext.card,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: ext.outline.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.photo_library_rounded,
                      color: Theme.of(ctx).colorScheme.primary),
                ),
                title: const Text('গ্যালারি থেকে বেছে নিন',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.camera_alt_rounded,
                      color: Theme.of(ctx).colorScheme.primary),
                ),
                title: const Text('ক্যামেরা দিয়ে তুলুন',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_isSaving) return;

    final name = _displayNameCtl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('নাম খালি রাখা যাবে না')),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      // 1. Upload avatar first (if the user picked one).
      String? newAvatarUrl;
      if (_pendingAvatarFile != null) {
        newAvatarUrl = await ProfileRepository.uploadAvatar(_pendingAvatarFile!);
      }

      // 2. Update all profile fields in a single RPC call.
      await ProfileRepository.updateProfile(
        displayName: name,
        bio:         _bioCtl.text.trim(),
        website:     _websiteCtl.text.trim(),
        gender:      _selectedGender,
        avatarUrl:   newAvatarUrl, // null → RPC keeps the existing value
      );

      if (mounted) {
        HapticFeedback.lightImpact();
        Navigator.pop(context, true); // true = profile was updated
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('সেভ করতে সমস্যা: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ext         = context.appColors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: ext.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──────────────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: ext.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header row ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(
              children: [
                Text('প্রোফাইল সম্পাদনা',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Form ─────────────────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar picker ─────────────────────────────────
                  Center(child: _AvatarPicker(
                    profile:          widget.profile,
                    pendingFile:      _pendingAvatarFile,
                    isCompressing:    _isCompressingAvatar,
                    onPickRequested:  _pickAvatar,
                  )),

                  const SizedBox(height: 24),

                  const _FieldLabel('নাম'),
                  TextField(
                    controller: _displayNameCtl,
                    maxLength:  100,
                    decoration: const InputDecoration(
                      hintText:    'আপনার নাম লিখুন',
                      counterText: '',
                    ),
                  ),

                  const SizedBox(height: 16),

                  const _FieldLabel('বায়ো'),
                  TextField(
                    controller: _bioCtl,
                    maxLength:  500,
                    maxLines:   3,
                    minLines:   2,
                    decoration: const InputDecoration(
                      hintText: 'নিজের সম্পর্কে কিছু লিখুন',
                    ),
                  ),

                  const SizedBox(height: 16),

                  const _FieldLabel('ওয়েবসাইট'),
                  TextField(
                    controller:   _websiteCtl,
                    keyboardType: TextInputType.url,
                    decoration:   const InputDecoration(
                      hintText: 'https://example.com',
                    ),
                  ),

                  const SizedBox(height: 16),

                  const _FieldLabel('লিঙ্গ'),
                  ..._genderOptions.entries.map((e) => RadioListTile<String>(
                    value:          e.key,
                    groupValue:     _selectedGender,
                    onChanged:      (v) => setState(() => _selectedGender = v!),
                    title:          Text(e.value),
                    contentPadding: EdgeInsets.zero,
                    dense:          true,
                    visualDensity:  VisualDensity.compact,
                  )),

                  const SizedBox(height: 24),

                  // ── Save button ─────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: (_isSaving || _isCompressingAvatar) ? null : _save,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                          : const Text('সেভ করুন',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Avatar picker widget
// ─────────────────────────────────────────────────────────────────────────────

/// Shows the current (or newly picked) avatar with a camera-icon overlay.
/// Tapping anywhere on the avatar triggers the image picker flow.
class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.profile,
    required this.pendingFile,
    required this.isCompressing,
    required this.onPickRequested,
  });

  final UserProfile  profile;
  final File?        pendingFile;
  final bool         isCompressing;
  final VoidCallback onPickRequested;

  /// Resolves a display URL from the current profile (storage path or full URL).
  String? _resolveCurrentUrl() {
    final raw = profile.avatarUrl;
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    try {
      return Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Determine what to show: pending local file > current network avatar > placeholder
    Widget avatarImage;
    if (pendingFile != null) {
      avatarImage = CircleAvatar(
        radius: 52,
        backgroundImage: FileImage(pendingFile!),
        backgroundColor: cs.surfaceContainerHighest,
      );
    } else {
      final url = _resolveCurrentUrl();
      avatarImage = url != null
          ? CircleAvatar(
        radius: 52,
        backgroundImage: NetworkImage(url),
        backgroundColor: cs.surfaceContainerHighest,
        onBackgroundImageError: (_, __) {},
      )
          : CircleAvatar(
        radius: 52,
        backgroundColor: cs.surfaceContainerHighest,
        child: Icon(Icons.person_rounded, size: 52,
            color: cs.onSurfaceVariant),
      );
    }

    return GestureDetector(
      onTap: isCompressing ? null : onPickRequested,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Avatar circle with subtle ring
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.35),
                width: 3,
              ),
            ),
            child: avatarImage,
          ),

          // Camera badge (bottom-right)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color:  cs.primary,
                shape:  BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color:      Colors.black.withValues(alpha: 0.18),
                    blurRadius: 6,
                    offset:     const Offset(0, 2),
                  ),
                ],
              ),
              child: isCompressing
                  ? const Padding(
                padding: EdgeInsets.all(7),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.camera_alt_rounded,
                  size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Field label
// ─────────────────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.appColors.textSecondary,
          )),
    );
  }
}