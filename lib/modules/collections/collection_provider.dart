import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../contracts/i_collection_repository.dart';
import '../../core/cache/collection_cache.dart';
import '../../core/errors/failure.dart';
import '../../models/collection.dart';
import '../../modules/auth/auth_provider.dart';
import '../../modules/cards/card_provider.dart';
import 'collection_repository.dart';

// ── Repository provider ───────────────────────────────────────────────────────

final collectionRepositoryProvider = Provider<ICollectionRepository>(
  (ref) => SupabaseCollectionRepository(ref.read(supabaseClientProvider)),
);

// ── State ─────────────────────────────────────────────────────────────────────

class CollectionState {
  final List<Collection> collections;
  final bool isLoading;
  final Failure? failure;

  const CollectionState({
    this.collections = const [],
    this.isLoading = false,
    this.failure,
  });

  CollectionState copyWith({
    List<Collection>? collections,
    bool? isLoading,
    Failure? failure,
    bool? clearFailure,
  }) =>
      CollectionState(
        collections: collections ?? this.collections,
        isLoading: isLoading ?? this.isLoading,
        failure: clearFailure == true ? null : failure ?? this.failure,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class CollectionNotifier extends StateNotifier<CollectionState> {
  final ICollectionRepository _repo;
  final CollectionCache _cache;

  CollectionNotifier(this._repo, this._cache)
      : super(const CollectionState());

  Future<void> loadCollections(String userId) async {
    // 1. Emit cache immediately
    final cached = await _cache.load(userId);
    if (cached.isNotEmpty) {
      state = state.copyWith(collections: cached, isLoading: false);
    } else {
      state = state.copyWith(isLoading: true);
    }

    // 2. Fetch fresh from Supabase
    try {
      final fresh = await _repo.getCollections(userId);
      state = state.copyWith(collections: fresh, isLoading: false);
      _cache.save(userId, fresh); // fire-and-forget
    } on Exception catch (e) {
      if (cached.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          failure: DatabaseFailure(e.toString()),
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<Collection?> create({
    required String userId,
    required String name,
    String emoji = '📚',
    String? color,
    String? description,
  }) async {
    final optimistic = Collection(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      name: name,
      emoji: emoji,
      color: color,
      description: description,
      position: state.collections.length,
      createdAt: DateTime.now(),
    );

    // Optimistic add
    state = state.copyWith(
        collections: [...state.collections, optimistic]);

    try {
      final saved = await _repo.createCollection(optimistic);
      // Replace optimistic entry with real one
      final updated = state.collections
          .map((c) => c.id == optimistic.id ? saved : c)
          .toList();
      state = state.copyWith(collections: updated);
      _cache.upsert(userId, saved);
      return saved;
    } on Exception catch (e) {
      // Rollback
      state = state.copyWith(
        collections:
            state.collections.where((c) => c.id != optimistic.id).toList(),
        failure: DatabaseFailure(e.toString()),
      );
      return null;
    }
  }

  Future<void> update(Collection collection) async {
    // Optimistic update
    _replaceInState(collection);
    _cache.upsert(collection.userId, collection);
    _repo.updateCollection(collection).then<void>((_) {}, onError: (_) {});
  }

  Future<void> delete(String collectionId) async {
    final toDelete =
        state.collections.where((c) => c.id == collectionId).firstOrNull;
    if (toDelete == null) return; // already deleted
    // Optimistic remove
    state = state.copyWith(
      collections: state.collections.where((c) => c.id != collectionId).toList(),
    );
    _cache.remove(toDelete.userId, collectionId);
    _repo.deleteCollection(collectionId).then<void>((_) {}, onError: (_) {});
  }

  Future<void> pin(String collectionId) async {
    // Optimistic: unpin all, pin target
    final updated = state.collections.map((c) {
      if (c.id == collectionId) return c.copyWith(isPinned: true);
      return c.isPinned ? c.copyWith(isPinned: false) : c;
    }).toList();
    state = state.copyWith(collections: updated);

    final target = updated.where((c) => c.id == collectionId).firstOrNull;
    if (target != null) _cache.upsert(target.userId, target);

    _repo.pinCollection(collectionId).then<void>((_) {}, onError: (_) {});
  }

  Future<void> unpin(String collectionId) async {
    final updated = state.collections.map((c) {
      return c.id == collectionId ? c.copyWith(isPinned: false) : c;
    }).toList();
    state = state.copyWith(collections: updated);

    final target = updated.where((c) => c.id == collectionId).firstOrNull;
    if (target != null) _cache.upsert(target.userId, target);

    _repo.unpinCollection(collectionId).then<void>((_) {}, onError: (_) {});
  }

  void _replaceInState(Collection collection) {
    final idx = state.collections.indexWhere((c) => c.id == collection.id);
    if (idx < 0) return;
    final updated = [...state.collections];
    updated[idx] = collection;
    state = state.copyWith(collections: updated);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final collectionProvider =
    StateNotifierProvider<CollectionNotifier, CollectionState>(
  (ref) => CollectionNotifier(
    ref.read(collectionRepositoryProvider),
    ref.read(collectionCacheProvider),
  ),
);

// ── Derived providers ─────────────────────────────────────────────────────────

/// Currently pinned collection, if any.
final pinnedCollectionProvider = Provider<Collection?>((ref) {
  return ref
      .watch(collectionProvider)
      .collections
      .where((c) => c.isPinned)
      .firstOrNull;
});

/// Look up a collection by ID.
final collectionByIdProvider =
    Provider.family<Collection?, String?>((ref, id) {
  if (id == null) return null;
  return ref
      .watch(collectionProvider)
      .collections
      .where((c) => c.id == id)
      .firstOrNull;
});

/// Card count per collection (null = all cards).
final collectionCardCountProvider =
    Provider.family<int, String?>((ref, collectionId) {
  final cards = ref.watch(cardListProvider).allCards;
  if (collectionId == null) return cards.length;
  return cards.where((c) => c.collectionId == collectionId).length;
});
