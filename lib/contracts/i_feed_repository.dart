import '../models/feed_post.dart';

abstract class IFeedRepository {
  /// Returns a paginated list of feed posts for [userId].
  Future<List<FeedPost>> getFeedPosts(
    String userId, {
    int limit = 20,
    int offset = 0,
    String? spaceId,
  });

  /// Returns all posts the user has liked.
  Future<List<FeedPost>> getLikedPosts(String userId);

  /// Toggles the liked state of [postId] for [userId].
  Future<void> toggleLike(String userId, String postId, bool liked);

  /// Saves a suggested post's word to the user's deck and marks it as saved.
  Future<void> saveSuggestedToDeck(String userId, String postId, {String? spaceId});

  /// Triggers async feed generation for a newly saved card.
  /// [targetLang] and [nativeLang] are optional; the edge function falls back
  /// to the user's settings in the DB if they are not provided.
  Future<void> triggerFeedGeneration(
    String userId,
    String cardId, {
    String? targetLang,
    String? nativeLang,
    String? spaceId,
  });

  /// Triggers async generation of system-suggested posts for [userId].
  Future<void> triggerSuggestionGeneration(
    String userId,
    String nativeLang,
    String learningLang,
    List<String> existingWords,
    int cardCount,
  );

  /// Triggers feed generation for any existing cards that have no post yet.
  /// Fire-and-forget — backfills up to [limit] most-recent cards.
  Future<void> backfillFeedPosts(
    String userId,
    String nativeLang,
    String learningLang, {
    int limit = 10,
    String? spaceId,
  });

  /// Deletes any feed rows with status 'failed' for the given user.
  /// Self-healing cleanup — call fire-and-forget during loadFeed.
  Future<void> deleteFailedFeedRows(String userId);

  /// Returns the total number of cards in the user's deck.
  Future<int> getUserCardCount(String userId);
}
