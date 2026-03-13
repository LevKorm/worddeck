import 'package:flutter/material.dart';
import '../../core/theme/feed_slide_gradients.dart';
import 'feed_slide_frame.dart';
import 'feed_theme.dart';

class CompareGridSlide extends StatelessWidget {
  final Map<String, dynamic> content;
  final Map<String, dynamic>? extra;
  final bool showNative;
  final bool reelsMode;

  const CompareGridSlide({
    super.key,
    required this.content,
    this.extra,
    required this.showNative,
    this.reelsMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final title    = content['title'] as String? ?? 'Usage Comparison';
    final rawWords = extra?['words'] as List<dynamic>? ??
        content['words'] as List<dynamic>? ??
        [];
    final words = rawWords
        .map((e) => (e as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{})
        .take(4)
        .toList();

    final colors = [
      FeedTheme.accent,
      FeedTheme.success,
      FeedTheme.warning,
      FeedTheme.info,
    ];

    return FeedSlideFrame(
      gradient: FeedSlideGradients.hero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 16,
            left: 16,
            child: Text(title.toUpperCase(), style: FeedTheme.typeLabelStyle),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.4,
                    children: words.asMap().entries.map((entry) {
                      final i       = entry.key;
                      final item    = entry.value;
                      final word    = item['word']    as String? ?? '';
                      final usage   = item['usage']   as String? ?? '';
                      final context = item['context'] as String? ?? '';
                      final color   = colors[i % colors.length];

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withAlpha(60)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              word,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: Text(
                                usage.isNotEmpty ? usage : context,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: FeedTheme.textSecondary,
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
