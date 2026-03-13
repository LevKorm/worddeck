import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modules/auth/auth_provider.dart';
import '../../modules/cards/card_provider.dart';
import '../../modules/spaces/space_provider.dart';
import '../../models/flash_card.dart';

// ── State ──────────────────────────────────────────────────────────────────

class DeckControllerState {
  final String searchQuery;

  const DeckControllerState({this.searchQuery = ''});

  DeckControllerState copyWith({String? searchQuery}) =>
      DeckControllerState(searchQuery: searchQuery ?? this.searchQuery);
}

// ── Notifier ───────────────────────────────────────────────────────────────

class DeckController extends StateNotifier<DeckControllerState> {
  final Ref _ref;

  DeckController(this._ref) : super(const DeckControllerState());

  Future<void> loadCards() async {
    final userId = _ref.read(currentUserProvider)?.userId;
    if (userId == null) return;
    final spaceId = _ref.read(activeSpaceProvider)?.id;
    await _ref.read(cardListProvider.notifier).loadCards(userId, spaceId: spaceId);
  }

  void setSearch(String query) =>
      state = state.copyWith(searchQuery: query);

  Future<void> deleteCard(String cardId) async {
    await _ref.read(cardListProvider.notifier).deleteCard(cardId);
  }

  void restoreCard(FlashCard card) {
    _ref.read(cardListProvider.notifier).restoreCard(card);
  }

  Future<void> clearAll() async {
    final userId = _ref.read(currentUserProvider)?.userId;
    if (userId == null) return;
    await _ref.read(cardRepositoryProvider).clearAllCards(userId);
    await loadCards();
  }
}

// ── Provider ───────────────────────────────────────────────────────────────

final deckControllerProvider =
    StateNotifierProvider<DeckController, DeckControllerState>(
  (ref) => DeckController(ref),
);

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

/// Smooth 0.0–1.0 progress value for the circular ring on word cards.
double cardProgress(FlashCard c) {
  if (c.repetitions == 0) return 0.0;
  final d = c.intervalDays;
  if (d < 7)  return (d / 7.0).clamp(0.0, 1.0);
  if (d < 21) return 0.33 + ((d - 7) / 14.0 * 0.34).clamp(0.0, 0.34);
  return (0.67 + ((d - 21) / 60.0).clamp(0.0, 1.0) * 0.33).clamp(0.0, 1.0);
}
