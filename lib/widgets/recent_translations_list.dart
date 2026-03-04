import 'package:flutter/material.dart';

/// A single item in the recent translations list.
class RecentItem {
  final String word;
  final String translation;
  final bool isSaved;

  const RecentItem({
    required this.word,
    required this.translation,
    this.isSaved = false,
  });
}

/// Subtle list of recently translated words.
///
/// Shows a "Recent" header with a "Clear" link, then a list of word/translation
/// pairs with a green checkmark on saved items.
class RecentTranslationsList extends StatelessWidget {
  final List<RecentItem> items;
  final ValueChanged<String> onTap;
  final VoidCallback onClear;

  const RecentTranslationsList({
    super.key,
    required this.items,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                'Recent',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onClear,
                child: Text(
                  'Clear',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Items
        ...items.map(
          (item) => _RecentItemTile(
            item: item,
            onTap: () => onTap(item.word),
          ),
        ),
      ],
    );
  }
}

class _RecentItemTile extends StatelessWidget {
  final RecentItem item;
  final VoidCallback onTap;

  const _RecentItemTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.word,
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      item.translation,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.isSaved)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: Color(0xFF22C55E),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
