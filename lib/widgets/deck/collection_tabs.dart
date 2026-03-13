import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/collection.dart';
import '../../models/flash_card.dart';
import '../../modules/cards/card_provider.dart';

class CollectionTabs extends ConsumerWidget {
  final List<Collection> collections;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const CollectionTabs({
    super.key,
    required this.collections,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCards = ref.watch(cardListProvider).allCards;
    final sorted = List<Collection>.from(collections)
      ..sort((a, b) => a.position.compareTo(b.position));

    return SizedBox(
      height: 42,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // "All" tab
            _Tab(
              emoji: null,
              icon: Icons.auto_awesome_rounded,
              label: 'All',
              count: allCards.length,
              isActive: selected == null,
              onTap: () => onSelected(null),
            ),
            const SizedBox(width: 8),
            for (final c in sorted) ...[
              _Tab(
                emoji: c.emoji,
                label: c.name,
                count: _countForCollection(allCards, c.id),
                isActive: selected == c.id,
                onTap: () => onSelected(c.id),
              ),
              const SizedBox(width: 8),
            ],
            // "+ New" tab
            GestureDetector(
              onTap: () => context.push('/collections/new'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.surface3,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.add_rounded, size: 14, color: AppColors.textDim),
                    SizedBox(width: 4),
                    Text(
                      'New',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDim,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _countForCollection(List<FlashCard> cards, String collectionId) {
    return cards.where((c) => c.collectionId == collectionId).length;
  }
}

class _Tab extends StatelessWidget {
  final String? emoji;
  final IconData? icon;
  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _Tab({
    this.emoji,
    this.icon,
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentDim : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? AppColors.accent : AppColors.surface3,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, size: 15, color: isActive ? AppColors.accent : AppColors.textMuted)
            else
              Text(emoji ?? '📚', style: AppTheme.emojiStyle.copyWith(fontSize: 15)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isActive ? AppColors.accent : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.accent.withAlpha(51)
                    : AppColors.surface3,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppColors.accent : AppColors.textDim,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
