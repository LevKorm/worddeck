import 'package:flutter/material.dart';

/// Card for the Deck list showing a saved word's mastery status.
///
/// [masteryLabel] must be one of: 'New', 'Learning', 'Review', 'Mature'
/// [progress] is a 0.0–1.0 mastery progress value.
class WordCard extends StatelessWidget {
  final String word;
  final String? translation;
  final String? partOfSpeech;
  final String masteryLabel;
  final DateTime nextReviewDate;
  final double progress;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const WordCard({
    super.key,
    required this.word,
    this.translation,
    this.partOfSpeech,
    required this.masteryLabel,
    required this.nextReviewDate,
    required this.progress,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _masteryColor(masteryLabel);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left accent bar
                  Container(width: 4, color: color),

                  // Main content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
                      child: Row(
                        children: [
                          // Word + translation
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  word,
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                if (translation != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    translation!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Right column: badges + actions
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Top row: part of speech + mastery badge
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (partOfSpeech != null) ...[
                                    Text(
                                      partOfSpeech!,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: theme
                                            .colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  _StatusBadge(
                                      label: masteryLabel, color: color),
                                ],
                              ),

                              const SizedBox(height: 6),

                              // Bottom row: next review date + actions
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    _fmtRelDate(nextReviewDate),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 16),
                                    color: theme.colorScheme.error
                                        .withAlpha(179),
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(
                                        minWidth: 28, minHeight: 28),
                                    tooltip: 'Delete',
                                    onPressed: onDelete,
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 16,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Progress bar at bottom
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: color.withAlpha(26),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status badge ───────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

Color _masteryColor(String label) {
  switch (label) {
    case 'New':
      return const Color(0xFF6B7280);
    case 'Learning':
      return const Color(0xFFF97316);
    case 'Review':
      return const Color(0xFF8B5CF6);
    case 'Mature':
      return const Color(0xFF22C55E);
    default:
      return const Color(0xFF6B7280);
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
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${m[d.month - 1]} ${d.day}';
}
