import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/feed_post.dart';

class FeedCache {
  static const _prefix = 'feed_cache_';

  String _key(String userId, {String? spaceId}) =>
      spaceId != null ? '$_prefix${userId}_$spaceId' : '$_prefix$userId';

  Future<List<FeedPost>> load(String userId, {String? spaceId}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId, spaceId: spaceId));
    if (raw == null) return [];
    final list = json.decode(raw) as List<dynamic>;
    return list
        .map((e) => FeedPost.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(String userId, List<FeedPost> posts,
      {String? spaceId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(userId, spaceId: spaceId),
      json.encode(posts.map((p) => p.toJson()).toList()),
    );
  }
}

final feedCacheProvider = Provider<FeedCache>((ref) => FeedCache());
