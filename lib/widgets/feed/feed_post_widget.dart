import 'package:flutter/material.dart';

import '../../models/feed_post.dart';
import 'feed_carousel.dart';

/// Card-shaped feed list item with a subtle border and rounded corners.
class FeedPostWidget extends StatelessWidget {
  final FeedPost post;
  final bool liked;
  final String learningLang;
  final String nativeLang;
  final VoidCallback onLike;
  final VoidCallback onOpenReels;
  final VoidCallback? onSave;
  final bool showNative;

  const FeedPostWidget({
    super.key,
    required this.post,
    required this.liked,
    required this.onLike,
    required this.onOpenReels,
    this.onSave,
    this.learningLang = 'EN',
    this.nativeLang   = 'UK',
    this.showNative   = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GestureDetector(
          onTap: onOpenReels,
          behavior: HitTestBehavior.translucent,
          child: FeedCarousel(
            post:         post,
            liked:        liked,
            reelsMode:    false,
            onLike:       onLike,
            onOpenReels:  onOpenReels,
            onSave:       onSave,
            learningLang: learningLang,
            nativeLang:   nativeLang,
            showNative:   showNative,
          ),
        ),
      ),
    );
  }
}
