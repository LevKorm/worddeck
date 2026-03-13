import 'package:flutter/material.dart';
import '../../core/theme/feed_slide_gradients.dart';
import 'feed_slide_frame.dart';
import 'feed_theme.dart';

class SentencesSlide extends StatelessWidget {
  final Map<String, dynamic> content;
  final Map<String, dynamic>? extra;
  final bool showNative;
  final bool reelsMode;

  const SentencesSlide({
    super.key,
    required this.content,
    this.extra,
    required this.showNative,
    this.reelsMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final rawList  = extra?['sentences'] as List<dynamic>? ?? [];
    final sentences = rawList
        .map((e) => (e as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{})
        .toList();

    final colors = [FeedTheme.accent, FeedTheme.success, FeedTheme.warning];

    return FeedSlideFrame(
      gradient: FeedSlideGradients.sentences,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: 16,
            left: 16,
            child: Text('IN CONTEXT', style: FeedTheme.typeLabelStyle),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sentences.asMap().entries.map((entry) {
                final i    = entry.key;
                final item = entry.value;
                final text = showNative
                    ? item['native']   as String? ?? item['learning'] as String? ?? ''
                    : item['learning'] as String? ?? '';
                final color = colors[i % colors.length];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 3,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            text,
                            style: const TextStyle(
                              fontSize: 14,
                              color: FeedTheme.textPrimary,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
