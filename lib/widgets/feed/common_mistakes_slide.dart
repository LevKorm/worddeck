import 'package:flutter/material.dart';
import '../../core/theme/feed_slide_gradients.dart';
import 'feed_slide_frame.dart';
import 'feed_theme.dart';

class CommonMistakesSlide extends StatelessWidget {
  final Map<String, dynamic> content;
  final Map<String, dynamic>? extra;
  final bool showNative;
  final bool reelsMode;

  const CommonMistakesSlide({
    super.key,
    required this.content,
    this.extra,
    required this.showNative,
    this.reelsMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final title    = content['title']    as String? ?? 'Common Mistakes';
    final rawList  = content['mistakes'] as List<dynamic>? ??
        extra?['mistakes'] as List<dynamic>? ??
        [];
    final mistakes = rawList
        .map((e) => (e as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{})
        .toList();

    return FeedSlideFrame(
      gradient: FeedSlideGradients.commonMistakes,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: 16,
            left: 16,
            child: Text('COMMON MISTAKES', style: FeedTheme.typeLabelStyle),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: FeedTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                ...mistakes.map((m) {
                  final wrong       = m['wrong']       as String? ?? '';
                  final right       = m['right']       as String? ?? '';
                  final explanation = m['explanation'] as String? ?? '';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '✗  $wrong',
                          style: const TextStyle(
                            fontSize: 14,
                            color: FeedTheme.error,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: FeedTheme.error,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '✓  $right',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: FeedTheme.success,
                          ),
                        ),
                        if (explanation.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            explanation,
                            style: const TextStyle(
                              fontSize: 12,
                              color: FeedTheme.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
