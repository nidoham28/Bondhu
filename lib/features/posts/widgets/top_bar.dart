import 'package:bondhu/config/theme.dart';
import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.isSubmitting,
    required this.hasContent,
    required this.shareScale,
    required this.onClose,
    required this.onShare,
  });

  final bool isSubmitting;
  final bool hasContent;
  final Animation<double> shareScale;
  final VoidCallback onClose;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorExtension>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, size: 26, color: ext.textPrimary),
            tooltip: 'Discard',
            splashRadius: 20,
          ),
          Expanded(
            child: Text(
              'Create Post',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: ext.textPrimary, letterSpacing: -0.3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ScaleTransition(
              scale: shareScale,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: hasContent ? 1.0 : 0.40,
                child: GestureDetector(
                  onTap: (hasContent && !isSubmitting) ? onShare : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                    decoration: BoxDecoration(
                      gradient: hasContent ? const LinearGradient(colors: [AppColors.primary, AppColors.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                      color: hasContent ? null : AppColors.primary,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: isSubmitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Share', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}