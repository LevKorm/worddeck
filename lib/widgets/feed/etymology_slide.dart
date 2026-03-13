import 'package:flutter/material.dart';
import '../../core/theme/feed_slide_gradients.dart';
import 'feed_slide_frame.dart';
import 'feed_theme.dart';

class EtymologySlide extends StatelessWidget {
  final Map<String, dynamic> content;
  final Map<String, dynamic>? extra;
  final bool showNative;
  final bool reelsMode;

  const EtymologySlide({
    super.key,
    required this.content,
    this.extra,
    required this.showNative,
    this.reelsMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final origin   = content['origin'] as String? ?? '';
    final story    = content['story']  as String? ?? '';
    final era      = extra?['era']     as String? ?? '';
    final rootLang = extra?['rootLang'] as String? ?? '';

    return FeedSlideFrame(
      gradient: FeedSlideGradients.etymology,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: 16,
            left: 16,
            child: Text('ETYMOLOGY', style: FeedTheme.typeLabelStyle),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📜', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 14),
                if (origin.isNotEmpty) ...[
                  Text(
                    origin,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: FeedTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (story.isNotEmpty)
                  Text(
                    story,
                    style: const TextStyle(
                      fontSize: 14,
                      color: FeedTheme.textSecondary,
                      height: 1.65,
                    ),
                  ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (era.isNotEmpty)
                      FeedTag(label: era, color: FeedTheme.warning),
                    if (rootLang.isNotEmpty)
                      FeedTag(label: rootLang, color: FeedTheme.info),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
