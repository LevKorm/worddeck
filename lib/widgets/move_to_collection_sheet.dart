import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../modules/collections/collection_provider.dart';

/// Bottom sheet listing all collections + "Remove from collection" option.
/// Returns the chosen collection ID, or an empty string '' to remove.
/// Returns null if dismissed.
Future<String?> showMoveToCollectionSheet(
  BuildContext context,
  WidgetRef ref, {
  int cardCount = 0,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _MoveSheet(ref: ref, cardCount: cardCount),
  );
}

class _MoveSheet extends StatelessWidget {
  final WidgetRef ref;
  final int cardCount;

  const _MoveSheet({required this.ref, required this.cardCount});

  @override
  Widget build(BuildContext context) {
    final collections = ref.watch(collectionProvider).collections;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surface3,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  cardCount == 1
                      ? 'Move 1 word to…'
                      : 'Move $cardCount words to…',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (collections.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No collections yet',
                style: TextStyle(color: AppColors.textMuted),
              ),
            )
          else ...[
            // Remove option
            _CollectionTile(
              emoji: '×',
              name: 'Remove from collection',
              color: AppColors.red,
              onTap: () => Navigator.of(context).pop(''),
            ),
            const Divider(color: AppColors.surface3, height: 1),

            // Collections list
            ...collections.map((c) => _CollectionTile(
                  emoji: c.emoji,
                  name: c.name,
                  color: c.flutterColor ?? AppColors.textMuted,
                  onTap: () => Navigator.of(context).pop(c.id),
                )),
          ],
        ],
      ),
    );
  }
}

class _CollectionTile extends StatelessWidget {
  final String emoji;
  final String name;
  final Color color;
  final VoidCallback onTap;

  const _CollectionTile({
    required this.emoji,
    required this.name,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(AppColors.radiusSm),
                ),
                child: Text(emoji, style: AppTheme.emojiStyle.copyWith(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Text(
                name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: name == 'Remove from collection'
                      ? AppColors.red
                      : AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
