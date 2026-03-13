import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../cefr_badge.dart';

class BigWordCard extends StatelessWidget {
  final String word;
  final String? translation;
  final String? exampleSentence;
  final String masteryLabel;
  final String? collectionName;
  final String? collectionEmoji;
  final String? cefrLevel;
  final bool showCefr;
  final VoidCallback onTap;

  const BigWordCard({
    super.key,
    required this.word,
    this.translation,
    this.exampleSentence,
    required this.masteryLabel,
    this.collectionName,
    this.collectionEmoji,
    this.cefrLevel,
    this.showCefr = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surface3, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Word
            Text(
              word,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
                height: 1.2,
              ),
            ),
            if (translation != null) ...[
              const SizedBox(height: 4),
              Text(
                translation!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            // Example sentence
            if (exampleSentence != null && exampleSentence!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.only(top: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.surface3, width: 0.5),
                  ),
                ),
                child: Text(
                  '"$exampleSentence"',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textDim,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Footer
            Row(
              children: [
                if (showCefr && cefrLevel != null) ...[
                  CefrBadge(level: cefrLevel, fontSize: 9),
                  const SizedBox(width: 6),
                ],
                _StatusBadge(label: masteryLabel),
                const Spacer(),
                if (collectionName != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        collectionEmoji ?? '📚',
                        style: AppTheme.emojiStyle.copyWith(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        collectionName!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textDim,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  const _StatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colorsFor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }

  (Color, Color) _colorsFor(String label) {
    switch (label) {
      case 'New':
        return (AppColors.surface2, AppColors.textMuted);
      case 'Learning':
        return (AppColors.accentDim, AppColors.accent);
      case 'Review':
        return (AppColors.indigoDim, AppColors.indigo);
      case 'Mature':
        return (AppColors.greenDim, AppColors.green);
      default:
        return (AppColors.surface2, AppColors.textDim);
    }
  }
}
