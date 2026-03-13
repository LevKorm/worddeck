import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/flash_card.dart';
import '../../modules/spaces/space_provider.dart';
import 'feed_theme.dart';

/// Shows the user's most recently saved cards in the feed screen.
/// Displays 3 by default; tapping "Show all" expands the full list.
class FeedRecentTranslationsList extends StatefulWidget {
  final List<FlashCard> recentCards;

  const FeedRecentTranslationsList({
    super.key,
    required this.recentCards,
  });

  @override
  State<FeedRecentTranslationsList> createState() =>
      _FeedRecentTranslationsListState();
}

class _FeedRecentTranslationsListState
    extends State<FeedRecentTranslationsList> {
  static const _previewCount = 3;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.recentCards.isEmpty) return const SizedBox.shrink();

    final shown = _expanded
        ? widget.recentCards
        : widget.recentCards.take(_previewCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Text(
                'Recent Cards',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: FeedTheme.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              if (_expanded)
                GestureDetector(
                  onTap: () => setState(() => _expanded = false),
                  child: const Row(
                    children: [
                      Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 12,
                          color: FeedTheme.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.close_rounded,
                          size: 14, color: FeedTheme.accent),
                    ],
                  ),
                ),
            ],
          ),
        ),
        ...shown.map((card) => _RecentCardTile(card: card)),
        if (!_expanded && widget.recentCards.length > _previewCount)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTap: () => setState(() => _expanded = true),
              child: Text(
                'Show all ${widget.recentCards.length} cards',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: FeedTheme.accent,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RecentCardTile extends ConsumerWidget {
  final FlashCard card;

  const _RecentCardTile({required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final age = _formatAge(card.createdAt);
    final activeSpace = ref.watch(activeSpaceProvider);
    final langLabel = activeSpace?.learningLanguage ?? 'EN';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: FeedTheme.borderDark),
        ),
      ),
      child: Row(
        children: [
          // Lang badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: FeedTheme.accentSoft,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              langLabel,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: FeedTheme.accent,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Word + translation
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.word,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: FeedTheme.textPrimary,
                  ),
                ),
                if (card.translation != null)
                  Text(
                    card.translation!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: FeedTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          // Time
          Text(
            age,
            style: const TextStyle(
              fontSize: 11,
              color: FeedTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatAge(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m';
    if (diff.inHours   < 24)  return '${diff.inHours}h';
    if (diff.inDays    < 30)  return '${diff.inDays}d';
    return '${(diff.inDays / 30).floor()}mo';
  }
}
