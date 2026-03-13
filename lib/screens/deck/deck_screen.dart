import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shimmer_widget.dart';
import '../../models/collection.dart';
import '../../models/flash_card.dart';
import '../../modules/cards/card_provider.dart';
import '../../modules/collections/collection_provider.dart';
import '../../providers/deck_filter_providers.dart';
import '../../widgets/move_to_collection_sheet.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/word_card.dart';
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
  bool _searchVisible = false;
  bool _showedSkeleton = false;

  // Swipe-to-delete: pending deletes with undo
  final Map<String, _PendingDelete> _pendingDeletes = {};

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

  void _markPendingDelete(FlashCard card) {
    setState(() {
      _pendingDeletes[card.id] = _PendingDelete(card: card);
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _pendingDeletes.containsKey(card.id)) {
        _finalizeDeletion(card.id);
      }
    });
  }

  void _undoDelete(String cardId) {
    setState(() {
      _pendingDeletes.remove(cardId);
    });
  }

  void _finalizeDeletion(String cardId) {
    if (!_pendingDeletes.containsKey(cardId)) return;
    final card = _pendingDeletes[cardId]!.card;
    ref.read(deckControllerProvider.notifier).deleteCard(card.id);
    if (mounted) {
      setState(() {
        _pendingDeletes.remove(cardId);
      });
    }
  }

  Future<void> _refresh() async {
    await ref.read(deckControllerProvider.notifier).loadCards();
  }

  void _enterSelectMode(String firstCardId) {
    ref.read(deckSelectModeProvider.notifier).state = true;
    ref.read(deckSelectedCardsProvider.notifier).state = {firstCardId};
  }

  void _exitSelectMode() {
    ref.read(deckSelectModeProvider.notifier).state = false;
    ref.read(deckSelectedCardsProvider.notifier).state = {};
  }

  void _toggleSelect(String cardId) {
    final current = ref.read(deckSelectedCardsProvider);
    final updated = Set<String>.from(current);
    if (updated.contains(cardId)) {
      updated.remove(cardId);
    } else {
      updated.add(cardId);
    }
    ref.read(deckSelectedCardsProvider.notifier).state = updated;
    if (updated.isEmpty) _exitSelectMode();
  }

  Future<void> _moveSelected() async {
    final selected = ref.read(deckSelectedCardsProvider);
    if (selected.isEmpty) return;
    final result = await showMoveToCollectionSheet(
      context,
      ref,
      cardCount: selected.length,
    );
    if (result == null) return;
    final cardIds = selected.toList();
    if (result.isEmpty) {
      for (final id in cardIds) {
        ref.read(cardListProvider.notifier).updateCardCollection(id, null);
      }
    } else {
      ref.read(cardListProvider.notifier).moveCardsToCollection(cardIds, result);
    }
    _exitSelectMode();
  }

  Future<void> _deleteSelected() async {
    final selected = ref.read(deckSelectedCardsProvider);
    if (selected.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete words'),
        content: Text(
          'Delete ${selected.length} '
          '${selected.length == 1 ? 'word' : 'words'}? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ctrl = ref.read(deckControllerProvider.notifier);
    for (final id in selected.toList()) {
      await ctrl.deleteCard(id);
    }
    _exitSelectMode();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(scrollToTopProvider, (_, __) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    final safeBottom = MediaQuery.of(context).padding.bottom;
    final cardState = ref.watch(cardListProvider);

    // Show shimmer skeleton on very first load (before cards arrive).
    final showSkeleton = !_showedSkeleton && cardState.isLoading;
    if (!cardState.isLoading) _showedSkeleton = true;

    if (showSkeleton) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Header skeleton
                Row(
                  children: [
                    const ShimmerWidget(width: 100, height: 28, borderRadius: 8),
                    const Spacer(),
                    ShimmerWidget(width: 28, height: 28, borderRadius: 14),
                    const SizedBox(width: 10),
                    ShimmerWidget(width: 28, height: 28, borderRadius: 14),
                    const SizedBox(width: 10),
                    ShimmerWidget(width: 28, height: 28, borderRadius: 14),
                  ],
                ),
                const SizedBox(height: 16),
                // Status pills skeleton
                Row(
                  children: List.generate(4, (i) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ShimmerWidget(
                      width: 60 + (i == 0 ? 0 : 16),
                      height: 30,
                      borderRadius: 15,
                    ),
                  )),
                ),
                const SizedBox(height: 20),
                // Card skeletons
                ...List.generate(5, (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ShimmerWidget(
                    height: 72,
                    borderRadius: 14,
                  ),
                )),
              ],
            ),
          ),
        ),
      );
    }

    final deckState = ref.watch(deckControllerProvider);
    final filteredCards = ref.watch(filteredDeckCardsProvider);
    final statusFilter = ref.watch(deckStatusFilterProvider);
    final sortOption = ref.watch(deckSortProvider);
    final isSelectMode = ref.watch(deckSelectModeProvider);
    final selectedCards = ref.watch(deckSelectedCardsProvider);
    final allCards = cardState.allCards;
    final collections = ref.watch(collectionProvider).collections;
    final collectionFilter = ref.watch(deckCollectionFilterProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: isSelectMode
                    ? _SelectHeader(
                        selectedCount: selectedCards.length,
                        onCancel: _exitSelectMode,
                        onMove: _moveSelected,
                        onDelete: _deleteSelected,
                      )
                    : _Header(
                        wordCount: allCards.length,
                        searchVisible: _searchVisible,
                        sortOption: sortOption,
                        onSearchToggle: () =>
                            setState(() => _searchVisible = !_searchVisible),
                        onSortChanged: (opt) =>
                            ref.read(deckSortProvider.notifier).state = opt,
                        searchController: _searchController,
                        searchQuery: deckState.searchQuery,
                        onSearchChanged: (q) =>
                            ref.read(deckControllerProvider.notifier).setSearch(q),
                      ),
              ),
              _StatusFilterPills(
                selected: statusFilter,
                onChanged: (f) =>
                    ref.read(deckStatusFilterProvider.notifier).state = f,
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _TodaysFocusCarousel(allCards: allCards),
                      ),
                      if (filteredCards.isEmpty)
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 300,
                            child: _EmptyState(
                              hasSearch: deckState.searchQuery.isNotEmpty,
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                          sliver: SliverList.separated(
                            itemCount: filteredCards.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 6),
                            itemBuilder: (context, i) {
                              final card = filteredCards[i];

                              // Show undo placeholder for pending deletes
                              if (_pendingDeletes.containsKey(card.id)) {
                                return _UndoRow(
                                  word: card.word,
                                  onUndo: () => _undoDelete(card.id),
                                );
                              }

                              final collection = ref.watch(
                                collectionByIdProvider(card.collectionId),
                              );
                              final wordCard = WordCard(
                                key: ValueKey('wc_${card.id}'),
                                word: card.word,
                                translation: card.translation,
                                progress: cardProgress(card),
                                masteryLabel: masteryLabelFor(card),
                                nextReviewDate: card.nextReview,
                                collectionName: collection?.name,
                                collectionColor: collection?.flutterColor,
                                cefrLevel: card.cefrLevel,
                                isSelectMode: isSelectMode,
                                isSelected: selectedCards.contains(card.id),
                                onTap: isSelectMode
                                    ? () => _toggleSelect(card.id)
                                    : () => context.push('/word', extra: card),
                                onLongPress: isSelectMode
                                    ? null
                                    : () => _enterSelectMode(card.id),
                              );
                              final Widget item = isSelectMode
                                  ? wordCard
                                  : _SwipeToDelete(
                                      onDeleted: () =>
                                          _markPendingDelete(card),
                                      child: wordCard,
                                    );
                              return item;
                            },
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: SizedBox(height: 100 + safeBottom + 60),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Collection island ─────────────────────────────────────────────
          Positioned(
            bottom: 82 + safeBottom,
            left: 16,
            right: 16,
            child: Center(
              child: _CollectionIsland(
                collections: collections,
                selected: collectionFilter,
                onSelected: (id) =>
                    ref.read(deckCollectionFilterProvider.notifier).state = id,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int wordCount;
  final bool searchVisible;
  final DeckSortOption sortOption;
  final VoidCallback onSearchToggle;
  final ValueChanged<DeckSortOption> onSortChanged;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  const _Header({
    required this.wordCount,
    required this.searchVisible,
    required this.sortOption,
    required this.onSearchToggle,
    required this.onSortChanged,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.push('/stats'),
                child: Text(
                  '$wordCount words',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    height: 1.1,
                  ),
                ),
              ),
              const Spacer(),
              _IconBtn(
                icon: searchVisible
                    ? Icons.search_off_rounded
                    : Icons.search_rounded,
                onTap: onSearchToggle,
              ),
              _SortBtn(current: sortOption, onSelected: onSortChanged),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: searchVisible
                ? Padding(
                    padding: const EdgeInsets.only(top: 10, right: 8),
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search words…',
                        prefixIcon:
                            const Icon(Icons.search_rounded, size: 18),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  searchController.clear();
                                  onSearchChanged('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.surface2,
                      ),
                      onChanged: onSearchChanged,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Select header ─────────────────────────────────────────────────────────────

class _SelectHeader extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onCancel;
  final VoidCallback onMove;
  final VoidCallback onDelete;

  const _SelectHeader({
    required this.selectedCount,
    required this.onCancel,
    required this.onMove,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          TextButton(
            onPressed: onCancel,
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              '$selectedCount selected',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.folder_open_rounded, size: 22),
            color: AppColors.textMuted,
            onPressed: onMove,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 22),
            color: AppColors.red,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ── Icon button ───────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: Icon(icon, size: 22, color: AppColors.textMuted),
      ),
    );
  }
}

// ── Sort button ───────────────────────────────────────────────────────────────

class _SortBtn extends StatelessWidget {
  final DeckSortOption current;
  final ValueChanged<DeckSortOption> onSelected;

  const _SortBtn({required this.current, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<DeckSortOption>(
      icon: const Icon(Icons.sort_rounded,
          size: 22, color: AppColors.textMuted),
      color: AppColors.surface2,
      onSelected: onSelected,
      itemBuilder: (_) => DeckSortOption.values
          .map((opt) => PopupMenuItem<DeckSortOption>(
                value: opt,
                child: Row(
                  children: [
                    if (opt == current)
                      const Icon(Icons.check_rounded,
                          size: 16, color: AppColors.accent)
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    Text(opt.label,
                        style: const TextStyle(color: AppColors.text)),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

// ── Status filter pills ───────────────────────────────────────────────────────

class _StatusFilterPills extends StatelessWidget {
  final DeckStatusFilter selected;
  final ValueChanged<DeckStatusFilter> onChanged;

  const _StatusFilterPills({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        children: DeckStatusFilter.values.map((f) {
          final isSelected = selected == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accentDim : AppColors.surface2,
                  borderRadius:
                      BorderRadius.circular(AppColors.radiusFull),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accent.withAlpha(80)
                        : AppColors.surface3.withAlpha(128),
                  ),
                ),
                child: Text(
                  f.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color:
                        isSelected ? AppColors.accent : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Today's Focus carousel ────────────────────────────────────────────────────

class _TodaysFocusCarousel extends StatefulWidget {
  final List<FlashCard> allCards;

  const _TodaysFocusCarousel({required this.allCards});

  @override
  State<_TodaysFocusCarousel> createState() => _TodaysFocusCarouselState();
}

class _TodaysFocusCarouselState extends State<_TodaysFocusCarousel> {
  late final PageController _pageController;
  int _activePage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.58);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<FlashCard> get _dueCards {
    final cutoff = DateTime.now().add(const Duration(hours: 24));
    return widget.allCards
        .where((c) => c.nextReview.isBefore(cutoff))
        .toList()
      ..sort((a, b) => a.nextReview.compareTo(b.nextReview));
  }

  @override
  Widget build(BuildContext context) {
    final due = _dueCards;
    if (due.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Row(
              children: [
                const Text(
                  "Today's Focus",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${due.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.go('/review'),
                  child: const Text(
                    'Review All →',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.indigo,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Cards
          SizedBox(
            height: 210,
            child: PageView.builder(
              controller: _pageController,
              itemCount: due.length,
              onPageChanged: (i) => setState(() => _activePage = i),
              itemBuilder: (context, i) {
                final card = due[i];
                final isActive = i == _activePage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  margin: EdgeInsets.only(
                    left: i == 0 ? 16 : 6,
                    right: i == due.length - 1 ? 16 : 6,
                    top: isActive ? 0 : 14,
                    bottom: isActive ? 0 : 14,
                  ),
                  child: isActive
                      ? _ActiveFocusCard(card: card)
                      : _InactiveFocusCard(card: card),
                );
              },
            ),
          ),

          // Dot indicators
          if (due.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  due.length.clamp(0, 8),
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i == _activePage ? 16 : 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i == _activePage
                          ? AppColors.accent
                          : AppColors.surface3,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ActiveFocusCard extends StatelessWidget {
  final FlashCard card;

  const _ActiveFocusCard({required this.card});

  @override
  Widget build(BuildContext context) {
    final color = _masteryColorFor(card);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.surface3.withOpacity(0.5), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  card.word,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ProgressRing(
                progress: cardProgress(card),
                color: color,
                size: 38,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            card.translation ?? '',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.go('/review'),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.indigo.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.indigo.withOpacity(0.25), width: 0.5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow_rounded,
                      size: 16, color: AppColors.indigo),
                  SizedBox(width: 4),
                  Text(
                    'Review Now',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.indigo,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InactiveFocusCard extends StatelessWidget {
  final FlashCard card;

  const _InactiveFocusCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppColors.surface3.withOpacity(0.3), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.word,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            card.translation ?? '',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textDim,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Swipe-to-delete helpers ──────────────────────────────────────────────────

class _PendingDelete {
  final FlashCard card;
  _PendingDelete({required this.card});
}

/// Custom swipe-to-delete with resistance (rubber-band feel).
class _SwipeToDelete extends StatefulWidget {
  final Widget child;
  final VoidCallback onDeleted;
  const _SwipeToDelete({required this.child, required this.onDeleted});

  @override
  State<_SwipeToDelete> createState() => _SwipeToDeleteState();
}

class _SwipeToDeleteState extends State<_SwipeToDelete>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  late AnimationController _animCtrl;
  Animation<double>? _snapBack;
  VoidCallback? _snapBackListener;
  bool _dismissed = false;
  static const _deleteThreshold = 0.55; // 55% of width to trigger delete
  static const _resistance = 0.35; // rubber-band resistance factor

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails d) {
    if (_dismissed) return;
    // Only allow left swipe (negative delta)
    final raw = _dragOffset + d.delta.dx;
    if (raw > 0) {
      setState(() => _dragOffset = 0);
      return;
    }
    // Apply rubber-band resistance: the further you drag, the harder it gets
    final width = context.size?.width ?? 300;
    final ratio = (_dragOffset.abs() / width).clamp(0.0, 1.0);
    final dampened = d.delta.dx * (1.0 - ratio * _resistance);
    setState(() {
      _dragOffset = (_dragOffset + dampened).clamp(-width, 0.0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails d) {
    if (_dismissed) return;
    final width = context.size?.width ?? 300;
    final ratio = _dragOffset.abs() / width;

    // Remove previous listener to prevent accumulation
    if (_snapBack != null && _snapBackListener != null) {
      _snapBack!.removeListener(_snapBackListener!);
    }

    if (ratio >= _deleteThreshold) {
      // Animate off screen then delete
      _dismissed = true;
      final startOffset = _dragOffset;
      _snapBack = Tween<double>(begin: startOffset, end: -width)
          .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn));
      _snapBackListener = () => setState(() => _dragOffset = _snapBack!.value);
      _snapBack!.addListener(_snapBackListener!);
      _animCtrl.forward(from: 0).then((_) {
        if (mounted) widget.onDeleted();
      });
    } else {
      // Snap back with spring
      final startOffset = _dragOffset;
      _snapBack = Tween<double>(begin: startOffset, end: 0.0).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut),
      );
      _snapBackListener = () {
        if (mounted) setState(() => _dragOffset = _snapBack!.value);
      };
      _snapBack!.addListener(_snapBackListener!);
      _animCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final ratio = (_dragOffset.abs() / width).clamp(0.0, 1.0);
    final showDelete = ratio > 0.05;

    return Stack(
      children: [
        // Red background revealed behind
        if (showDelete)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Color.lerp(
                  AppColors.red.withOpacity(0.08),
                  AppColors.red.withOpacity(0.25),
                  ratio,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.red.withOpacity(0.5 + ratio * 0.5),
                size: 28,
              ),
            ),
          ),
        // The card itself
        GestureDetector(
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          child: Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

/// Inline undo row that appears where the deleted card was.
class _UndoRow extends StatefulWidget {
  final String word;
  final VoidCallback onUndo;
  const _UndoRow({required this.word, required this.onUndo});

  @override
  State<_UndoRow> createState() => _UndoRowState();
}

class _UndoRowState extends State<_UndoRow> {
  int _seconds = 4;
  late final _timer = Timer.periodic(const Duration(seconds: 1), (t) {
    if (!mounted) { t.cancel(); return; }
    setState(() => _seconds--);
    if (_seconds <= 0) t.cancel();
  });

  @override
  void initState() {
    super.initState();
    _timer; // start
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.red.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.delete_outline_rounded,
              size: 18, color: AppColors.red.withOpacity(0.6)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '"${widget.word}" deleted',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$_seconds',
            style: TextStyle(
              color: AppColors.textDim,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: widget.onUndo,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Undo',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Collection island ─────────────────────────────────────────────────────────

class _CollectionIsland extends ConsumerStatefulWidget {
  final List<Collection> collections;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _CollectionIsland({
    required this.collections,
    required this.selected,
    required this.onSelected,
  });

  @override
  ConsumerState<_CollectionIsland> createState() => _CollectionIslandState();
}

class _CollectionIslandState extends ConsumerState<_CollectionIsland> {
  late List<Collection> _ordered;
  String? _pendingMoveId;
  BuildContext? _stateContext;
  // Key on the island container — used to get exact screen Y for menu positioning
  final _islandKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _ordered = _sorted(widget.collections);
  }

  @override
  void didUpdateWidget(_CollectionIsland old) {
    super.didUpdateWidget(old);
    // Re-sync if a collection was added/removed from outside
    if (old.collections.length != widget.collections.length) {
      _ordered = _sorted(widget.collections);
    }
  }

  List<Collection> _sorted(List<Collection> src) =>
      List.from(src)..sort((a, b) => a.position.compareTo(b.position));

  void _onReorder(int oldIdx, int newIdx) {
    setState(() {
      if (newIdx > oldIdx) newIdx--;
      final item = _ordered.removeAt(oldIdx);
      _ordered.insert(newIdx, item);
      _pendingMoveId = null;
    });
    // Persist updated positions
    final notifier = ref.read(collectionProvider.notifier);
    for (int i = 0; i < _ordered.length; i++) {
      if (_ordered[i].position != i) {
        notifier.update(_ordered[i].copyWith(position: i));
      }
    }
  }

  Future<void> _showContextMenu(Offset globalPos, Collection c) async {
    final ctx = _stateContext;
    if (ctx == null || !ctx.mounted) return;
    HapticFeedback.mediumImpact();
    final screen = MediaQuery.of(ctx).size;
    // Get the island's top Y so the menu sits right above it.
    final islandBox =
        _islandKey.currentContext?.findRenderObject() as RenderBox?;
    final islandTopY = islandBox != null
        ? islandBox.localToGlobal(Offset.zero).dy
        : globalPos.dy - 8;
    final result = await showMenu<String>(
      context: ctx,
      color: AppColors.surface2,
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      position: RelativeRect.fromLTRB(
        (globalPos.dx - 80).clamp(8, screen.width - 168),
        islandTopY - 104,             // menu ~100px above island top
        (screen.width - globalPos.dx - 80).clamp(8, screen.width - 168),
        screen.height - islandTopY + 4, // no room below → forces upward
      ),
      items: [
        PopupMenuItem(
          value: 'edit',
          height: 40,
          child: Row(children: [
            const Icon(Icons.edit_outlined,
                size: 15, color: AppColors.textMuted),
            const SizedBox(width: 10),
            const Text('Edit',
                style: TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem(
          value: 'move',
          height: 40,
          child: Row(children: [
            const Icon(Icons.open_with_rounded,
                size: 15, color: AppColors.textMuted),
            const SizedBox(width: 10),
            const Text('Move',
                style: TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
      ],
    );
    if (result == 'edit') {
      _showEditSheet(c);
    } else if (result == 'move') {
      setState(() => _pendingMoveId = c.id);
      // Auto-cancel move mode after 6 s of no interaction
      Future.delayed(const Duration(seconds: 6), () {
        if (mounted && _pendingMoveId == c.id) {
          setState(() => _pendingMoveId = null);
        }
      });
    }
  }

  void _showEditSheet(Collection c) async {
    HapticFeedback.mediumImpact();
    final result = await context.push<String>('/collections/edit', extra: c);
    if (result == 'deleted' && widget.selected == c.id) {
      widget.onSelected(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    _stateContext = context;
    final isEmpty = _ordered.isEmpty;

    // Empty state: just "New Collection" + "+"
    if (isEmpty) {
      return ClipRRect(
        key: _islandKey,
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: GestureDetector(
            onTap: () => context.push('/collections/new'),
            child: Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.94),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.surface3.withOpacity(0.4), width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'New Collection',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 0.5,
                    height: 36,
                    color: AppColors.surface3.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.add_rounded,
                      size: 20, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Build collection buttons as a list to measure if we need scrolling
    final collectionButtons = <Widget>[];
    for (int i = 0; i < _ordered.length; i++) {
      final c = _ordered[i];
      final isSelected = widget.selected == c.id;
      final isMoveMode = _pendingMoveId == c.id;

      final btn = GestureDetector(
        onTap: () {
          if (isMoveMode) {
            setState(() => _pendingMoveId = null);
          } else {
            widget.onSelected(c.id);
          }
        },
        onLongPressStart: isMoveMode
            ? null
            : (d) => _showContextMenu(d.globalPosition, c),
        child: _IslandBtn(
          label: c.name,
          emoji: c.emoji,
          isSelected: isSelected,
          isMoveMode: isMoveMode,
        ),
      );

      if (isMoveMode) {
        collectionButtons.add(
          ReorderableDragStartListener(
            key: ValueKey(c.id),
            index: i,
            child: btn
                .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
                .moveX(
                    begin: -2.5,
                    end: 2.5,
                    duration: 280.ms,
                    curve: Curves.easeInOut),
          ),
        );
      } else {
        collectionButtons.add(KeyedSubtree(key: ValueKey(c.id), child: btn));
      }
    }

    // Estimate per-button width: ~24px padding + ~30px content ≈ 54px each
    // "All" ≈ 50px, "+" ≈ 50px, dividers ≈ 1px each
    const btnWidth = 54.0;
    const fixedWidth = 50.0 + 50.0 + 1.0 + 1.0; // All + New + 2 dividers
    final contentWidth = fixedWidth + (_ordered.length * btnWidth) + 4;
    final maxWidth = MediaQuery.of(context).size.width - 32;
    final isOverflowing = contentWidth > maxWidth;

    return ClipRRect(
      key: _islandKey,
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: 70,
          width: isOverflowing ? maxWidth : null,
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.94),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.surface3.withOpacity(0.4), width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // "All" — fixed, non-reorderable
              GestureDetector(
                onTap: () => widget.onSelected(null),
                child: _IslandBtn(
                  label: 'All',
                  icon: Icons.auto_awesome_rounded,
                  isSelected: widget.selected == null,
                ),
              ),
              // Thin divider
              Container(
                width: 0.5,
                height: 36,
                color: AppColors.surface3.withOpacity(0.6),
              ),
              // Collections
              isOverflowing
                  ? Expanded(
                      child: ReorderableListView.builder(
                        scrollDirection: Axis.horizontal,
                        buildDefaultDragHandles: false,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        onReorder: _onReorder,
                        itemCount: _ordered.length,
                        itemBuilder: (context, i) => collectionButtons[i],
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: collectionButtons,
                    ),
              // Thin divider
              Container(
                width: 0.5,
                height: 36,
                color: AppColors.surface3.withOpacity(0.6),
              ),
              // "+" — fixed, non-reorderable
              GestureDetector(
                onTap: () => context.push('/collections/new'),
                child: _IslandBtn(
                  label: 'New',
                  icon: Icons.add_rounded,
                  isSelected: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Collection edit sheet ─────────────────────────────────────────────────────


// ── Island button ─────────────────────────────────────────────────────────────

class _IslandBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? emoji;
  final bool isSelected;
  final bool isMoveMode;

  const _IslandBtn({
    required this.label,
    this.icon,
    this.emoji,
    required this.isSelected,
    this.isMoveMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isMoveMode
        ? AppColors.accent.withOpacity(0.6)
        : isSelected
            ? AppColors.indigo.withOpacity(0.3)
            : Colors.transparent;
    final Color bgColor = isMoveMode
        ? AppColors.accent.withOpacity(0.08)
        : isSelected
            ? AppColors.indigo.withOpacity(0.12)
            : Colors.transparent;
    final Color labelColor = isMoveMode
        ? AppColors.accent
        : isSelected
            ? AppColors.indigo
            : AppColors.textDim;

    return AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon,
                  size: 18,
                  color: isMoveMode
                      ? AppColors.accent
                      : isSelected
                          ? AppColors.indigo
                          : AppColors.textMuted)
            else
              Text(emoji ?? '📚', style: AppTheme.emojiStyle.copyWith(fontSize: 18)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Drag-mode indicator: two small arrows
            if (isMoveMode) ...[
              const SizedBox(height: 2),
              const Icon(Icons.swap_horiz_rounded,
                  size: 10, color: AppColors.accent),
            ],
          ],
        ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasSearch;

  const _EmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasSearch ? Icons.search_off_rounded : Icons.layers_outlined,
            size: 56,
            color: AppColors.textDim,
          )
              .animate()
              .scale(
                begin: const Offset(0.7, 0.7),
                duration: 400.ms,
                curve: Curves.easeOut,
              )
              .fade(duration: 300.ms),
          const SizedBox(height: 14),
          Text(
            hasSearch
                ? 'No words match your search'
                : 'No words yet.\nStart translating!',
            style: const TextStyle(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          )
              .animate(delay: 120.ms)
              .fade(duration: 300.ms)
              .slideY(begin: 0.2, end: 0, duration: 300.ms),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _masteryColorFor(FlashCard c) {
  switch (masteryLabelFor(c)) {
    case 'New':
      return AppColors.textMuted;
    case 'Learning':
      return AppColors.accent;
    case 'Review':
      return AppColors.indigo;
    case 'Mature':
      return AppColors.green;
    default:
      return AppColors.textDim;
  }
}
