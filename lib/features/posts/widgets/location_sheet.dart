import 'package:bondhu/config/theme.dart';
import 'package:bondhu/features/posts/widgets/bottom_sheet_shell.dart';
import 'package:flutter/material.dart';

class LocationSheet extends StatefulWidget {
  const LocationSheet({super.key, required this.current, required this.onConfirm});

  final String? current;
  final void Function(String?) onConfirm;

  @override
  State<LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<LocationSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.current ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: BottomSheetShell(
        isDark: isDark,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ext.textPrimary)),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl, autofocus: true,
              style: TextStyle(color: ext.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search or type a location…', hintStyle: TextStyle(color: ext.textSecondary),
                prefixIcon: const Icon(Icons.place_outlined, color: AppColors.iconRed),
                filled: true, fillColor: ext.surfaceVariant,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (widget.current != null) ...[
                  Expanded(child: OutlinedButton(onPressed: () { widget.onConfirm(null); Navigator.pop(context); }, child: const Text('Remove'))),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final val = _ctrl.text.trim();
                      widget.onConfirm(val.isEmpty ? null : val);
                      Navigator.pop(context);
                    },
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}