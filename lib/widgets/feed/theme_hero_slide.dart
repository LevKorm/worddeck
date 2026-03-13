import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/feed_slide_gradients.dart';
import 'feed_slide_frame.dart';
import 'feed_theme.dart';

class ThemeHeroSlide extends StatelessWidget {
  final Map<String, dynamic> content;
  final Map<String, dynamic>? extra;
  final bool showNative;
  final bool reelsMode;

  const ThemeHeroSlide({
    super.key,
    required this.content,
    this.extra,
    required this.showNative,
    this.reelsMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final emoji       = content['emoji']       as String? ?? '🎯';
    final title       = content['title']       as String? ?? '';
    final description = content['description'] as String? ?? '';
    final rawWords    = extra?['words']         as List<dynamic>? ?? [];
    final words       = rawWords.whereType<String>().toList();

    return FeedSlideFrame(
      gradient: FeedSlideGradients.suggestion,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: 16,
            left: 16,
            child: Text('THEME', style: FeedTheme.typeLabelStyle),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: AppTheme.emojiStyle.copyWith(fontSize: 52)),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: FeedTheme.textPrimary,
                    height: 1.2,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: FeedTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
                if (words.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: words
                        .map((w) => FeedTag(label: w, color: FeedTheme.suggest))
                        .toList(),
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
