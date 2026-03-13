import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/collection.dart';

class CollectionCache {
  static const _prefix = 'collections_v1_';

  Future<List<Collection>> load(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$userId');
    if (raw == null) return [];
    final list = json.decode(raw) as List<dynamic>;
    return list
        .map((e) => Collection.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(String userId, List<Collection> collections) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefix$userId',
      json.encode(collections.map((c) => c.toJson()).toList()),
    );
  }

  Future<void> upsert(String userId, Collection collection) async {
    final list = await load(userId);
    final idx = list.indexWhere((c) => c.id == collection.id);
    if (idx >= 0) {
      list[idx] = collection;
    } else {
      list.add(collection);
    }
    await save(userId, list);
  }

  Future<void> remove(String userId, String collectionId) async {
    final list = await load(userId);
    list.removeWhere((c) => c.id == collectionId);
    await save(userId, list);
  }
}

final collectionCacheProvider = Provider<CollectionCache>((ref) => CollectionCache());
