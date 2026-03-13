import '../../models/feed_post.dart';

/// Interleaves user-owned posts with system-suggested posts.
///
/// Suggested density scales down as the user builds their deck:
///   0–3 cards  → 1 suggested per 1 user post  (~70% suggested)
///   4–10 cards → 1 suggested per 3 user posts  (~25% suggested)
///   11+ cards  → 1 suggested per 5 user posts  (~17% suggested)
class FeedMixer {
  FeedMixer._();

  /// Returns an interleaved list of [userPosts] and [suggestedPosts] based on
  /// how many cards the user currently has in their deck ([userCardCount]).
  ///
  /// Any leftover suggested posts are appended after all user posts have been
  /// placed (important when the user has very few posts of their own).
  static List<FeedPost> mixFeed(
    List<FeedPost> userPosts,
    List<FeedPost> suggestedPosts,
    int userCardCount,
  ) {
    // Determine interleave ratio
    final int ratio;
    if (userCardCount <= 3) {
      ratio = 1; // 1 suggested after every 1 user post
    } else if (userCardCount <= 10) {
      ratio = 3; // 1 suggested after every 3 user posts
    } else {
      ratio = 5; // 1 suggested after every 5 user posts
    }

    final result    = <FeedPost>[];
    int userIdx      = 0;
    int suggestedIdx = 0;

    while (userIdx < userPosts.length) {
      // Add `ratio` user posts
      final end = (userIdx + ratio).clamp(0, userPosts.length);
      result.addAll(userPosts.sublist(userIdx, end));
      userIdx = end;

      // Add 1 suggested post (if available)
      if (suggestedIdx < suggestedPosts.length) {
        result.add(suggestedPosts[suggestedIdx]);
        suggestedIdx++;
      }
    }

    // Append any remaining suggested posts
    if (suggestedIdx < suggestedPosts.length) {
      result.addAll(suggestedPosts.sublist(suggestedIdx));
    }

    return result;
  }
}
