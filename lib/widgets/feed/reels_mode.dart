import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/feed_post.dart';
import 'feed_carousel.dart';

/// Full-screen reels overlay.  Navigate between posts with vertical swipe
/// or the Prev / Next buttons above and below the card.
///
/// Usage:
/// ```dart
/// ReelsMode.show(context, posts: posts, initialIndex: i, ...);
/// ```
class ReelsMode extends StatefulWidget {
  final List<FeedPost> posts;
  final int initialIndex;
  final String learningLang;
  final String nativeLang;
  final void Function(String postId) onLike;
  final void Function(String postId)? onSave;

  const ReelsMode({
    super.key,
    required this.posts,
    required this.initialIndex,
    required this.onLike,
    this.onSave,
    this.learningLang = 'EN',
    this.nativeLang   = 'UK',
  });

  static Future<void> show(
    BuildContext context, {
    required List<FeedPost> posts,
    required int initialIndex,
    required void Function(String postId) onLike,
    void Function(String postId)? onSave,
    String learningLang = 'EN',
    String nativeLang   = 'UK',
  }) {
    return Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder(
        opaque: true,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => ReelsMode(
          posts:        posts,
          initialIndex: initialIndex,
          onLike:       onLike,
          onSave:       onSave,
          learningLang: learningLang,
          nativeLang:   nativeLang,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  State<ReelsMode> createState() => _ReelsModeState();
}

class _ReelsModeState extends State<ReelsMode> {
  late PageController _pageCtrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex.clamp(0, widget.posts.length - 1);
    _pageCtrl = PageController(initialPage: _current);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Vertical PageView — smooth Instagram-style scroll ──────────
          PageView.builder(
            controller: _pageCtrl,
            scrollDirection: Axis.vertical,
            onPageChanged: (i) => setState(() => _current = i),
            itemCount: widget.posts.length,
            itemBuilder: (ctx, i) {
              final post = widget.posts[i];
              return FeedCarousel(
                key: ValueKey(post.id),
                post:         post,
                liked:        post.liked,
                reelsMode:    true,
                onLike:       () => widget.onLike(post.id),
                onOpenReels:  null,
                onSave:       widget.onSave != null
                    ? () => widget.onSave!(post.id)
                    : null,
                learningLang: widget.learningLang,
                nativeLang:   widget.nativeLang,
              );
            },
          ),

          // ── Floating close button ──────────────────────────────────────
          Positioned(
            top: safePadding.top + 12,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context, rootNavigator: true).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(110),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
