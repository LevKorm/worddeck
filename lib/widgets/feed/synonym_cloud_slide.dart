import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/feed_slide_gradients.dart';
import 'feed_slide_frame.dart';
import 'feed_theme.dart';

class SynonymCloudSlide extends StatelessWidget {
  final Map<String, dynamic> content;
  final Map<String, dynamic>? extra;
  final bool showNative;
  final bool reelsMode;

  const SynonymCloudSlide({
    super.key,
    required this.content,
    this.extra,
    required this.showNative,
    this.reelsMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final center   = extra?['center'] as String? ?? '';
    final rawWords = extra?['words']  as List<dynamic>? ?? [];
    final words    = rawWords
        .map((e) => (e as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{})
        .toList();

    return FeedSlideFrame(
      gradient: FeedSlideGradients.synonymCloud,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Type label
          const Positioned(
            top: 16,
            left: 16,
            child: Text('SYNONYMS', style: FeedTheme.typeLabelStyle),
          ),

          // Word galaxy
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 40, 0, 40),
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final cx     = constraints.maxWidth / 2;
                final cy     = constraints.maxHeight / 2;
                final radius = math.min(cx, cy) * 0.62;

                return Stack(
                  children: [
                    // Orbiting words
                    ...words.asMap().entries.map((entry) {
                      final i    = entry.key;
                      final item = entry.value;
                      final word = item['word'] as String? ?? '';
                      final dist = (item['distance'] as num?)?.toInt() ?? 1;
                      final r    = radius * (0.6 + dist * 0.15);
                      final angle = (2 * math.pi * i / words.length) - math.pi / 2;
                      final x    = cx + r * math.cos(angle);
                      final y    = cy + r * math.sin(angle);
                      final color = dist == 1
                          ? FeedTheme.accent
                          : dist == 2
                              ? FeedTheme.purple
                              : FeedTheme.textSecondary;

                      return Positioned(
                        left: x - 50,
                        top: y - 16,
                        width: 100,
                        child: Text(
                          word,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13 - dist.toDouble(),
                            color: color,
                            fontWeight: dist == 1
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      );
                    }),

                    // Center word
                    Positioned(
                      left: cx - 70,
                      top: cy - 22,
                      width: 140,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: FeedTheme.accentSoft,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: FeedTheme.accent.withAlpha(120)),
                        ),
                        child: Text(
                          center,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: FeedTheme.accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
