import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../contracts/i_card_repository.dart';
import '../../core/errors/failure.dart';
import '../../models/flash_card.dart';
import '../auth/auth_provider.dart';
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

  CardListNotifier(this._repo) : super(const CardListState());

  Future<void> loadCards(String userId) async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    try {
      final cards = await _repo.getAllCards(userId);
      state = state.copyWith(allCards: cards, isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        failure: DatabaseFailure(e.toString()),
      );
    }
  }

  Future<void> saveCard(FlashCard card) async {
    try {
      final saved = await _repo.saveCard(card);
      state = state.copyWith(
        allCards: [saved, ...state.allCards],
      );
    } on Exception catch (e) {
      state = state.copyWith(failure: DatabaseFailure(e.toString()));
    }
  }

  Future<void> updateCard(FlashCard card) async {
    try {
      final updated = await _repo.updateCard(card);
      final idx = state.allCards.indexWhere((c) => c.id == card.id);
      if (idx >= 0) {
        final newList = [...state.allCards];
        newList[idx] = updated;
        state = state.copyWith(allCards: newList);
      }
    } on Exception catch (e) {
      state = state.copyWith(failure: DatabaseFailure(e.toString()));
    }
  }

  Future<void> deleteCard(String cardId) async {
    try {
      await _repo.deleteCard(cardId);
      state = state.copyWith(
        allCards: state.allCards.where((c) => c.id != cardId).toList(),
      );
    } on Exception catch (e) {
      state = state.copyWith(failure: DatabaseFailure(e.toString()));
    }
  }

  void setSearch(String query) =>
      state = state.copyWith(searchQuery: query);

  void setStatusFilter(CardStatus? status) =>
      state = state.copyWith(
        statusFilter: status,
        clearStatusFilter: status == null,
      );

  void clearFailure() => state = state.copyWith(clearFailure: true);
}

final cardListProvider =
    StateNotifierProvider<CardListNotifier, CardListState>(
  (ref) => CardListNotifier(ref.read(cardRepositoryProvider)),
);

// ── Derived providers ─────────────────────────────────────────────────────────

final dueCardsCountProvider = Provider<int>(
  (ref) => ref.watch(cardListProvider).dueCount,
);

final dueCardsProvider = Provider<List<FlashCard>>(
  (ref) => ref.watch(cardListProvider).dueCards,
);
