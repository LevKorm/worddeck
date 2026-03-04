import 'package:flutter/material.dart';

/// App-level bottom navigation bar with 5 tabs and optional review badge.
///
/// Used by [ShellScreen]. The [reviewBadgeCount] shows a badge on the
/// Review tab when there are due cards.
class AppNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int reviewBadgeCount;

  const AppNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.reviewBadgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.translate_outlined),
          selectedIcon: Icon(Icons.translate_rounded),
          label: 'Translate',
        ),
        const NavigationDestination(
          icon: Icon(Icons.layers_outlined),
          selectedIcon: Icon(Icons.layers_rounded),
          label: 'Deck',
        ),
        NavigationDestination(
          icon: _withBadge(
            child: const Icon(Icons.flash_on_outlined),
            count: reviewBadgeCount,
          ),
          selectedIcon: _withBadge(
            child: const Icon(Icons.flash_on_rounded),
            count: reviewBadgeCount,
          ),
          label: 'Review',
        ),
        const NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart_rounded),
          label: 'Stats',
        ),
        const NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          label: 'Settings',
        ),
      ],
    );
  }

  Widget _withBadge({required Widget child, required int count}) {
    if (count <= 0) return child;
    return Badge(
      label: count > 99 ? const Text('99+') : Text('$count'),
      child: child,
    );
  }
}
