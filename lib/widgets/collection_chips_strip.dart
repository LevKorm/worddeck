import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_colors.dart';
import '../modules/collections/collection_provider.dart';

/// Horizontal strip of collection chips shown on the Translate screen (idle state).
///
/// Allows the user to pre-select a collection before saving a word.
/// [selectedId] == null means "no collection" (uncategorised).
class CollectionChipsStrip extends ConsumerWidget {
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const CollectionChipsStrip({
    super.key,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(collectionProvider).collections;

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _Chip(
            label: 'No collection',
            isSelected: selectedId == null,
            onTap: () => onSelected(null),
          ),
          ...collections.map(
            (c) => _Chip(
              label: c.name,
              isSelected: selectedId == c.id,
              color: c.flutterColor,
              onTap: () => onSelected(c.id),
            ),
          ),
          _AddChip(
            onTap: () => context.push('/collections/new'),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _Chip({
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
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? c.withAlpha(35) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppColors.radiusFull),
          border: Border.all(
            color: isSelected
                ? c.withAlpha(120)
                : AppColors.surface3,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? c : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  final VoidCallback onTap;
  const _AddChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(AppColors.radiusFull),
          border: Border.all(color: AppColors.surface3.withAlpha(128)),
        ),
        child: const Icon(Icons.add_rounded, size: 16, color: AppColors.textMuted),
      ),
    );
  }
}
