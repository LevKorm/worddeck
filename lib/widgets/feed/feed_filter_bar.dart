import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../modules/feed/feed_provider.dart';
import 'feed_theme.dart';

/// Sticky filter bar for the Discovery feed.
///
/// - Clock button: toggles [FeedFilter.latest] (toggles back to random)
/// - Liked pill: shows like count, toggles [FeedFilter.liked]
/// - Scroll-to-top arrow: visible when [showScrollToTop] is true
class FeedFilterBar extends StatelessWidget {
  final FeedFilter activeFilter;
  final int likedCount;
  final bool showScrollToTop;
  final ValueChanged<FeedFilter> onFilterChanged;
  final VoidCallback? onScrollToTop;

  const FeedFilterBar({
    super.key,
    required this.activeFilter,
    required this.likedCount,
    required this.onFilterChanged,
    this.showScrollToTop = false,
    this.onScrollToTop,
  });

  void _toggle(FeedFilter filter) {
    // Tapping an active filter returns to random (reshuffles)
    onFilterChanged(activeFilter == filter ? FeedFilter.random : filter);
  }

  @override
  Widget build(BuildContext context) {
    final latestActive = activeFilter == FeedFilter.latest;
    final likedActive  = activeFilter == FeedFilter.liked;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          // ── Latest toggle (clock icon) ─────────────────────────────────
          _FilterBtn(
            icon: Icons.access_time_rounded,
            label: 'Latest',
            active: latestActive,
            onTap: () => _toggle(FeedFilter.latest),
          ),

          const SizedBox(width: 10),

          // ── Liked pill ─────────────────────────────────────────────────
          _LikedBtn(
            count:  likedCount,
            active: likedActive,
            onTap:  () => _toggle(FeedFilter.liked),
          ),

          const Spacer(),

          // ── Scroll to top ──────────────────────────────────────────────
          AnimatedOpacity(
            opacity: showScrollToTop ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: showScrollToTop ? onScrollToTop : null,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface3),
                ),
                child: const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurfaceVariant;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? primary.withAlpha(38)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? primary.withAlpha(100) : theme.colorScheme.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? primary : muted),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? primary : muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LikedBtn extends StatelessWidget {
  final int count;
  final bool active;
  final VoidCallback onTap;

  const _LikedBtn({
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const heart = FeedTheme.heart;
    final muted = theme.colorScheme.onSurfaceVariant;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? heart.withAlpha(38)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? heart.withAlpha(100) : theme.colorScheme.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 14,
              color: active ? heart : muted,
            ),
            const SizedBox(width: 5),
            Text(
              count > 0 ? 'Liked  $count' : 'Liked',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? heart : muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
