import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modules/auth/auth_provider.dart';
import '../../modules/cards/card_provider.dart';
import '../../modules/spaces/space_provider.dart';

// ── Notifier ───────────────────────────────────────────────────────────────

/// Minimal controller for the Stats screen — just exposes a refresh action.
/// Actual statistics data is consumed from [fullStatisticsProvider] directly.
class StatsController extends StateNotifier<bool> {
  final Ref _ref;

  StatsController(this._ref) : super(false) {
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    final userId = _ref.read(currentUserProvider)?.userId;
    if (userId == null) return;
    final cards = _ref.read(cardListProvider).allCards;
    if (cards.isEmpty) {
      final spaceId = _ref.read(activeSpaceProvider)?.id;
      await _ref.read(cardListProvider.notifier).loadCards(userId, spaceId: spaceId);
    }
  }

  Future<void> refresh() async {
    state = true;
    final userId = _ref.read(currentUserProvider)?.userId;
    if (userId != null) {
      final spaceId = _ref.read(activeSpaceProvider)?.id;
      await _ref.read(cardListProvider.notifier).loadCards(userId, spaceId: spaceId);
    }
    state = false;
  }
}

// ── Provider ───────────────────────────────────────────────────────────────

final statsControllerProvider =
    StateNotifierProvider.autoDispose<StatsController, bool>(
  (ref) => StatsController(ref),
);
