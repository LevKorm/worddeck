import '../../models/flash_card.dart';

// ── Thresholds ──────────────────────────────────────────────────────────────

const cefrThresholds = [
  ('A1', 0),
  ('A2', 30),
  ('B1', 100),
  ('B2', 250),
  ('C1', 500),
  ('C2', 1000),
];

// ── Level metadata ──────────────────────────────────────────────────────────

class CefrMeta {
  final String name;
  final String emoji;
  final String description;
  const CefrMeta({required this.name, required this.emoji, required this.description});
}

const cefrLevelMeta = <String, CefrMeta>{
  'A1': CefrMeta(
    name: 'First Steps',
    emoji: '🌱',
    description: 'You\'re planting the seeds. Every word you save here '
        'is the start of something — greetings, numbers, the basics '
        'that make a language feel real for the first time.',
  ),
  'A2': CefrMeta(
    name: 'Foundation Builder',
    emoji: '🧱',
    description: 'You can handle simple conversations — ordering food, '
        'asking directions, talking about your daily routine. '
        'The foundation is solid and growing.',
  ),
  'B1': CefrMeta(
    name: 'Intermediate Explorer',
    emoji: '🏔️',
    description: 'You\'re building real fluency. Your vocabulary covers '
        'everyday conversations and you\'re starting to express '
        'opinions with nuance. This is where it gets interesting.',
  ),
  'B2': CefrMeta(
    name: 'Independent Thinker',
    emoji: '⚡',
    description: 'You can hold your own in most situations — debating, '
        'explaining complex ideas, understanding native content. '
        'People stop switching to English for you.',
  ),
  'C1': CefrMeta(
    name: 'Fluent Navigator',
    emoji: '🧭',
    description: 'You navigate the language with ease. Idioms, subtle '
        'humor, professional vocabulary — it\'s all becoming '
        'second nature. You think in the language now.',
  ),
  'C2': CefrMeta(
    name: 'Near-Native Mastery',
    emoji: '👑',
    description: 'The summit. You understand virtually everything — '
        'literature, film, slang, wordplay. The language isn\'t '
        'something you learned. It\'s something you are.',
  ),
};

// ── Scoring ─────────────────────────────────────────────────────────────────

double pointsForCard(FlashCard card) {
  if (card.repetitions == 0) return 0.5;       // pending / new
  if (card.intervalDays < 7)  return 1.0;      // learning
  if (card.intervalDays < 21) return 1.5;      // review
  return 2.0;                                   // mature / mastered
}

// ── Result ──────────────────────────────────────────────────────────────────

class CefrLevelResult {
  final String currentLevel;
  final String nextLevel;
  final double totalPoints;
  final double currentThreshold;
  final double nextThreshold;
  final double progress;
  final int pointsToNext;

  const CefrLevelResult({
    required this.currentLevel,
    required this.nextLevel,
    required this.totalPoints,
    required this.currentThreshold,
    required this.nextThreshold,
    required this.progress,
    required this.pointsToNext,
  });
}

// ── Calculator ──────────────────────────────────────────────────────────────

CefrLevelResult calculateCefrLevel(List<FlashCard> cards) {
  double total = 0;
  for (final card in cards) {
    total += pointsForCard(card);
  }

  String current = 'A1';
  String next = 'A2';
  double currentTh = 0;
  double nextTh = 30;

  for (int i = 0; i < cefrThresholds.length; i++) {
    if (total >= cefrThresholds[i].$2) {
      current = cefrThresholds[i].$1;
      if (i + 1 < cefrThresholds.length) {
        next = cefrThresholds[i + 1].$1;
        currentTh = cefrThresholds[i].$2.toDouble();
        nextTh = cefrThresholds[i + 1].$2.toDouble();
      } else {
        next = 'C2';
        currentTh = cefrThresholds[i].$2.toDouble();
        nextTh = currentTh;
      }
    }
  }

  final progress = nextTh == currentTh
      ? 1.0
      : ((total - currentTh) / (nextTh - currentTh)).clamp(0.0, 1.0);
  final pointsToNext = (nextTh - total).ceil().clamp(0, 99999);

  return CefrLevelResult(
    currentLevel: current,
    nextLevel: next,
    totalPoints: total,
    currentThreshold: currentTh,
    nextThreshold: nextTh,
    progress: progress,
    pointsToNext: pointsToNext,
  );
}
