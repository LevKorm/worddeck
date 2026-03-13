import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../contracts/i_feed_repository.dart';
import '../../core/cache/feed_cache.dart';
import '../../core/errors/failure.dart';
import '../../models/feed_post.dart';
import '../auth/auth_provider.dart';
import 'feed_mixer.dart';
import 'feed_repository.dart';

// ── Repository provider ───────────────────────────────────────────────────────

final feedRepositoryProvider = Provider<IFeedRepository>(
  (ref) => SupabaseFeedRepository(ref.read(supabaseClientProvider)),
);

// ── Feed filter ───────────────────────────────────────────────────────────────

enum FeedFilter { random, latest, liked }

// ── Feed state ────────────────────────────────────────────────────────────────

class FeedState {
  final List<FeedPost> posts;
  final bool isLoading;
  final FeedFilter filter;
  final Set<String> likedIds;
  final Failure? failure;

  const FeedState({
    this.posts     = const [],
    this.isLoading = false,
    this.filter    = FeedFilter.random,
    this.likedIds  = const {},
    this.failure,
  });

  FeedState copyWith({
    List<FeedPost>? posts,
    bool? isLoading,
    FeedFilter? filter,
    Set<String>? likedIds,
    Failure? failure,
    bool clearFailure = false,
  }) =>
      FeedState(
        posts:     posts     ?? this.posts,
        isLoading: isLoading ?? this.isLoading,
        filter:    filter    ?? this.filter,
        likedIds:  likedIds  ?? this.likedIds,
        failure:   clearFailure ? null : failure ?? this.failure,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class FeedNotifier extends StateNotifier<FeedState> {
  final IFeedRepository _repo;
  final FeedCache _cache;

  FeedNotifier(this._repo, this._cache) : super(const FeedState());

  // ── Load ─────────────────────────────────────────────────────────────────

  Future<void> loadFeed(
    String userId, {
    String learningLang = 'EN',
    String nativeLang   = 'UK',
    int? cardCount,
    String? spaceId,
  }) async {
    // 1. Emit cached user posts immediately — no spinner for returning users
    final cached = await _cache.load(userId, spaceId: spaceId);
    if (cached.isNotEmpty) {
      state = state.copyWith(
          posts: _applyFilter(cached, state.filter), clearFailure: true);
    } else {
      state = state.copyWith(isLoading: true, clearFailure: true);
    }

    // Silently clean up any lingering failed rows from before the fix
    _repo.deleteFailedFeedRows(userId).then<void>((_) {}, onError: (_) {});

    try {
      final allPosts = await _repo.getFeedPosts(userId, spaceId: spaceId);

      // Split into user-owned vs system-suggested
      final userPosts      = allPosts.where((p) => !p.suggested).toList();
      final suggestedPosts = allPosts.where((p) => p.suggested).toList();

      // Use the caller-supplied count when available — avoids a redundant DB call
      final count = cardCount ?? await _repo.getUserCardCount(userId);

      // Interleave using FeedMixer
      final mixed = FeedMixer.mixFeed(userPosts, suggestedPosts, count);

      final likedIds = allPosts
          .where((p) => p.liked)
          .map((p) => p.id)
          .toSet();

      final ordered = _applyFilter(mixed, state.filter);
      state = state.copyWith(
        posts:     ordered,
        likedIds:  likedIds,
        isLoading: false,
      );

      // Update cache with user's own posts only (never cache suggested posts)
      _cache.save(userId, userPosts, spaceId: spaceId); // fire-and-forget

      // Backfill: existing cards with no feed post yet
      if (userPosts.isEmpty && count > 0) {
        _repo
            .backfillFeedPosts(userId, nativeLang, learningLang, spaceId: spaceId)
            .then<void>((_) {}, onError: (_) {});
      }

      // Trigger suggestion generation when the pool is thin
      if (suggestedPosts.length < 3) {
        final existingWords = userPosts
            .map((p) => p.word ?? '')
            .where((w) => w.isNotEmpty)
            .toList();
        _repo
            .triggerSuggestionGeneration(
              userId,
              nativeLang,
              learningLang,
              existingWords,
              count,
            )
            .then<void>((_) {}, onError: (_) {});
      }
    } catch (e) {
      // Keep showing cached data if available; only surface error on empty state
      if (cached.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          failure:   DatabaseFailure(e.toString()),
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  // ── Filter ────────────────────────────────────────────────────────────────

  void setFilter(FeedFilter filter) {
    final reordered = _applyFilter(state.posts, filter);
    state = state.copyWith(posts: reordered, filter: filter);
  }

  List<FeedPost> _applyFilter(List<FeedPost> posts, FeedFilter filter) {
    switch (filter) {
      case FeedFilter.random:
        final shuffled = [...posts]..shuffle(Random());
        return shuffled;
      case FeedFilter.latest:
        return [...posts]
          ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
      case FeedFilter.liked:
        return posts.where((p) => state.likedIds.contains(p.id)).toList();
    }
  }

  // ── Toggle like (optimistic) ──────────────────────────────────────────────

  void toggleLike(String userId, String postId) {
    final isLiked    = state.likedIds.contains(postId);
    final nowLiked   = !isLiked;
    final newLikedIds = Set<String>.from(state.likedIds);

    if (nowLiked) {
      newLikedIds.add(postId);
    } else {
      newLikedIds.remove(postId);
    }

    // Patch in-memory post
    final updatedPosts = state.posts
        .map((p) => p.id == postId ? p.copyWith(liked: nowLiked) : p)
        .toList();

    state = state.copyWith(posts: updatedPosts, likedIds: newLikedIds);

    // Fire-and-forget persist
    _repo.toggleLike(userId, postId, nowLiked).then<void>((_) {},
        onError: (_) {
      // Roll back on failure
      final rolled = state.posts
          .map((p) => p.id == postId ? p.copyWith(liked: isLiked) : p)
          .toList();
      final rolledIds = Set<String>.from(state.likedIds);
      if (isLiked) {
        rolledIds.add(postId);
      } else {
        rolledIds.remove(postId);
      }
      state = state.copyWith(posts: rolled, likedIds: rolledIds);
    });
  }

  // ── Save suggested ────────────────────────────────────────────────────────

  Future<void> saveSuggested(String userId, String postId, {String? spaceId}) async {
    try {
      await _repo.saveSuggestedToDeck(userId, postId, spaceId: spaceId);
    } catch (e) {
      state = state.copyWith(failure: DatabaseFailure(e.toString()));
    }
  }

  // ── Shuffle ───────────────────────────────────────────────────────────────

  void shuffleFeed() {
    final shuffled = [...state.posts]..shuffle(Random());
    state = state.copyWith(posts: shuffled);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>(
  (ref) => FeedNotifier(
    ref.read(feedRepositoryProvider),
    ref.read(feedCacheProvider),
  ),
);

// ── User card count ───────────────────────────────────────────────────────────

final userCardCountProvider = FutureProvider<int>((ref) async {
  final userId = ref.watch(currentUserProvider)?.userId;
  if (userId == null) return 0;
  return ref.read(feedRepositoryProvider).getUserCardCount(userId);
});
