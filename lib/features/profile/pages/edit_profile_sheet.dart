import 'package:bondhu/config/theme.dart';
import 'package:bondhu/features/profile/models/user_profile.dart';
import 'package:bondhu/features/profile/repositories/profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  bool _isSaving = false;

  static const _genderOptions = {
    'MALE': 'পুরুষ',
    'FEMALE': 'মহিলা',
    'NON_BINARY': 'নন-বাইনারি',
    'OTHER': 'অন্যান্য',
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
      await ProfileRepository.updateProfile(
        displayName: name,
        bio: _bioCtl.text.trim(),
        website: _websiteCtl.text.trim(),
        gender: _selectedGender,
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

  @override
  Widget build(BuildContext context) {
    final ext = context.appColors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                  _FieldLabel('নাম'),
                  TextField(
                    controller: _displayNameCtl,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      hintText: 'আপনার নাম লিখুন',
                      counterText: '',
                    ),
                  ),

                  const SizedBox(height: 16),

                  _FieldLabel('বায়ো'),
                  TextField(
                    controller: _bioCtl,
                    maxLength: 500,
                    maxLines: 3,
                    minLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'নিজের সম্পর্কে কিছু লিখুন',
                    ),
                  ),

                  const SizedBox(height: 16),

                  _FieldLabel('ওয়েবসাইট'),
                  TextField(
                    controller: _websiteCtl,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      hintText: 'https://example.com',
                    ),
                  ),

                  const SizedBox(height: 16),

                  _FieldLabel('লিঙ্গ'),
                  ..._genderOptions.entries.map((e) => RadioListTile<String>(
                    value: e.key,
                    groupValue: _selectedGender,
                    onChanged: (v) => setState(() => _selectedGender = v!),
                    title: Text(e.value),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                  )),

                  const SizedBox(height: 24),

                  // ── Save button ─────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _save,
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: context.appColors.textSecondary,
      )),
    );
  }
}