import 'dart:io';
import 'package:bondhu/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MediaStrip extends StatelessWidget {
  const MediaStrip({super.key, required this.files, required this.onAdd, required this.onRemove});

  final List<XFile> files;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorExtension>()!;

    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: files.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == files.length) {
            return GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 100,
                decoration: BoxDecoration(
                  color: ext.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ext.outline.withValues(alpha: 0.5), width: 0.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(height: 6),
                    const Text('Add more', style: TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            );
          }

          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(File(files[i].path), width: 100, height: 118, fit: BoxFit.cover),
              ),
              Positioned(
                top: 6, right: 6,
                child: GestureDetector(
                  onTap: () => onRemove(i),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 13),
                  ),
                ),
              ),
              if (files.length > 1)
                Positioned(
                  top: 6, left: 6,
                  child: Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                    alignment: Alignment.center,
                    child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}