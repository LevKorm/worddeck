import 'package:supabase_flutter/supabase_flutter.dart';

import '../../contracts/i_feed_repository.dart';
import '../../core/errors/app_exception.dart';
import '../../models/feed_post.dart';

/// Supabase implementation of [IFeedRepository].
///
/// Table: public.card_feed_content
/// RLS: SELECT/UPDATE filtered to auth.uid() = user_id.
///      INSERT allowed to service role only (triggered from edge function).
class SupabaseFeedRepository implements IFeedRepository {
  final SupabaseClient _supabase;
  static const _table = 'card_feed_content';

  const SupabaseFeedRepository(this._supabase);

  // ── getFeedPosts ──────────────────────────────────────────────────────────

  @override
  Future<List<FeedPost>> getFeedPosts(
    String userId, {
    int limit = 20,
    int offset = 0,
    String? spaceId,
  }) async {
    try {
      var query = _supabase
          .from(_table)
          .select()
          .eq('user_id', userId)
          .eq('status', 'ready');
      if (spaceId != null) {
        query = query.eq('space_id', spaceId);
      }
      final data = await query
          .order('generated_at', ascending: false)
          .range(offset, offset + limit - 1);
      return (data as List)
          .map((e) => FeedPost.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch feed posts', cause: e);
    }
  }

  // ── getLikedPosts ─────────────────────────────────────────────────────────

  @override
  Future<List<FeedPost>> getLikedPosts(String userId) async {
    try {
      final data = await _supabase
          .from(_table)
          .select()
          .eq('user_id', userId)
          .eq('status', 'ready')
          .eq('liked', true)
          .order('generated_at', ascending: false);
      return (data as List)
          .map((e) => FeedPost.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch liked posts', cause: e);
    }
  }

  // ── toggleLike ────────────────────────────────────────────────────────────

  @override
  Future<void> toggleLike(String userId, String postId, bool liked) async {
    try {
      await _supabase
          .from(_table)
          .update({'liked': liked})
          .eq('id', postId)
          .eq('user_id', userId);
    } catch (e) {
      throw DatabaseException('Failed to toggle like', cause: e);
    }
  }

  // ── saveSuggestedToDeck ───────────────────────────────────────────────────
  /// Reads the suggested post, inserts a card into `cards`, then triggers
  /// feed generation for the new card.

  @override
  Future<void> saveSuggestedToDeck(String userId, String postId, {String? spaceId}) async {
    try {
      // 1. Read the feed post
      final postData = await _supabase
          .from(_table)
          .select('word, translation, ipa, slides')
          .eq('id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (postData == null) {
        throw const DatabaseException('Feed post not found');
      }

      final word        = postData['word'] as String?;
      final translation = postData['translation'] as String?;
      final ipa         = postData['ipa'] as String?;

      if (word == null || word.isEmpty) {
        throw const DatabaseException('Feed post has no word to save');
      }

      // 2. Insert into cards table (mirrors card_repository.saveCard pattern)
      final cardData = await _supabase
          .from('cards')
          .insert({
            'user_id':     userId,
            'word':        word,
            'translation': translation,
            'transcription': ipa,
            'status':      'learning',
            'next_review': DateTime.now().toIso8601String(),
            if (spaceId != null) 'space_id': spaceId,
          })
          .select()
          .single();

      final newCardId = cardData['id'] as String;

      // 3. Trigger feed generation for the new card (fire-and-forget)
      triggerFeedGeneration(userId, newCardId, spaceId: spaceId);
    } catch (e) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException('Failed to save suggested post to deck', cause: e);
    }
  }

  // ── triggerFeedGeneration ─────────────────────────────────────────────────
  /// Fires a POST to the generate-feed edge function. Fire-and-forget —
  /// the caller does not await the result.

  @override
  Future<void> triggerFeedGeneration(
    String userId,
    String cardId, {
    String? targetLang,
    String? nativeLang,
    String? spaceId,
  }) async {
    try {
      final cardData = await _supabase
          .from('cards')
          .select('word, translation, transcription')
          .eq('id', cardId)
          .eq('user_id', userId)
          .maybeSingle();

      if (cardData == null) return; // card not found, skip feed generation

      final session = _supabase.auth.currentSession;
      _supabase.functions
          .invoke(
            'generate-feed',
            body: {
              'card_id':     cardId,
              'word':        cardData['word'],
              'translation': cardData['translation'],
              'ipa':         cardData['transcription'],
              if (targetLang != null) 'target_lang': targetLang,
              if (nativeLang != null) 'native_lang': nativeLang,
              if (spaceId != null) 'space_id': spaceId,
            },
            headers: {
              if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
            },
          )
          .ignore();
    } catch (_) {}
  }

  // ── backfillFeedPosts ─────────────────────────────────────────────────────
  /// Finds cards that have no feed post yet and triggers generate-feed for
  /// each one (up to [limit] most recent). Fire-and-forget.

  @override
  Future<void> backfillFeedPosts(
    String userId,
    String nativeLang,
    String learningLang, {
    int limit = 10,
    String? spaceId,
  }) async {
    try {
      // Cards the user has
      var cardsQuery = _supabase
          .from('cards')
          .select('id, word, translation, transcription')
          .eq('user_id', userId);
      if (spaceId != null) {
        cardsQuery = cardsQuery.eq('space_id', spaceId);
      }
      final cards = await cardsQuery
          .order('created_at', ascending: false)
          .limit(limit);

      // card_ids that already have a successful feed post (ignore failed rows)
      final existing = await _supabase
          .from(_table)
          .select('card_id')
          .eq('user_id', userId)
          .eq('status', 'ready')
          .not('card_id', 'is', null);

      final existingIds = (existing as List)
          .map((e) => e['card_id'] as String?)
          .whereType<String>()
          .toSet();

      // Collect cards that have no successful post yet
      final uncovered = (cards as List).where((card) {
        final id = card['id'] as String?;
        return id != null && !existingIds.contains(id);
      }).toList();

      // Process in batches of 3 — avoids unbounded concurrent edge function calls
      final session = _supabase.auth.currentSession;
      const batchSize = 3;
      for (var i = 0; i < uncovered.length; i += batchSize) {
        final chunk = uncovered.sublist(
            i, (i + batchSize).clamp(0, uncovered.length));
        for (final card in chunk) {
          _supabase.functions
              .invoke(
                'generate-feed',
                body: {
                  'card_id':     card['id'],
                  'word':        card['word'],
                  'translation': card['translation'],
                  'ipa':         card['transcription'],
                  'target_lang': learningLang,
                  'native_lang': nativeLang,
                  if (spaceId != null) 'space_id': spaceId,
                },
                headers: {
                  if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
                },
              )
              .ignore();
        }
        if (i + batchSize < uncovered.length) {
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      }
    } catch (_) {}
  }

  // ── triggerSuggestionGeneration ───────────────────────────────────────────

  @override
  Future<void> triggerSuggestionGeneration(
    String userId,
    String nativeLang,
    String learningLang,
    List<String> existingWords,
    int cardCount,
  ) async {
    try {
      final session = _supabase.auth.currentSession;
      _supabase.functions
          .invoke(
            'generate-suggestions',
            body: {
              'user_id':        userId,
              'native_lang':    nativeLang,
              'learning_lang':  learningLang,
              'existing_words': existingWords,
              'card_count':     cardCount,
            },
            headers: {
              if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
            },
          )
          .ignore();
    } catch (_) {
      // Fire-and-forget: swallow errors silently
    }
  }

  // ── deleteFailedFeedRows ──────────────────────────────────────────────────

  @override
  Future<void> deleteFailedFeedRows(String userId) async {
    try {
      await _supabase
          .from(_table)
          .delete()
          .eq('user_id', userId)
          .eq('status', 'failed');
    } catch (_) {}
  }

  // ── getUserCardCount ──────────────────────────────────────────────────────

  @override
  Future<int> getUserCardCount(String userId) async {
    try {
      final response = await _supabase
          .from('cards')
          .select('id')
          .eq('user_id', userId)
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      throw DatabaseException('Failed to count user cards', cause: e);
    }
  }
}
