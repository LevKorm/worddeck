import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/feed_slide_gradients.dart';
import 'feed_slide_frame.dart';
import 'feed_theme.dart';

class FunFactSlide extends StatelessWidget {
  final Map<String, dynamic> content;
  final Map<String, dynamic>? extra;
  final bool showNative;
  final bool reelsMode;

  const FunFactSlide({
    super.key,
    required this.content,
    this.extra,
    required this.showNative,
    this.reelsMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = content['emoji'] as String? ?? '💡';
    final fact  = content['fact']  as String? ?? content['text'] as String? ?? '';

    return FeedSlideFrame(
      gradient: FeedSlideGradients.funFact,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: 16,
            left: 16,
            child: Text('FUN FACT', style: FeedTheme.typeLabelStyle),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 52, 28, 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: AppTheme.emojiStyle.copyWith(fontSize: 48)),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: FeedTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: FeedTheme.borderDark),
                  ),
                  child: Text(
                    fact,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: FeedTheme.textPrimary,
                      height: 1.65,
                      fontStyle: FontStyle.italic,
                    ),
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
