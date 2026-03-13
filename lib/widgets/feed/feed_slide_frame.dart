import 'package:flutter/material.dart';

/// Full-bleed gradient container used by every slide type.
///
/// Sizing is handled by the parent ([FeedCarousel] uses AspectRatio 4/5 in
/// feed mode and SizedBox.expand in reels mode).  The child is responsible
/// for its own layout inside the gradient box.
class FeedSlideFrame extends StatelessWidget {
  final Widget child;
  final Gradient gradient;

  const FeedSlideFrame({
    super.key,
    required this.child,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: child,
    );
  }
}
