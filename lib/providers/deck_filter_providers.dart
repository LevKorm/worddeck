import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/flash_card.dart';
import '../modules/cards/card_provider.dart';
import '../screens/deck/deck_controller.dart';

// ── Filter enums ──────────────────────────────────────────────────────────────

enum DeckStatusFilter {
  all,
  newCard,
  learning,
  review,
  mature;

  String get label {
    switch (this) {
      case DeckStatusFilter.all:      return 'All';
      case DeckStatusFilter.newCard:  return 'New';
      case DeckStatusFilter.learning: return 'Learning';
      case DeckStatusFilter.review:   return 'Review';
      case DeckStatusFilter.mature:   return 'Mature';
    }
  }
}

enum DeckSortOption {
  dateAdded,
  alphabetical,
  nextReview,
  difficulty;

  String get label {
    switch (this) {
      case DeckSortOption.dateAdded:     return 'Date added';
      case DeckSortOption.alphabetical:  return 'Alphabetical';
      case DeckSortOption.nextReview:    return 'Next review';
      case DeckSortOption.difficulty:    return 'Difficulty';
    }
  }
}

// ── Simple state providers ────────────────────────────────────────────────────

final deckStatusFilterProvider =
    StateProvider<DeckStatusFilter>((ref) => DeckStatusFilter.all);

/// null = "All" tab (no collection filter).
final deckCollectionFilterProvider =
    StateProvider<String?>((ref) => null);

final deckSortProvider =
    StateProvider<DeckSortOption>((ref) => DeckSortOption.dateAdded);

final deckSelectModeProvider = StateProvider<bool>((ref) => false);

final deckSelectedCardsProvider =
    StateProvider<Set<String>>((ref) => {});

/// Set of selected CEFR levels. Empty = show all.
final deckCefrFilterProvider =
    StateProvider<Set<String>>((ref) => {});

// ── Filtered + sorted card list ───────────────────────────────────────────────

final filteredDeckCardsProvider = Provider<List<FlashCard>>((ref) {
  final allCards = ref.watch(cardListProvider).allCards;
  final statusFilter = ref.watch(deckStatusFilterProvider);
  final collectionFilter = ref.watch(deckCollectionFilterProvider);
  final cefrFilter = ref.watch(deckCefrFilterProvider);
  final searchQuery =
      ref.watch(deckControllerProvider).searchQuery.toLowerCase();
  final sortOption = ref.watch(deckSortProvider);

  var cards = allCards;

  // 1. Collection filter
  if (collectionFilter != null) {
    cards = cards.where((c) => c.collectionId == collectionFilter).toList();
  }

  // 2. Status filter
  if (statusFilter != DeckStatusFilter.all) {
    cards = cards
        .where((c) => masteryLabelFor(c) == statusFilter.label)
        .toList();
  }

  // 3. CEFR filter
  if (cefrFilter.isNotEmpty) {
    cards = cards.where((c) => cefrFilter.contains(c.cefrLevel)).toList();
  }

  // 4. Search
  if (searchQuery.isNotEmpty) {
    cards = cards
        .where((c) =>
            c.word.toLowerCase().contains(searchQuery) ||
            (c.translation?.toLowerCase().contains(searchQuery) ?? false))
        .toList();
  }

  // 5. Sort
  switch (sortOption) {
    case DeckSortOption.alphabetical:
      cards.sort(
          (a, b) => a.word.toLowerCase().compareTo(b.word.toLowerCase()));
    case DeckSortOption.dateAdded:
      cards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    case DeckSortOption.nextReview:
      cards.sort((a, b) => a.nextReview.compareTo(b.nextReview));
    case DeckSortOption.difficulty:
      cards.sort((a, b) => a.easeFactor.compareTo(b.easeFactor));
  }

  return cards;
});
