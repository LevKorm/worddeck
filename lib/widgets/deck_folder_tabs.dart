import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_colors.dart';
import '../modules/collections/collection_provider.dart';
import '../providers/deck_filter_providers.dart';

/// Telegram-style horizontal collection folder tabs for the Vocabulary screen.
///
/// "All" tab + one tab per collection. Tapping sets [deckCollectionFilterProvider].
/// Hidden if user has no collections.
/// Edit/delete collections via Settings → Manage Collections.
class DeckFolderTabs extends ConsumerWidget {
  const DeckFolderTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(collectionProvider).collections;
    final selectedId = ref.watch(deckCollectionFilterProvider);

    if (collections.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _Tab(
            label: 'All',
            isSelected: selectedId == null,
            onTap: () =>
                ref.read(deckCollectionFilterProvider.notifier).state = null,
          ),
          ...collections.map(
            (c) => _Tab(
              label: '${c.emoji} ${c.name}',
              isSelected: selectedId == c.id,
              color: c.flutterColor,
              onTap: () =>
                  ref.read(deckCollectionFilterProvider.notifier).state = c.id,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.accent;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 6, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? c.withAlpha(35) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppColors.radiusFull),
          border: Border.all(
            color: isSelected ? c.withAlpha(100) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? c : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
