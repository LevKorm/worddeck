import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';

class StreamWordRow extends StatelessWidget {
  final String word;
  final String? translation;
  final String? cefrLevel;
  final String masteryLabel;
  final String? collectionEmoji;
  final bool showCefr;
  final VoidCallback onTap;

  const StreamWordRow({
    super.key,
    required this.word,
    this.translation,
    this.cefrLevel,
    required this.masteryLabel,
    this.collectionEmoji,
    this.showCefr = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Word
            Flexible(
              child: Text(
                word,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Translation
            if (translation != null)
              Flexible(
                child: Text(
                  translation!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(width: 8),
            // CEFR
            if (showCefr && cefrLevel != null)
              Text(
                cefrLevel!,
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 9,
                  color: AppColors.textDim,
                ),
              ),
            if (showCefr && cefrLevel != null) const SizedBox(width: 6),
            // Status dot
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _dotColor(masteryLabel),
              ),
            ),
            if (collectionEmoji != null) ...[
              const SizedBox(width: 6),
              Text(
                collectionEmoji!,
                style: AppTheme.emojiStyle.copyWith(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _dotColor(String label) {
    switch (label) {
      case 'New':      return AppColors.textMuted;
      case 'Learning': return AppColors.accent;
      case 'Review':   return AppColors.indigo;
      case 'Mature':   return AppColors.green;
      default:         return AppColors.textDim;
    }
  }
}
