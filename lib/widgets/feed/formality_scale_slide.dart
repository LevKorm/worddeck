import 'package:flutter/material.dart';
import '../../core/theme/feed_slide_gradients.dart';
import 'feed_slide_frame.dart';
import 'feed_theme.dart';

class FormalityScaleSlide extends StatelessWidget {
  final Map<String, dynamic> content;
  final Map<String, dynamic>? extra;
  final bool showNative;
  final bool reelsMode;

  const FormalityScaleSlide({
    super.key,
    required this.content,
    this.extra,
    required this.showNative,
    this.reelsMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final title    = content['title'] as String? ?? 'Formality Scale';
    final rawItems = extra?['items']    as List<dynamic>? ??
        content['items'] as List<dynamic>? ??
        [];
    final items = rawItems
        .map((e) => (e as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{})
        .toList();

    final scaleColors = [
      FeedTheme.success,
      FeedTheme.info,
      FeedTheme.accent,
      FeedTheme.purple,
    ];

    return FeedSlideFrame(
      gradient: FeedSlideGradients.formalityScale,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: 16,
            left: 16,
            child: Text('FORMALITY', style: FeedTheme.typeLabelStyle),
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
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('casual',
                        style: TextStyle(
                            fontSize: 11, color: FeedTheme.textSecondary)),
                    Text('formal',
                        style: TextStyle(
                            fontSize: 11, color: FeedTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 12),
                ...items.asMap().entries.map((entry) {
                  final i     = entry.key;
                  final item  = entry.value;
                  final word  = item['word']  as String? ?? '';
                  final label = item['label'] as String? ?? '';
                  final color = scaleColors[i.clamp(0, scaleColors.length - 1)];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 4,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  word,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                                if (label.isNotEmpty)
                                  Text(
                                    label,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: FeedTheme.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
