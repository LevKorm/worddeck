import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../modules/cards/card_provider.dart';

/// Returns the set of words (lowercased) that have been saved as child cards
/// of the given parent card ID. Used to accent-style synonym chips that the
/// user has already added to their deck.
final synonymChildrenProvider = Provider.family<Set<String>, String>(
  (ref, parentCardId) {
    final cards = ref.watch(cardListProvider).allCards;
    return cards
        .where((c) => c.parentCardId == parentCardId)
        .map((c) => c.word.toLowerCase())
        .toSet();
  },
);
