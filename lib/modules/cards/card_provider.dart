import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../contracts/i_card_repository.dart';
import '../../contracts/i_collection_repository.dart';
import '../../core/cache/card_cache.dart';
import '../../core/errors/failure.dart';
import '../../models/flash_card.dart';
import '../auth/auth_provider.dart';
import '../collections/collection_repository.dart';
import 'card_repository.dart';

// ── Repository provider ───────────────────────────────────────────────────────

final cardRepositoryProvider = Provider<ICardRepository>(
  (ref) => SupabaseCardRepository(ref.read(supabaseClientProvider)),
);

// ── Card list state ───────────────────────────────────────────────────────────

class CardListState {
  final List<FlashCard> allCards;
  final String searchQuery;
  final CardStatus? statusFilter;
  final bool isLoading;
  final Failure? failure;

  const CardListState({
    this.allCards = const [],
    this.searchQuery = '',
    this.statusFilter,
    this.isLoading = false,
    this.failure,
  });

  List<FlashCard> get filteredCards {
    var cards = allCards;
    if (statusFilter != null) {
      cards = cards.where((c) => c.status == statusFilter).toList();
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      cards = cards.where((c) =>
          c.word.toLowerCase().contains(q) ||
          (c.translation?.toLowerCase().contains(q) ?? false)).toList();
    }
    return cards;
  }

  List<FlashCard> get dueCards =>
      allCards.where((c) => c.isDue).toList();

  int get dueCount => dueCards.length;

  CardListState copyWith({
    List<FlashCard>? allCards,
    String? searchQuery,
    CardStatus? statusFilter,
    bool? clearStatusFilter,
    bool? isLoading,
    Failure? failure,
    bool? clearFailure,
  }) =>
      CardListState(
        allCards: allCards ?? this.allCards,
        searchQuery: searchQuery ?? this.searchQuery,
        statusFilter: clearStatusFilter == true ? null : statusFilter ?? this.statusFilter,
        isLoading: isLoading ?? this.isLoading,
        failure: clearFailure == true ? null : failure ?? this.failure,
      );
}

// ── Card list notifier ────────────────────────────────────────────────────────

class CardListNotifier extends StateNotifier<CardListState> {
  final ICardRepository _repo;
  final CardCache _cache;
  final ICollectionRepository _collectionRepo;

  CardListNotifier(this._repo, this._cache, this._collectionRepo)
      : super(const CardListState());

  Future<void> loadCards(String userId, {String? spaceId}) async {
    // 1. Emit cached cards immediately — no spinner
    final cached = await _cache.load(userId, spaceId: spaceId);
    if (cached.isNotEmpty) {
      state = state.copyWith(allCards: cached, isLoading: false, clearFailure: true);
    } else {
      state = state.copyWith(isLoading: true, clearFailure: true);
    }

    // 2. Fetch from Supabase in the background
    try {
      final cards = await _repo.getAllCards(userId, spaceId: spaceId);
      state = state.copyWith(allCards: cards, isLoading: false);
      _cache.save(userId, cards, spaceId: spaceId); // fire-and-forget
    } on Exception catch (e) {
      if (cached.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          failure: DatabaseFailure(e.toString()),
        );
      } else {
        // Keep showing cached data; clear spinner silently
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<void> saveCard(FlashCard card) async {
    try {
      final saved = await _repo.saveCard(card);
      state = state.copyWith(
        allCards: [saved, ...state.allCards],
      );
      _cache.upsert(saved.userId, saved, spaceId: saved.spaceId); // fire-and-forget
    } on Exception catch (e) {
      state = state.copyWith(failure: DatabaseFailure(e.toString()));
    }
  }

  void updateCard(FlashCard card) {
    // 1. Patch in-memory state immediately
    final idx = state.allCards.indexWhere((c) => c.id == card.id);
    if (idx >= 0) {
      final newList = [...state.allCards];
      newList[idx] = card;
      state = state.copyWith(allCards: newList);
    }

    // 2. Update cache immediately (fire-and-forget)
    if (state.allCards.isNotEmpty) {
      _cache.upsert(card.userId, card, spaceId: card.spaceId);
    }

    // 3. Persist to Supabase in background (fire-and-forget)
    _repo.updateCard(card).then<void>((_) {}, onError: (_) {});
  }

  Future<void> deleteCard(String cardId) async {
    // 1. Remove from in-memory state immediately
    final card = state.allCards.where((c) => c.id == cardId).firstOrNull;
    if (card == null) return; // already deleted
    state = state.copyWith(
      allCards: state.allCards.where((c) => c.id != cardId).toList(),
    );

    // 2. Remove from cache immediately (fire-and-forget)
    _cache.remove(card.userId, cardId, spaceId: card.spaceId);

    // 3. Persist to Supabase in background (fire-and-forget)
    _repo.deleteCard(cardId).catchError((_) {});
  }

  /// Restore a previously deleted card (undo).
  void restoreCard(FlashCard card) {
    // 1. Add back to in-memory state
    state = state.copyWith(allCards: [...state.allCards, card]);

    // 2. Re-add to cache
    _cache.upsert(card.userId, card, spaceId: card.spaceId);

    // 3. Re-save to Supabase (upsert)
    _repo.saveCard(card).then<void>((_) {}, onError: (_) {});
  }

  void setSearch(String query) =>
      state = state.copyWith(searchQuery: query);

  void setStatusFilter(CardStatus? status) =>
      state = state.copyWith(
        statusFilter: status,
        clearStatusFilter: status == null,
      );

  void clearFailure() => state = state.copyWith(clearFailure: true);

  /// Move a single card to a collection (or remove from collection with null).
  /// Optimistic update + fire-and-forget Supabase.
  void updateCardCollection(String cardId, String? collectionId) {
    final idx = state.allCards.indexWhere((c) => c.id == cardId);
    if (idx < 0) return;

    final updated = state.allCards[idx].copyWith(
      collectionId: collectionId,
      clearCollectionId: collectionId == null,
    );
    final newList = [...state.allCards];
    newList[idx] = updated;
    state = state.copyWith(allCards: newList);
    _cache.upsert(updated.userId, updated);

    _collectionRepo
        .assignCardToCollection(cardId, collectionId)
        .then<void>((_) {}, onError: (_) {});
  }

  /// Bulk-move multiple cards to a collection. Optimistic update.
  void moveCardsToCollection(List<String> cardIds, String collectionId) {
    final newList = state.allCards.map((c) {
      if (!cardIds.contains(c.id)) return c;
      return c.copyWith(collectionId: collectionId);
    }).toList();
    state = state.copyWith(allCards: newList);
    for (final c in newList.where((c) => cardIds.contains(c.id))) {
      _cache.upsert(c.userId, c);
    }

    _collectionRepo
        .assignCardsToCollection(cardIds, collectionId)
        .then<void>((_) {}, onError: (_) {});
  }
}

final collectionRepositoryForCardsProvider = Provider<ICollectionRepository>(
  (ref) => SupabaseCollectionRepository(ref.read(supabaseClientProvider)),
);

final cardListProvider =
    StateNotifierProvider<CardListNotifier, CardListState>(
  (ref) => CardListNotifier(
    ref.read(cardRepositoryProvider),
    ref.read(cardCacheProvider),
    ref.read(collectionRepositoryForCardsProvider),
  ),
);

// ── Derived providers ─────────────────────────────────────────────────────────

final dueCardsCountProvider = Provider<int>(
  (ref) => ref.watch(cardListProvider).dueCount,
);

final dueCardsProvider = Provider<List<FlashCard>>(
  (ref) => ref.watch(cardListProvider).dueCards,
);
