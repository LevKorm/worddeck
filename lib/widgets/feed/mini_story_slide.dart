import 'package:flutter/material.dart';
import '../../core/theme/feed_slide_gradients.dart';
import 'feed_slide_frame.dart';
import 'feed_theme.dart';

class MiniStorySlide extends StatelessWidget {
  final Map<String, dynamic> content;
  final Map<String, dynamic>? extra;
  final bool showNative;
  final bool reelsMode;

  const MiniStorySlide({
    super.key,
    required this.content,
    this.extra,
    required this.showNative,
    this.reelsMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final story    = content['story']    as String? ?? '';
    final takeaway = content['takeaway'] as String? ?? '';

    return FeedSlideFrame(
      gradient: FeedSlideGradients.miniStory,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: 16,
            left: 16,
            child: Text('MINI STORY', style: FeedTheme.typeLabelStyle),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 3,
                        decoration: BoxDecoration(
                          color: FeedTheme.purple,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          story,
                          style: const TextStyle(
                            fontSize: 15,
                            color: FeedTheme.textPrimary,
                            fontStyle: FontStyle.italic,
                            height: 1.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (takeaway.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: FeedTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: FeedTheme.borderDark),
                    ),
                    child: Row(
                      children: [
                        const Text('✨', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            takeaway,
                            style: const TextStyle(
                              fontSize: 13,
                              color: FeedTheme.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
