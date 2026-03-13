import 'package:flutter/material.dart';
import '../../core/theme/feed_slide_gradients.dart';
import 'feed_slide_frame.dart';
import 'feed_theme.dart';

class GrammarSlide extends StatelessWidget {
  final Map<String, dynamic> content;
  final Map<String, dynamic>? extra;
  final bool showNative;
  final bool reelsMode;

  const GrammarSlide({
    super.key,
    required this.content,
    this.extra,
    required this.showNative,
    this.reelsMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final title     = content['title']  as String? ?? 'Grammar Notes';
    final rawPoints = content['points'] as List<dynamic>? ?? [];
    final rawTraps  = content['traps']  as List<dynamic>? ?? [];
    final points    = rawPoints.whereType<String>().toList();
    final traps     = rawTraps.whereType<String>().toList();

    return FeedSlideFrame(
      gradient: FeedSlideGradients.grammar,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: 16,
            left: 16,
            child: Text('GRAMMAR', style: FeedTheme.typeLabelStyle),
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
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: FeedTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...points.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('•  ',
                              style: TextStyle(
                                  color: FeedTheme.info,
                                  fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              p,
                              style: const TextStyle(
                                fontSize: 14,
                                color: FeedTheme.textPrimary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                if (traps.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: FeedTheme.error.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: FeedTheme.error.withAlpha(80)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '⚠️  Common traps',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: FeedTheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...traps.map((t) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '• $t',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: FeedTheme.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            )),
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
