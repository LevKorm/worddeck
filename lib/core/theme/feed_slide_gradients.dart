import 'package:flutter/material.dart';

/// Gradient palette for feed slide backgrounds.
/// Each slide type gets a unique dark gradient.
abstract final class FeedSlideGradients {
  /// Deep navy — hero slides (word introduction)
  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B2845), Color(0xFF152238), Color(0xFF0F3460)],
  );

  /// Forest emerald — etymology slides
  static const etymology = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A3A2A), Color(0xFF0D4A35), Color(0xFF0A5C40)],
  );

  /// Warm ember — example sentence slides
  static const sentences = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3A2018), Color(0xFF4A2A12), Color(0xFF5A3010)],
  );

  /// Deep plum — fun fact slides
  static const funFact = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D1B3D), Color(0xFF3A1540), Color(0xFF4A1048)],
  );

  /// Ocean teal — synonym cloud slides
  static const synonymCloud = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF152B3A), Color(0xFF0E3545), Color(0xFF084050)],
  );

  /// Olive gold — mini story slides
  static const miniStory = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E2A15), Color(0xFF3A3510), Color(0xFF45400A)],
  );

  /// Dark teal — word family slides
  static const wordFamily = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF142E2E), Color(0xFF0A3838), Color(0xFF054545)],
  );

  /// Violet — collocations slides
  static const collocations = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF251530), Color(0xFF2E0E3D), Color(0xFF38084A)],
  );

  /// Neutral slate — grammar slides
  static const grammar = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E2024), Color(0xFF25282E), Color(0xFF2E3238)],
  );

  /// Dark crimson — common mistakes slides
  static const commonMistakes = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF351518), Color(0xFF420E12), Color(0xFF50080E)],
  );

  /// Sage — formality scale slides
  static const formalityScale = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E2E1A), Color(0xFF283A1E), Color(0xFF324522)],
  );

  /// Bronze — idiom slides
  static const idioms = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF302518), Color(0xFF3A2A12), Color(0xFF45300E)],
  );

  /// Suggestion glow — system-suggested posts
  static const suggestion = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1830), Color(0xFF282040), Color(0xFF322850)],
  );

  /// Lookup: slideType string → gradient
  static LinearGradient forType(String slideType) {
    switch (slideType) {
      case 'hero':           return hero;
      case 'etymology':      return etymology;
      case 'sentences':      return sentences;
      case 'funFact':        return funFact;
      case 'synonymCloud':   return synonymCloud;
      case 'miniStory':      return miniStory;
      case 'wordFamily':     return wordFamily;
      case 'collocations':   return collocations;
      case 'grammar':        return grammar;
      case 'commonMistakes': return commonMistakes;
      case 'formalityScale': return formalityScale;
      case 'idioms':         return idioms;
      default:               return hero;
    }
  }
}
