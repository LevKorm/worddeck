import 'package:flutter/material.dart';
import '../../core/theme/feed_slide_gradients.dart';
import 'feed_slide_frame.dart';
import 'feed_theme.dart';

class CollocationsSlide extends StatelessWidget {
  final Map<String, dynamic> content;
  final Map<String, dynamic>? extra;
  final bool showNative;
  final bool reelsMode;

  const CollocationsSlide({
    super.key,
    required this.content,
    this.extra,
    required this.showNative,
    this.reelsMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final rawItems = content['items'] as List<dynamic>? ??
        extra?['items'] as List<dynamic>? ??
        [];
    final items = rawItems
        .map((e) => (e as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{})
        .toList();

    return FeedSlideFrame(
      gradient: FeedSlideGradients.collocations,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: 16,
            left: 16,
            child: Text('COLLOCATIONS', style: FeedTheme.typeLabelStyle),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((item) {
                final phrase  = item['phrase']  as String? ?? '';
                final meaning = item['meaning'] as String? ?? '';
                final note    = item['note']    as String? ?? '';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        phrase,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: FeedTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meaning,
                        style: const TextStyle(
                          fontSize: 13,
                          color: FeedTheme.textSecondary,
                        ),
                      ),
                      if (note.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        FeedTag(label: note, color: FeedTheme.warning),
                      ],
                    ],
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
