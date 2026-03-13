import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../models/enrichment_result.dart';
import '../../models/flash_card.dart';
import '../../models/space.dart';
import '../../models/translation_result.dart';
import '../../models/word_input.dart';
import '../../modules/auth/auth_provider.dart';
import '../../modules/cards/card_provider.dart';
import '../../modules/spaces/space_provider.dart';
import '../../providers/translate_pipeline_provider.dart';
import '../../widgets/recent_translations_list.dart';

// ── SharedPreferences keys ─────────────────────────────────────────────────
const _kSourceLang    = 'i_speak';
const _kTargetLang    = 'im_learning';
const _kRecentItems   = 'recent_translations'; // legacy / no-space fallback
const _maxRecents     = 30;

String _recentsKey(String? spaceId) =>
    spaceId != null ? 'recent_translations_$spaceId' : _kRecentItems;

// ── Script detection ───────────────────────────────────────────────────────

enum _Script { latin, cyrillic, arabic, cjk, greek, other }

_Script _detectScript(String text) {
  int latin = 0, cyrillic = 0, arabic = 0, cjk = 0, greek = 0;
  for (final r in text.runes) {
    if ((r >= 0x0041 && r <= 0x005A) || (r >= 0x0061 && r <= 0x007A) ||
        (r >= 0x00C0 && r <= 0x024F)) {
      latin++;
    } else if (r >= 0x0400 && r <= 0x04FF) {
      cyrillic++;
    } else if (r >= 0x0600 && r <= 0x06FF) {
      arabic++;
    } else if (r >= 0x0370 && r <= 0x03FF) {
      greek++;
    } else if ((r >= 0x4E00 && r <= 0x9FFF) ||
        (r >= 0x3040 && r <= 0x30FF) ||
        (r >= 0xAC00 && r <= 0xD7AF)) {
      cjk++;
    }
  }
  final scores = {
    _Script.latin: latin,
    _Script.cyrillic: cyrillic,
    _Script.arabic: arabic,
    _Script.greek: greek,
    _Script.cjk: cjk,
  };
  final best = scores.entries.reduce((a, b) => a.value >= b.value ? a : b);
  return best.value == 0 ? _Script.other : best.key;
}

_Script _scriptForLang(String lang) {
  switch (lang.toUpperCase()) {
    case 'UK':
    case 'RU':
      return _Script.cyrillic;
    case 'AR':
      return _Script.arabic;
    case 'EL':
      return _Script.greek;
    case 'JA':
    case 'ZH':
    case 'KO':
      return _Script.cjk;
    default:
      return _Script.latin;
  }
}

// ── State ──────────────────────────────────────────────────────────────────

class TranslateControllerState {
  final String sourceLang;
  final String targetLang;
  final List<RecentItem> recentItems;
  // Set when the language pair was auto-swapped due to script detection.
  final String? autoDetectedFrom;
  // Non-null while the typed text matches a card already in the deck.
  final FlashCard? matchedDeckCard;

  const TranslateControllerState({
    this.sourceLang       = AppConstants.defaultNativeLanguage,
    this.targetLang       = AppConstants.defaultLearningLanguage,
    this.recentItems      = const [],
    this.autoDetectedFrom,
    this.matchedDeckCard,
  });

  TranslateControllerState copyWith({
    String? sourceLang,
    String? targetLang,
    List<RecentItem>? recentItems,
    String? autoDetectedFrom,
    bool clearAutoDetected   = false,
    FlashCard? matchedDeckCard,
    bool clearMatchedDeckCard = false,
  }) =>
      TranslateControllerState(
        sourceLang:       sourceLang       ?? this.sourceLang,
        targetLang:       targetLang       ?? this.targetLang,
        recentItems:      recentItems      ?? this.recentItems,
        autoDetectedFrom: clearAutoDetected ? null : autoDetectedFrom ?? this.autoDetectedFrom,
        matchedDeckCard:  clearMatchedDeckCard ? null : matchedDeckCard ?? this.matchedDeckCard,
      );
}

// ── Notifier ───────────────────────────────────────────────────────────────

class TranslateController
    extends StateNotifier<TranslateControllerState> {
  final Ref _ref;
  Timer? _deckHintTimer;
  String? _currentSpaceId;

  TranslateController(this._ref)
      : super(const TranslateControllerState()) {
    _loadPrefs();
    // Whenever the active space changes, sync languages and reload recents.
    _ref.listen<Space?>(activeSpaceProvider, (prev, next) {
      if (next?.id != prev?.id) {
        _currentSpaceId = next?.id;
        state = state.copyWith(
          sourceLang: next?.nativeLanguage ?? state.sourceLang,
          targetLang: next?.learningLanguage ?? state.targetLang,
          clearAutoDetected: true,
        );
        _loadRecentsForSpace(next?.id);
      }
    });
  }

  @override
  void dispose() {
    _deckHintTimer?.cancel();
    super.dispose();
  }

  // ── Init ─────────────────────────────────────────────────────────────────

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final activeSpace = _ref.read(activeSpaceProvider);
    _currentSpaceId = activeSpace?.id;
    final sourceLang = activeSpace?.nativeLanguage
        ?? prefs.getString(_kSourceLang)
        ?? AppConstants.defaultNativeLanguage;
    final targetLang = activeSpace?.learningLanguage
        ?? prefs.getString(_kTargetLang)
        ?? AppConstants.defaultLearningLanguage;

    final recents = await _readRecentsFromPrefs(_currentSpaceId);
    state = state.copyWith(
      sourceLang:  sourceLang,
      targetLang:  targetLang,
      recentItems: recents,
    );
  }

  Future<void> _loadRecentsForSpace(String? spaceId) async {
    final recents = await _readRecentsFromPrefs(spaceId);
    if (mounted) state = state.copyWith(recentItems: recents);
  }

  Future<List<RecentItem>> _readRecentsFromPrefs(String? spaceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_recentsKey(spaceId)) ?? '[]';
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((item) {
        final m = item as Map<String, dynamic>;
        final ct = m['cached_translation'];
        final ce = m['cached_enrichment'];
        return RecentItem(
          word:              m['word'] as String,
          translation:       m['translation'] as String,
          isSaved:           (m['isSaved'] as bool?) ?? false,
          cachedTranslation: ct != null
              ? TranslationResult.fromJson(ct as Map<String, dynamic>)
              : null,
          cachedEnrichment: ce != null
              ? EnrichmentResult.fromJson(ce as Map<String, dynamic>)
              : null,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> translate(String word) async {
    if (word.trim().isEmpty) return;

    // ── Auto-detect script and swap languages if needed ───────────────────
    final typedScript   = _detectScript(word.trim());
    final expectedScript = _scriptForLang(state.sourceLang);

    String src = state.sourceLang;
    String tgt = state.targetLang;
    String? detectedFrom;

    if (typedScript != _Script.other && typedScript != expectedScript) {
      // The script of the typed text matches the target language — swap.
      final targetScript = _scriptForLang(state.targetLang);
      if (typedScript == targetScript) {
        detectedFrom = src; // remember original source for the notice
        src = state.targetLang;
        tgt = state.sourceLang;
        state = state.copyWith(
          sourceLang: src,
          targetLang: tgt,
          autoDetectedFrom: detectedFrom,
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kSourceLang, src);
        await prefs.setString(_kTargetLang, tgt);
      }
    } else {
      state = state.copyWith(clearAutoDetected: true);
    }

    // ── Deck pre-check: skip API if word already saved ────────────────────
    // Use the already-matched card from the hint if available; otherwise
    // re-check synchronously (handles cases where debounce hadn't fired yet).
    FlashCard? existing = state.matchedDeckCard;
    final wordLower = word.trim().toLowerCase();
    if (existing == null ||
        (existing.word.toLowerCase() != wordLower &&
         existing.translation?.toLowerCase() != wordLower)) {
      final cards = _ref.read(cardListProvider).allCards;
      for (final c in cards) {
        if (c.word.toLowerCase() == wordLower ||
            c.translation?.toLowerCase() == wordLower) {
          existing = c;
          break;
        }
      }
    }
    if (existing != null) {
      _deckHintTimer?.cancel();
      state = state.copyWith(clearMatchedDeckCard: true);
      loadFromDeckCard(existing);
      return;
    }

    final input = WordInput(
      text:       word.trim(),
      sourceLang: src,
      targetLang: tgt,
    );

    await _ref.read(translatePipelineProvider.notifier).translate(input);

    // Add to recents after success — cache full result so re-opens are instant
    final pipeline = _ref.read(translatePipelineProvider);
    if (pipeline.translation != null) {
      await _addToRecents(RecentItem(
        word:              pipeline.translation!.original,
        translation:       pipeline.translation!.translation,
        cachedTranslation: pipeline.translation,
        cachedEnrichment:  pipeline.enrichment,
      ));
    }
  }

  Future<void> saveToCard({String? collectionId, String? spaceId}) async {
    final userId = _ref.read(currentUserProvider)?.userId;
    if (userId == null) return;
    await _ref
        .read(translatePipelineProvider.notifier)
        .saveCard(userId, collectionId: collectionId, spaceId: spaceId);

    state = state.copyWith(clearAutoDetected: true);

    // Mark as saved in recents — preserve cached results
    final t = _ref.read(translatePipelineProvider).translation;
    if (t != null) {
      final updated = state.recentItems
          .map((r) => r.word == t.original ? r.copyWith(isSaved: true) : r)
          .toList();
      state = state.copyWith(recentItems: updated);
      await _saveRecentsToPrefs(updated);
    }
  }

  void skip() {
    _deckHintTimer?.cancel();
    _ref.read(translatePipelineProvider.notifier).reset();
    state = state.copyWith(clearAutoDetected: true, clearMatchedDeckCard: true);
  }

  void clearAutoDetected() =>
      state = state.copyWith(clearAutoDetected: true);

  /// Debounced deck lookup — called on every keystroke.
  /// After 350 ms of inactivity, checks if the typed word matches any deck
  /// card and updates [matchedDeckCard] accordingly.
  void checkDeckHint(String text) {
    _deckHintTimer?.cancel();
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      if (state.matchedDeckCard != null) {
        state = state.copyWith(clearMatchedDeckCard: true);
      }
      return;
    }
    _deckHintTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final cards = _ref.read(cardListProvider).allCards;
      final lower = trimmed.toLowerCase();
      FlashCard? match;
      for (final c in cards) {
        if (c.word.toLowerCase() == lower ||
            (c.translation?.toLowerCase() == lower)) {
          match = c;
          break;
        }
      }
      if (match?.id != state.matchedDeckCard?.id) {
        state = match != null
            ? state.copyWith(matchedDeckCard: match)
            : state.copyWith(clearMatchedDeckCard: true);
      }
    });
  }

  /// Instantly populate the result area from a deck card — no API calls.
  /// Also adds the word to recents (isSaved: true) so it appears in history.
  void loadFromDeckCard(FlashCard card) {
    final translation = TranslationResult(
      original:    card.word,
      translation: card.translation ?? '',
      sourceLang:  state.sourceLang,
      targetLang:  state.targetLang,
    );
    final enrichment = EnrichmentResult(
      transcription:         card.transcription,
      exampleSentence:       card.exampleSentence,
      synonyms:              card.synonyms,
      usageNotes:            card.usageNotes,
      exampleSentenceNative: card.exampleSentenceNative,
      synonymsNative:        card.synonymsNative,
      usageNotesNative:      card.usageNotesNative,
      grammar:               card.grammar,
      synonymsEnriched:      card.synonymsEnriched,
      exampleSentences:      card.exampleSentences,
      usageNotesList:        card.usageNotesList,
    );
    _ref.read(translatePipelineProvider.notifier)
        .restoreFromCache(translation, enrichment, false);
    // Add to recents so the word shows up in history with its saved mark.
    // Fire-and-forget: state update is sync; only prefs write is async.
    unawaited(_addToRecents(RecentItem(
      word:              card.word,
      translation:       card.translation ?? '',
      isSaved:           true,
      cachedTranslation: translation,
      cachedEnrichment:  enrichment,
    )));
  }

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

  /// Clears only unsaved items. Saved cards stay in the list.
  Future<void> clearRecents() async {
    final saved = state.recentItems.where((r) => r.isSaved).toList();
    state = state.copyWith(recentItems: saved);
    await _saveRecentsToPrefs(saved);
  }

  /// Remove a single recent item by word.
  Future<void> removeRecent(String word) async {
    final updated = state.recentItems.where((r) => r.word != word).toList();
    state = state.copyWith(recentItems: updated);
    await _saveRecentsToPrefs(updated);
  }

  /// Restore a recent item from cache — no network call.
  void loadFromCache(RecentItem item) {
    if (item.cachedTranslation == null) return;
    // Always pass isSaved:false — the blue "Already in your vocabulary"
    // badge is shown via alreadyInDeck (computed from allCards) instead.
    // Green isSaved is reserved exclusively for fresh saves this session.
    _ref.read(translatePipelineProvider.notifier).restoreFromCache(
          item.cachedTranslation!,
          item.cachedEnrichment,
          false,
        );
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
              'word':               i.word,
              'translation':        i.translation,
              'isSaved':            i.isSaved,
              'cached_translation': i.cachedTranslation?.toJson(),
              'cached_enrichment':  i.cachedEnrichment?.toJson(),
            })
        .toList());
    await prefs.setString(_recentsKey(_currentSpaceId), json);
  }
}

// ── Provider ───────────────────────────────────────────────────────────────

final translateControllerProvider = StateNotifierProvider.autoDispose<
    TranslateController, TranslateControllerState>(
  (ref) => TranslateController(ref),
);
