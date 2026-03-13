import 'package:flutter/material.dart';
import '../../core/theme/feed_slide_gradients.dart';
import 'feed_slide_frame.dart';
import 'feed_theme.dart';

// TODO: implement YouGlish integration — embed real video player here
/// Placeholder for YouGlish video embed. No actual playback yet.
class VideoSlide extends StatelessWidget {
  final Map<String, dynamic> content;
  final Map<String, dynamic>? extra;
  final bool showNative;
  final bool reelsMode;

  const VideoSlide({
    super.key,
    required this.content,
    this.extra,
    required this.showNative,
    this.reelsMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final word = extra?['word'] as String? ?? content['word'] as String? ?? '';

    return FeedSlideFrame(
      gradient: FeedSlideGradients.hero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: 16,
            left: 16,
            child: Text('VIDEO', style: FeedTheme.typeLabelStyle),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: FeedTheme.accentSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: FeedTheme.accent.withAlpha(100)),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 40,
                  color: FeedTheme.accent,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Hear it spoken',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: FeedTheme.textPrimary,
                ),
              ),
              if (word.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '"$word"',
                  style: const TextStyle(
                    fontSize: 15,
                    color: FeedTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Powered by YouGlish',
                style: TextStyle(
                  fontSize: 11,
                  color: FeedTheme.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Video playback coming soon',
                style: TextStyle(
                  fontSize: 11,
                  color: FeedTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
