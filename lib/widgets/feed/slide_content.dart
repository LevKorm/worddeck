import 'package:flutter/material.dart';

import '../../models/feed_slide.dart';
import 'collocations_slide.dart';
import 'common_mistakes_slide.dart';
import 'compare_grid_slide.dart';
import 'compare_hero_slide.dart';
import 'etymology_slide.dart';
import 'formality_scale_slide.dart';
import 'fun_fact_slide.dart';
import 'grammar_slide.dart';
import 'hero_slide.dart';
import 'idioms_slide.dart';
import 'mini_story_slide.dart';
import 'sentences_slide.dart';
import 'synonym_cloud_slide.dart';
import 'theme_hero_slide.dart';
import 'video_slide.dart';
import 'word_family_slide.dart';

/// Resolves a [FeedSlide] to the appropriate slide widget.
///
/// Passes the language-resolved [content] map (learning or native based on
/// [showNative]) plus the always-present [extra] map to each slide widget.
class SlideContent extends StatelessWidget {
  final FeedSlide slide;
  final bool showNative;
  final bool reelsMode;
  final bool isSuggested;

  const SlideContent({
    super.key,
    required this.slide,
    required this.showNative,
    this.reelsMode = false,
    this.isSuggested = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = showNative ? slide.contentNative : slide.contentLearning;
    final extra   = slide.extra;

    switch (slide.type) {
      case FeedSlideType.hero:
        return HeroSlide(
            content: content, extra: extra,
            showNative: showNative, reelsMode: reelsMode,
            isSuggested: isSuggested);

      case FeedSlideType.etymology:
        return EtymologySlide(
            content: content, extra: extra,
            showNative: showNative, reelsMode: reelsMode);

      case FeedSlideType.sentences:
        return SentencesSlide(
            content: content, extra: extra,
            showNative: showNative, reelsMode: reelsMode);

      case FeedSlideType.funFact:
        return FunFactSlide(
            content: content, extra: extra,
            showNative: showNative, reelsMode: reelsMode);

      case FeedSlideType.synonymCloud:
        return SynonymCloudSlide(
            content: content, extra: extra,
            showNative: showNative, reelsMode: reelsMode);

      case FeedSlideType.miniStory:
        return MiniStorySlide(
            content: content, extra: extra,
            showNative: showNative, reelsMode: reelsMode);

      case FeedSlideType.wordFamily:
        return WordFamilySlide(
            content: content, extra: extra,
            showNative: showNative, reelsMode: reelsMode);

      case FeedSlideType.collocations:
        return CollocationsSlide(
            content: content, extra: extra,
            showNative: showNative, reelsMode: reelsMode);

      case FeedSlideType.grammar:
        return GrammarSlide(
            content: content, extra: extra,
            showNative: showNative, reelsMode: reelsMode);

      case FeedSlideType.commonMistakes:
        return CommonMistakesSlide(
            content: content, extra: extra,
            showNative: showNative, reelsMode: reelsMode);

      case FeedSlideType.formalityScale:
        return FormalityScaleSlide(
            content: content, extra: extra,
            showNative: showNative, reelsMode: reelsMode);

      case FeedSlideType.idioms:
        return IdiomsSlide(
            content: content, extra: extra,
            showNative: showNative, reelsMode: reelsMode);

      case FeedSlideType.compareHero:
        return CompareHeroSlide(
            content: content, extra: extra,
            showNative: showNative, reelsMode: reelsMode);

      case FeedSlideType.compareGrid:
        return CompareGridSlide(
            content: content, extra: extra,
            showNative: showNative, reelsMode: reelsMode);

      case FeedSlideType.themeHero:
        return ThemeHeroSlide(
            content: content, extra: extra,
            showNative: showNative, reelsMode: reelsMode);

      case FeedSlideType.video:
        return VideoSlide(
            content: content, extra: extra,
            showNative: showNative, reelsMode: reelsMode);
    }
  }
}
