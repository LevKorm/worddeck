import 'package:flutter/material.dart';
import '../../core/theme/feed_slide_gradients.dart';
import 'feed_slide_frame.dart';
import 'feed_theme.dart';

class WordFamilySlide extends StatelessWidget {
  final Map<String, dynamic> content;
  final Map<String, dynamic>? extra;
  final bool showNative;
  final bool reelsMode;

  const WordFamilySlide({
    super.key,
    required this.content,
    this.extra,
    required this.showNative,
    this.reelsMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final root     = extra?['root']  as String? ?? content['root']  as String? ?? '';
    final rawForms = extra?['forms'] as List<dynamic>? ??
        content['forms'] as List<dynamic>? ??
        [];
    final forms = rawForms
        .map((e) => (e as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{})
        .toList();

    const roleColors = <String, Color>{
      'noun':      FeedTheme.accent,
      'verb':      FeedTheme.success,
      'adjective': FeedTheme.warning,
      'adverb':    FeedTheme.info,
    };

    return FeedSlideFrame(
      gradient: FeedSlideGradients.wordFamily,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: 16,
            left: 16,
            child: Text('WORD FAMILY', style: FeedTheme.typeLabelStyle),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (root.isNotEmpty) ...[
                  Row(
                    children: [
                      const Text('🌱', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        'Root: $root',
                        style: const TextStyle(
                          fontSize: 13,
                          color: FeedTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                ...forms.map((form) {
                  final role    = (form['role'] as String? ?? '').toLowerCase();
                  final word    = form['word']    as String? ?? '';
                  final example = form['example'] as String? ?? '';
                  final color   = roleColors[role] ?? FeedTheme.textSecondary;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FeedTag(label: role.isEmpty ? '—' : role, color: color),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                word,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: FeedTheme.textPrimary,
                                ),
                              ),
                              if (example.isNotEmpty)
                                Text(
                                  example,
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
