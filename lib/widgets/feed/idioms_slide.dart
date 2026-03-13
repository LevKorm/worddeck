import 'package:flutter/material.dart';
import '../../core/theme/feed_slide_gradients.dart';
import 'feed_slide_frame.dart';
import 'feed_theme.dart';

class IdiomsSlide extends StatelessWidget {
  final Map<String, dynamic> content;
  final Map<String, dynamic>? extra;
  final bool showNative;
  final bool reelsMode;

  const IdiomsSlide({
    super.key,
    required this.content,
    this.extra,
    required this.showNative,
    this.reelsMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final title    = content['title'] as String? ?? 'Idioms & Phrases';
    final rawItems = content['items'] as List<dynamic>? ??
        extra?['items'] as List<dynamic>? ??
        [];
    final items = rawItems
        .map((e) => (e as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{})
        .toList();

    return FeedSlideFrame(
      gradient: FeedSlideGradients.idioms,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: 16,
            left: 16,
            child: Text('IDIOMS', style: FeedTheme.typeLabelStyle),
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
                ...items.map((item) {
                  final phrase      = item['phrase']          as String? ?? '';
                  final meaning     = item['meaning']         as String? ?? '';
                  final explanation = item['explanation']     as String? ?? '';
                  final nativeTrans = item['nativeTranslation'] as String? ?? '';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: FeedTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: FeedTheme.borderDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '"$phrase"',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: FeedTheme.purple,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          if (meaning.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              meaning,
                              style: const TextStyle(
                                fontSize: 13,
                                color: FeedTheme.textPrimary,
                              ),
                            ),
                          ],
                          if (showNative && nativeTrans.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              nativeTrans,
                              style: const TextStyle(
                                fontSize: 12,
                                color: FeedTheme.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                          if (explanation.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              explanation,
                              style: const TextStyle(
                                fontSize: 12,
                                color: FeedTheme.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
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
