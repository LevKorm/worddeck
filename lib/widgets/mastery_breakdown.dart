import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Horizontal bar chart showing the four mastery levels.
class MasteryBreakdown extends StatelessWidget {
  final int newCount;
  final int learningCount;
  final int reviewCount;
  final int matureCount;

  const MasteryBreakdown({
    super.key,
    required this.newCount,
    required this.learningCount,
    required this.reviewCount,
    required this.matureCount,
  });

  @override
  Widget build(BuildContext context) {
    final total = newCount + learningCount + reviewCount + matureCount;

    if (total == 0) {
      return _emptyState(context);
    }

    return Column(
      children: [
        _Bar(
          label: 'New',
          count: newCount,
          total: total,
          color: const Color(0xFF6B7280),
        ),
        const SizedBox(height: 10),
        _Bar(
          label: 'Learning',
          count: learningCount,
          total: total,
          color: const Color(0xFFF97316),
        ),
        const SizedBox(height: 10),
        _Bar(
          label: 'Review',
          count: reviewCount,
          total: total,
          color: const Color(0xFF8B5CF6),
        ),
        const SizedBox(height: 10),
        _Bar(
          label: 'Mature',
          count: matureCount,
          total: total,
          color: AppColors.green,
        ),
      ],
    );
  }

  Widget _emptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'No cards yet',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _Bar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = total > 0 ? count / total : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: color.withAlpha(26),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 32,
          child: Text(
            '$count',
            style: theme.textTheme.labelLarge,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
