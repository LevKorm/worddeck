import 'package:flutter/material.dart';

class LevelDef {
  final int level;
  final String name;
  final int startWords;
  final int span;
  final Color colorPrimary;
  final Color colorSecondary;
  final String description;

  const LevelDef({
    required this.level,
    required this.name,
    required this.startWords,
    required this.span,
    required this.colorPrimary,
    required this.colorSecondary,
    required this.description,
  });

  LinearGradient get barGradient => LinearGradient(
        colors: [
          colorPrimary.withValues(alpha: 0.8),
          colorSecondary.withValues(alpha: 0.4),
        ],
      );

  Color get badgeBg => colorPrimary.withValues(alpha: 0.15);
  Color get badgeBorder => colorPrimary.withValues(alpha: 0.25);
  Color get chamberEmpty => colorPrimary.withValues(alpha: 0.10);
  Color get chamberFilled => colorPrimary.withValues(alpha: 0.65);
  Color get chamberBorderEmpty => colorPrimary.withValues(alpha: 0.15);
  Color get chamberBorderFilled => colorPrimary.withValues(alpha: 0.4);
}

const levels = <LevelDef>[
  LevelDef(
    level: 1,
    name: 'Starter',
    startWords: 0,
    span: 8,
    colorPrimary: Color(0xFF2A3A8A),
    colorSecondary: Color(0xFF1E2D6D),
    description: 'Every journey begins with a single word',
  ),
  LevelDef(
    level: 2,
    name: 'Seeker',
    startWords: 8,
    span: 12,
    colorPrimary: Color(0xFF3B3F9E),
    colorSecondary: Color(0xFF2D2F7A),
    description: 'Curiosity is pulling you forward',
  ),
  LevelDef(
    level: 3,
    name: 'Collector',
    startWords: 20,
    span: 20,
    colorPrimary: Color(0xFF4F46B0),
    colorSecondary: Color(0xFF3B3690),
    description: 'You\'re gathering words with purpose',
  ),
  LevelDef(
    level: 4,
    name: 'Builder',
    startWords: 40,
    span: 30,
    colorPrimary: Color(0xFF6344C4),
    colorSecondary: Color(0xFF4C35A0),
    description: 'A vocabulary takes shape',
  ),
  LevelDef(
    level: 5,
    name: 'Linguist',
    startWords: 70,
    span: 40,
    colorPrimary: Color(0xFF7640D0),
    colorSecondary: Color(0xFF5C35AA),
    description: 'Words are becoming second nature',
  ),
  LevelDef(
    level: 6,
    name: 'Explorer',
    startWords: 110,
    span: 55,
    colorPrimary: Color(0xFF6366F1),
    colorSecondary: Color(0xFF4F46E5),
    description: 'You navigate language with confidence',
  ),
  LevelDef(
    level: 7,
    name: 'Scholar',
    startWords: 165,
    span: 70,
    colorPrimary: Color(0xFF6D5DD3),
    colorSecondary: Color(0xFF8B5CF6),
    description: 'Deep understanding is forming',
  ),
  LevelDef(
    level: 8,
    name: 'Adept',
    startWords: 235,
    span: 90,
    colorPrimary: Color(0xFF7C3AED),
    colorSecondary: Color(0xFFA855F7),
    description: 'Fluency is within reach',
  ),
  LevelDef(
    level: 9,
    name: 'Wordsmith',
    startWords: 325,
    span: 110,
    colorPrimary: Color(0xFF6D42B0),
    colorSecondary: Color(0xFF0D9488),
    description: 'You craft meaning with precision',
  ),
  LevelDef(
    level: 10,
    name: 'Fluent',
    startWords: 435,
    span: 140,
    colorPrimary: Color(0xFF0F766E),
    colorSecondary: Color(0xFF14B8A6),
    description: 'Language flows naturally',
  ),
  LevelDef(
    level: 11,
    name: 'Polyglot',
    startWords: 575,
    span: 170,
    colorPrimary: Color(0xFF0D9488),
    colorSecondary: Color(0xFF22C55E),
    description: 'A world of words is yours',
  ),
  LevelDef(
    level: 12,
    name: 'Sage',
    startWords: 745,
    span: 200,
    colorPrimary: Color(0xFF16A34A),
    colorSecondary: Color(0xFF4ADE80),
    description: 'Wisdom lives in your vocabulary',
  ),
  LevelDef(
    level: 13,
    name: 'Virtuoso',
    startWords: 945,
    span: 240,
    colorPrimary: Color(0xFF22C55E),
    colorSecondary: Color(0xFF86EFAC),
    description: 'Mastery is evident in every word',
  ),
  LevelDef(
    level: 14,
    name: 'Master',
    startWords: 1185,
    span: 9999,
    colorPrimary: Color(0xFF4ADE80),
    colorSecondary: Color(0xFFBBF7D0),
    description: 'The summit. Your vocabulary is vast.',
  ),
];

LevelDef getLevelForWords(int words) {
  for (final lv in levels.reversed) {
    if (words >= lv.startWords) return lv;
  }
  return levels.first;
}

double getLevelProgress(int words) {
  final lv = getLevelForWords(words);
  return ((words - lv.startWords) / lv.span).clamp(0.0, 1.0);
}

int wordsToNextLevel(int words) {
  final lv = getLevelForWords(words);
  return (lv.startWords + lv.span) - words;
}
