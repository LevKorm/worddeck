import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'cefr_badge.dart';
import 'progress_ring.dart';

/// Vocabulary list card — redesigned.
///
/// Layout:
///   Row(top): word (22px bold) + translation (16px muted) | progress ring / checkbox
///   Row(bottom): collection badge (optional) | due date
class WordCard extends StatelessWidget {
  final String word;
  final String? translation;
  final double progress;       // 0.0–1.0 — drives the ring
  final String masteryLabel;   // for ring color
  final DateTime nextReviewDate;
  final String? collectionName;
  final Color? collectionColor;
  final String? cefrLevel;
  final bool isSelectMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const WordCard({
    super.key,
    required this.word,
    this.translation,
    required this.progress,
    required this.masteryLabel,
    required this.nextReviewDate,
    this.collectionName,
    this.collectionColor,
    this.cefrLevel,
    this.isSelectMode = false,
    this.isSelected = false,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _masteryColor(masteryLabel);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.indigo.withOpacity(0.05)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppColors.indigo.withOpacity(0.3)
                : AppColors.surface3.withOpacity(0.5),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top section: word/translation + CEFR + ring ─────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              word,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (cefrLevel != null) ...[
                            const SizedBox(width: 6),
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: CefrBadge(
                                  level: cefrLevel, fontSize: 10),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        translation ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Progress ring in normal mode; checkbox in select mode
                isSelectMode
                    ? _SelectBox(isSelected: isSelected)
                    : ProgressRing(
                        progress: progress,
                        color: statusColor,
                        size: 42,
                      ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Bottom meta row ───────────────────────────────────────────
            Row(
              children: [
                if (collectionName != null) ...[
                  _CollectionBadge(
                    name: collectionName!,
                    color: collectionColor,
                  ),
                ],
                const Spacer(),
                const Icon(
                  Icons.schedule_rounded,
                  size: 11,
                  color: AppColors.textDim,
                ),
                const SizedBox(width: 4),
                Text(
                  _fmtRelDate(nextReviewDate),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textDim,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _SelectBox extends StatelessWidget {
  final bool isSelected;
  const _SelectBox({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.indigo.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.indigo : AppColors.textDim,
          width: 1.5,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check_rounded, size: 20, color: AppColors.indigo)
          : null,
    );
  }
}

class _CollectionBadge extends StatelessWidget {
  final String name;
  final Color? color;
  const _CollectionBadge({required this.name, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textDim;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: c.withOpacity(0.07),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: c,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

Color _masteryColor(String label) {
  switch (label) {
    case 'New':      return AppColors.textMuted;
    case 'Learning': return AppColors.accent;
    case 'Review':   return AppColors.indigo;
    case 'Mature':   return AppColors.green;
    default:         return AppColors.textDim;
  }
}

String _fmtRelDate(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(d.year, d.month, d.day);
  final diff = date.difference(today).inDays;
  if (diff < 0) return 'Overdue';
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  const m = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${m[d.month - 1]} ${d.day}';
}
