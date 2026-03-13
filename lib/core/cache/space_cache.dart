import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/space.dart';

class SpaceCache {
  static const _prefix = 'spaces_v1_';

  Future<List<Space>> load(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$userId');
    if (raw == null) return [];
    final list = json.decode(raw) as List<dynamic>;
    return list
        .map((e) => Space.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(String userId, List<Space> spaces) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefix$userId',
      json.encode(spaces.map((s) => s.toJson()).toList()),
    );
  }

  Future<void> upsert(String userId, Space space) async {
    final spaces = await load(userId);
    final idx = spaces.indexWhere((s) => s.id == space.id);
    if (idx >= 0) {
      spaces[idx] = space;
    } else {
      spaces.add(space);
    }
    await save(userId, spaces);
  }

  Future<void> remove(String userId, String spaceId) async {
    final spaces = await load(userId);
    spaces.removeWhere((s) => s.id == spaceId);
    await save(userId, spaces);
  }
}

final spaceCacheProvider = Provider<SpaceCache>((ref) => SpaceCache());
