import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../contracts/i_space_repository.dart';
import '../../core/cache/space_cache.dart';
import '../../core/errors/failure.dart';
import '../../models/space.dart';
import '../../modules/auth/auth_provider.dart';
import '../../modules/cards/card_provider.dart';
import '../../modules/feed/feed_provider.dart';
import 'space_repository.dart';

// ── Repository provider ───────────────────────────────────────────────────────

final spaceRepositoryProvider = Provider<ISpaceRepository>(
  (ref) => SupabaseSpaceRepository(ref.read(supabaseClientProvider)),
);

// ── State ─────────────────────────────────────────────────────────────────────

class SpaceState {
  final List<Space> spaces;
  final String? activeSpaceId;
  final bool isLoading;
  final Failure? failure;

  const SpaceState({
    this.spaces = const [],
    this.activeSpaceId,
    this.isLoading = false,
    this.failure,
  });

  Space? get activeSpace =>
      spaces.where((s) => s.id == activeSpaceId).firstOrNull;

  SpaceState copyWith({
    List<Space>? spaces,
    String? activeSpaceId,
    bool? clearActiveSpaceId,
    bool? isLoading,
    Failure? failure,
    bool? clearFailure,
  }) =>
      SpaceState(
        spaces: spaces ?? this.spaces,
        activeSpaceId: clearActiveSpaceId == true
            ? null
            : activeSpaceId ?? this.activeSpaceId,
        isLoading: isLoading ?? this.isLoading,
        failure: clearFailure == true ? null : failure ?? this.failure,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class SpaceNotifier extends StateNotifier<SpaceState> {
  final ISpaceRepository _repo;
  final SpaceCache _cache;
  final Ref _ref;

  SpaceNotifier(this._repo, this._cache, this._ref)
      : super(const SpaceState());

  Future<void> loadSpaces(String userId) async {
    // 1. Emit cached spaces immediately
    final cached = await _cache.load(userId);
    if (cached.isNotEmpty) {
      final activeId = cached.first.id;
      state = state.copyWith(
        spaces: cached,
        activeSpaceId: state.activeSpaceId ?? activeId,
        isLoading: false,
      );
      // Trigger card/feed load for cached active space
      _loadScopedData(userId, state.activeSpaceId ?? activeId);
    } else {
      state = state.copyWith(isLoading: true);
    }

    // 2. Fetch fresh from Supabase
    try {
      final fresh = await _repo.getSpaces(userId);

      if (fresh.isEmpty) {
        // No spaces yet — auto-create default from user profile
        await _ensureDefaultSpace(userId);
        return;
      }

      // Resolve active space from persisted setting or fall back to first
      final persistedActiveId = await _repo.getActiveSpaceId(userId);
      final activeId = (persistedActiveId != null &&
              fresh.any((s) => s.id == persistedActiveId))
          ? persistedActiveId
          : fresh.first.id;

      state = state.copyWith(
        spaces: fresh,
        activeSpaceId: activeId,
        isLoading: false,
      );
      _cache.save(userId, fresh);
      _loadScopedData(userId, activeId);
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

  Future<void> _ensureDefaultSpace(String userId) async {
    final user = _ref.read(currentUserProvider);
    final nativeLang = user?.nativeLanguage ?? 'UK';
    final learningLang = user?.learningLanguage ?? 'EN';

    try {
      final optimistic = Space(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        nativeLanguage: nativeLang,
        learningLanguage: learningLang,
        displayOrder: 0,
        createdAt: DateTime.now(),
      );

      final saved = await _repo.createSpace(optimistic);

      // Migrate any existing cards without a space_id
      await _repo.migrateCardsToSpace(userId, saved.id);

      // Persist active space
      _repo.setActiveSpace(userId, saved.id).then<void>((_) {}, onError: (_) {});

      state = state.copyWith(
        spaces: [saved],
        activeSpaceId: saved.id,
        isLoading: false,
      );
      _cache.save(userId, [saved]);
      _loadScopedData(userId, saved.id);
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        failure: DatabaseFailure(e.toString()),
      );
    }
  }

  Future<void> createSpace(
      String userId, String nativeLang, String learningLang) async {
    final optimistic = Space(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      nativeLanguage: nativeLang,
      learningLanguage: learningLang,
      displayOrder: state.spaces.length,
      createdAt: DateTime.now(),
    );

    // Optimistic add
    state = state.copyWith(spaces: [...state.spaces, optimistic]);

    try {
      final saved = await _repo.createSpace(optimistic);
      final updated =
          state.spaces.map((s) => s.id == optimistic.id ? saved : s).toList();
      state = state.copyWith(spaces: updated);
      _cache.upsert(userId, saved);

      // Switch to the new space
      await switchSpace(userId, saved.id);
    } on Exception catch (e) {
      // Rollback optimistic add
      state = state.copyWith(
        spaces: state.spaces.where((s) => s.id != optimistic.id).toList(),
        failure: DatabaseFailure(e.toString()),
      );
    }
  }

  Future<void> switchSpace(String userId, String spaceId) async {
    if (state.activeSpaceId == spaceId) return;

    state = state.copyWith(activeSpaceId: spaceId);

    // Persist selection (fire-and-forget)
    _repo.setActiveSpace(userId, spaceId).then<void>((_) {}, onError: (_) {});

    // Reload scoped data for the new space
    _loadScopedData(userId, spaceId);
  }

  Future<void> deleteSpace(String userId, String spaceId) async {
    final toDelete = state.spaces.where((s) => s.id == spaceId).firstOrNull;
    if (toDelete == null) return; // already deleted

    // Optimistic remove
    final remaining = state.spaces.where((s) => s.id != spaceId).toList();
    state = state.copyWith(spaces: remaining);
    _cache.remove(toDelete.userId, spaceId);

    // If deleting active space, switch to another
    if (state.activeSpaceId == spaceId) {
      final newActive = remaining.isNotEmpty ? remaining.first.id : null;
      if (newActive != null) {
        state = state.copyWith(activeSpaceId: newActive);
        _repo.setActiveSpace(userId, newActive).then<void>((_) {}, onError: (_) {});
        _loadScopedData(userId, newActive);
      } else {
        state = state.copyWith(clearActiveSpaceId: true);
      }
    }

    _repo.deleteSpace(spaceId).then<void>((_) {}, onError: (_) {});
  }

  void _loadScopedData(String userId, String spaceId) {
    final space = state.spaces.where((s) => s.id == spaceId).firstOrNull;
    ref.read(cardListProvider.notifier).loadCards(userId, spaceId: spaceId);
    ref.read(feedProvider.notifier).loadFeed(
          userId,
          spaceId: spaceId,
          learningLang: space?.learningLanguage ?? 'EN',
          nativeLang: space?.nativeLanguage ?? 'UK',
        );
  }

  // Expose ref for _loadScopedData
  Ref get ref => _ref;
}

// ── Provider ──────────────────────────────────────────────────────────────────

final spaceProvider = StateNotifierProvider<SpaceNotifier, SpaceState>(
  (ref) => SpaceNotifier(
    ref.read(spaceRepositoryProvider),
    ref.read(spaceCacheProvider),
    ref,
  ),
);

// ── Derived providers ─────────────────────────────────────────────────────────

/// Currently active space, if any.
final activeSpaceProvider = Provider<Space?>((ref) {
  return ref.watch(spaceProvider).activeSpace;
});

/// Look up a space by ID.
final spaceByIdProvider = Provider.family<Space?, String?>((ref, id) {
  if (id == null) return null;
  return ref
      .watch(spaceProvider)
      .spaces
      .where((s) => s.id == id)
      .firstOrNull;
});
