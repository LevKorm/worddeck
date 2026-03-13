import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Floating pill-shaped bottom navigation island.
///
/// Active tab: accent-tinted pill with icon + label side-by-side.
/// Inactive tabs: icon only, no background.
class FloatingPillNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int reviewDueCount;

  const FloatingPillNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.reviewDueCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg.withOpacity(0.96),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.surface3.withOpacity(0.5),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NavItem(
                  icon: Icons.translate_rounded,
                  label: 'Translate',
                  isActive: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
                const SizedBox(width: 8),
                _NavItem(
                  icon: Icons.layers_rounded,
                  label: 'Vocabulary',
                  isActive: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
                const SizedBox(width: 8),
                _NavItem(
                  icon: Icons.bolt_rounded,
                  label: 'Review',
                  isActive: currentIndex == 2,
                  onTap: () => onTap(2),
                  badgeCount: reviewDueCount,
                ),
              ],
            ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: 46,
        width: isActive ? 120 : 48,
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentDim : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Icon + label row (active) or icon only (inactive)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? AppColors.accent : AppColors.textDim,
                ),
                if (isActive) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ],
            ),

            // Badge (top-right of the item)
            if (badgeCount > 0)
              Positioned(
                top: 6,
                right: isActive ? 10 : 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  height: 15,
                  constraints: const BoxConstraints(minWidth: 15),
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
