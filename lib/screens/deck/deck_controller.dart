import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/flash_card.dart';
import '../../modules/auth/auth_provider.dart';
import '../../modules/cards/card_provider.dart';

// ── State ──────────────────────────────────────────────────────────────────

class DeckControllerState {
  final String searchQuery;

  /// 'All' | 'New' | 'Learning' | 'Review' | 'Mature'
  final String masteryFilter;

  const DeckControllerState({
    this.searchQuery   = '',
    this.masteryFilter = 'All',
  });

  DeckControllerState copyWith({
    String? searchQuery,
    String? masteryFilter,
  }) =>
      DeckControllerState(
        searchQuery:   searchQuery   ?? this.searchQuery,
        masteryFilter: masteryFilter ?? this.masteryFilter,
      );
}

// ── Notifier ───────────────────────────────────────────────────────────────

class DeckController extends StateNotifier<DeckControllerState> {
  final Ref _ref;

  DeckController(this._ref) : super(const DeckControllerState());

  Future<void> loadCards() async {
    final userId = _ref.read(currentUserProvider)?.userId;
    if (userId == null) return;
    await _ref.read(cardListProvider.notifier).loadCards(userId);
  }

  void setFilter(String filter) =>
      state = state.copyWith(masteryFilter: filter);

  void setSearch(String query) =>
      state = state.copyWith(searchQuery: query);

  Future<void> deleteCard(String cardId) async {
    await _ref.read(cardListProvider.notifier).deleteCard(cardId);
  }

  Future<void> clearAll() async {
    final userId = _ref.read(currentUserProvider)?.userId;
    if (userId == null) return;
    await _ref.read(cardRepositoryProvider).clearAllCards(userId);
    await loadCards();
  }
}

// ── Providers ──────────────────────────────────────────────────────────────

final deckControllerProvider =
    StateNotifierProvider<DeckController, DeckControllerState>(
  (ref) => DeckController(ref),
);

/// Filtered + searched card list, derived from cardListProvider + deckController.
final filteredDeckCardsProvider = Provider<List<FlashCard>>((ref) {
  final allCards = ref.watch(cardListProvider).allCards;
  final deckState = ref.watch(deckControllerProvider);
  return _applyFilter(allCards, deckState.masteryFilter, deckState.searchQuery);
});

// ── Mastery helpers ────────────────────────────────────────────────────────

String masteryLabelFor(FlashCard c) {
  if (c.repetitions == 0) return 'New';
  if (c.intervalDays < 7) return 'Learning';
  if (c.intervalDays < 21) return 'Review';
  return 'Mature';
}

double masteryProgressFor(FlashCard c) {
  if (c.repetitions == 0) return 0.0;
  if (c.intervalDays < 7) return 0.25;
  if (c.intervalDays < 21) return 0.6;
  return 1.0;
}

List<FlashCard> _applyFilter(
    List<FlashCard> cards, String filter, String query) {
  var result = cards;

  if (filter != 'All') {
    result = result.where((c) => masteryLabelFor(c) == filter).toList();
  }

  if (query.isNotEmpty) {
    final q = query.toLowerCase();
    result = result
        .where((c) =>
            c.word.toLowerCase().contains(q) ||
            (c.translation?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  return result;
}
