import 'package:flutter/material.dart';
import '../../core/theme/feed_slide_gradients.dart';
import 'feed_slide_frame.dart';
import 'feed_theme.dart';

class HeroSlide extends StatelessWidget {
  final Map<String, dynamic> content;
  final Map<String, dynamic>? extra;
  final bool showNative;
  final bool reelsMode;
  final bool isSuggested;

  const HeroSlide({
    super.key,
    required this.content,
    this.extra,
    required this.showNative,
    this.reelsMode = false,
    this.isSuggested = false,
  });

  @override
  Widget build(BuildContext context) {
    final word        = extra?['word']        as String? ?? content['word']        as String? ?? '';
    final translation = extra?['translation'] as String? ?? content['translation'] as String? ?? '';

    final wordCount  = word.trim().split(RegExp(r'\s+')).length;
    final fontSize   = wordCount >= 5 ? 24.0 : wordCount >= 3 ? 30.0 : 34.0;

    final gradient = isSuggested
        ? FeedSlideGradients.suggestion
        : FeedSlideGradients.hero;

    return FeedSlideFrame(
      gradient: gradient,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Type label / suggestion indicator — top left
          Positioned(
            top: 16,
            left: 16,
            child: isSuggested
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 12,
                        color: Colors.white.withOpacity(0.4),
                      ),
                      const SizedBox(width: 4),
                      const Text('SUGGESTION', style: FeedTheme.typeLabelStyle),
                    ],
                  )
                : const Text('HERO', style: FeedTheme.typeLabelStyle),
          ),

          // Word + translation — vertically centered
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    word,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (translation.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      translation,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
