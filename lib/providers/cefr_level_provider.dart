import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/cefr/cefr_level_calculator.dart';
import '../modules/cards/card_provider.dart';

final cefrLevelProvider = Provider<CefrLevelResult>((ref) {
  final cards = ref.watch(cardListProvider).allCards;
  return calculateCefrLevel(cards);
});
