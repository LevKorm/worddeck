import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../models/word_input.dart';
import '../../modules/auth/auth_provider.dart';
import '../../providers/translate_pipeline_provider.dart';
import '../../widgets/recent_translations_list.dart';

// ── SharedPreferences keys ─────────────────────────────────────────────────
const _kSourceLang    = 'i_speak';
const _kTargetLang    = 'im_learning';
const _kRecentItems   = 'recent_translations';
const _maxRecents     = 10;

// ── State ──────────────────────────────────────────────────────────────────

class TranslateControllerState {
  final String sourceLang;
  final String targetLang;
  final List<RecentItem> recentItems;

  const TranslateControllerState({
    this.sourceLang  = AppConstants.defaultNativeLanguage,
    this.targetLang  = AppConstants.defaultLearningLanguage,
    this.recentItems = const [],
  });

  TranslateControllerState copyWith({
    String? sourceLang,
    String? targetLang,
    List<RecentItem>? recentItems,
  }) =>
      TranslateControllerState(
        sourceLang:  sourceLang  ?? this.sourceLang,
        targetLang:  targetLang  ?? this.targetLang,
        recentItems: recentItems ?? this.recentItems,
      );
}

// ── Notifier ───────────────────────────────────────────────────────────────

class TranslateController
    extends StateNotifier<TranslateControllerState> {
  final Ref _ref;

  TranslateController(this._ref)
      : super(const TranslateControllerState()) {
    _loadPrefs();
  }

  // ── Init ─────────────────────────────────────────────────────────────────

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final sourceLang =
        prefs.getString(_kSourceLang) ?? AppConstants.defaultNativeLanguage;
    final targetLang =
        prefs.getString(_kTargetLang) ?? AppConstants.defaultLearningLanguage;

    List<RecentItem> recents = [];
    try {
      final raw = prefs.getString(_kRecentItems) ?? '[]';
      final list = jsonDecode(raw) as List<dynamic>;
      recents = list
          .map((item) => RecentItem(
                word:        item['word'] as String,
                translation: item['translation'] as String,
                isSaved:     (item['isSaved'] as bool?) ?? false,
              ))
          .toList();
    } catch (_) {}

    state = state.copyWith(
      sourceLang:  sourceLang,
      targetLang:  targetLang,
      recentItems: recents,
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> translate(String word) async {
    if (word.trim().isEmpty) return;

    final input = WordInput(
      text:       word.trim(),
      sourceLang: state.sourceLang,
      targetLang: state.targetLang,
    );

    await _ref.read(translatePipelineProvider.notifier).translate(input);

    // Add to recents after success
    final pipeline = _ref.read(translatePipelineProvider);
    if (pipeline.translation != null) {
      await _addToRecents(RecentItem(
        word:        pipeline.translation!.original,
        translation: pipeline.translation!.translation,
      ));
    }
  }

  Future<void> saveToCard() async {
    final userId = _ref.read(currentUserProvider)?.userId;
    if (userId == null) return;
    await _ref.read(translatePipelineProvider.notifier).saveCard(userId);

    // Mark as saved in recents
    final t = _ref.read(translatePipelineProvider).translation;
    if (t != null) {
      final updated = state.recentItems
          .map((r) => r.word == t.original
              ? RecentItem(
                  word:        r.word,
                  translation: r.translation,
                  isSaved:     true,
                )
              : r)
          .toList();
      state = state.copyWith(recentItems: updated);
      await _saveRecentsToPrefs(updated);
    }
  }

  void skip() => _ref.read(translatePipelineProvider.notifier).reset();

  Future<void> setSourceLang(String lang) async {
    state = state.copyWith(sourceLang: lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSourceLang, lang);
  }

  Future<void> setTargetLang(String lang) async {
    state = state.copyWith(targetLang: lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTargetLang, lang);
  }

  Future<void> swapLanguages() async {
    final src = state.sourceLang;
    final tgt = state.targetLang;
    state = state.copyWith(sourceLang: tgt, targetLang: src);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSourceLang, tgt);
    await prefs.setString(_kTargetLang, src);
    _ref.read(translatePipelineProvider.notifier).reset();
  }

  Future<void> clearRecents() async {
    state = state.copyWith(recentItems: []);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRecentItems, '[]');
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _addToRecents(RecentItem item) async {
    final withoutDup =
        state.recentItems.where((r) => r.word != item.word).toList();
    final updated = [item, ...withoutDup].take(_maxRecents).toList();
    state = state.copyWith(recentItems: updated);
    await _saveRecentsToPrefs(updated);
  }

  Future<void> _saveRecentsToPrefs(List<RecentItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(items
        .map((i) => {
              'word':        i.word,
              'translation': i.translation,
              'isSaved':     i.isSaved,
            })
        .toList());
    await prefs.setString(_kRecentItems, json);
  }
}

// ── Provider ───────────────────────────────────────────────────────────────

final translateControllerProvider = StateNotifierProvider.autoDispose<
    TranslateController, TranslateControllerState>(
  (ref) => TranslateController(ref),
);
