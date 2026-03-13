import 'package:flutter/material.dart';
import '../../core/theme/feed_slide_gradients.dart';
import 'feed_slide_frame.dart';
import 'feed_theme.dart';

class CompareHeroSlide extends StatelessWidget {
  final Map<String, dynamic> content;
  final Map<String, dynamic>? extra;
  final bool showNative;
  final bool reelsMode;

  const CompareHeroSlide({
    super.key,
    required this.content,
    this.extra,
    required this.showNative,
    this.reelsMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final badge    = extra?['badge']     as String? ?? 'Compare';
    final title    = content['title']    as String? ?? '';
    final subtitle = content['subtitle'] as String? ?? '';

    return FeedSlideFrame(
      gradient: FeedSlideGradients.hero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 16,
            left: 16,
            child: Text(badge.toUpperCase(), style: FeedTheme.typeLabelStyle),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 52, 28, 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: FeedTheme.textPrimary,
                    height: 1.15,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 15,
                      color: FeedTheme.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 3,
                      decoration: BoxDecoration(
                        color: FeedTheme.suggest,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Swipe to explore',
                      style: TextStyle(
                        fontSize: 12,
                        color: FeedTheme.textSecondary,
                      ),
                    ),
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
