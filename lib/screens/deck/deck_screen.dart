import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/word_card.dart';
import '../../widgets/word_detail_sheet.dart';
import '../shell/shell_screen.dart';
import 'deck_controller.dart';

class DeckScreen extends ConsumerStatefulWidget {
  const DeckScreen({super.key});

  @override
  ConsumerState<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends ConsumerState<DeckScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deckControllerProvider.notifier).loadCards();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(deckControllerProvider.notifier).loadCards();
  }

  @override
  Widget build(BuildContext context) {
    // Scroll to top when user taps the active Deck tab
    ref.listen(scrollToTopProvider, (_, __) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    final deckState     = ref.watch(deckControllerProvider);
    final filteredCards = ref.watch(filteredDeckCardsProvider);

    const filters = ['All', 'New', 'Learning', 'Review', 'Mature'];

    return Scaffold(
      appBar: AppBar(
        title: Text('My Deck (${filteredCards.length})'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search words…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: deckState.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(deckControllerProvider.notifier)
                              .setSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
              ),
              onChanged: (q) =>
                  ref.read(deckControllerProvider.notifier).setSearch(q),
            ),
          ),
          const SizedBox(height: 8),

          // Filter chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: filters
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(f),
                          selected: deckState.masteryFilter == f,
                          onSelected: (_) => ref
                              .read(deckControllerProvider.notifier)
                              .setFilter(f),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 4),

          // Card list
          Expanded(
            child: filteredCards.isEmpty
                ? _EmptyState(hasSearch: deckState.searchQuery.isNotEmpty)
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: filteredCards.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final card = filteredCards[i];
                        return WordCard(
                          word: card.word,
                          translation: card.translation,
                          masteryLabel: masteryLabelFor(card),
                          nextReviewDate: card.nextReview,
                          progress: masteryProgressFor(card),
                          onTap: () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => WordDetailSheet(
                              card: card,
                              onDelete: () {
                                Navigator.of(context).pop();
                                ref
                                    .read(deckControllerProvider.notifier)
                                    .deleteCard(card.id);
                              },
                            ),
                          ),
                          onDelete: () => ref
                              .read(deckControllerProvider.notifier)
                              .deleteCard(card.id),
                        )
                            .animate(delay: Duration(milliseconds: i * 40))
                            .fade(duration: 300.ms)
                            .slideY(
                              begin: 0.15,
                              end: 0,
                              duration: 300.ms,
                              curve: Curves.easeOut,
                            );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasSearch;

  const _EmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasSearch ? Icons.search_off_rounded : Icons.layers_outlined,
            size: 64,
            color: theme.colorScheme.outlineVariant,
          )
              .animate()
              .scale(
                begin: const Offset(0.7, 0.7),
                duration: 400.ms,
                curve: Curves.easeOut,
              )
              .fade(duration: 300.ms),
          const SizedBox(height: 16),
          Text(
            hasSearch
                ? 'No words match your search'
                : 'No words yet.\nStart translating!',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          )
              .animate(delay: 150.ms)
              .fade(duration: 300.ms)
              .slideY(begin: 0.2, end: 0, duration: 300.ms),
        ],
      ),
    );
  }
}
