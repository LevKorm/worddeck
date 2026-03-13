import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/flash_card.dart';

class CardCache {
  static const _prefix = 'cards_v1_';

  String _key(String userId, {String? spaceId}) =>
      spaceId != null ? '$_prefix${userId}_$spaceId' : '$_prefix$userId';

  Future<List<FlashCard>> load(String userId, {String? spaceId}) async {
    final prefs = await SharedPreferences.getInstance();
    // Try space-scoped key first; fall back to legacy key for migration
    final raw = prefs.getString(_key(userId, spaceId: spaceId)) ??
        (spaceId != null ? prefs.getString('$_prefix$userId') : null);
    if (raw == null) return [];
    final list = json.decode(raw) as List<dynamic>;
    return list
        .map((e) => FlashCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(String userId, List<FlashCard> cards,
      {String? spaceId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(userId, spaceId: spaceId),
      json.encode(cards.map((c) => c.toJson()).toList()),
    );
  }

  Future<void> upsert(String userId, FlashCard card, {String? spaceId}) async {
    final effectiveSpaceId = spaceId ?? card.spaceId;
    final cards = await load(userId, spaceId: effectiveSpaceId);
    final idx = cards.indexWhere((c) => c.id == card.id);
    if (idx >= 0) {
      cards[idx] = card;
    } else {
      cards.insert(0, card);
    }
    await save(userId, cards, spaceId: effectiveSpaceId);
  }

  Future<void> remove(String userId, String cardId, {String? spaceId}) async {
    final cards = await load(userId, spaceId: spaceId);
    cards.removeWhere((c) => c.id == cardId);
    await save(userId, cards, spaceId: spaceId);
  }
}

final cardCacheProvider = Provider<CardCache>((ref) => CardCache());
