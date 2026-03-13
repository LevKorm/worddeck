import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../models/flash_card.dart';
import '../providers/synonym_children_provider.dart';
import 'accordion_section.dart';
import 'cefr_badge.dart';
import 'collection_selector.dart';
import 'lang_toggle.dart';
import 'shimmer_widget.dart';
import 'spoiler_overlay.dart';
import 'synonym_card_sheet.dart';

// ── Context enum ────────────────────────────────────────────────────────────

enum WordCardContext {
  translateResult,
  inDeck,
  vocabularyDetail,
  synonymSheet,
}

// ── Main widget ─────────────────────────────────────────────────────────────

class WordCardDetail extends ConsumerStatefulWidget {
  final WordCardContext cardContext;
  // Core data
  final String word;
  final String translation;
  final String? ipa;
  final String? cefrLevel;
  final String? parentWord;
  final CardStatus? status;
  // Enrichment data
  final String? exampleSentence;
  final List<String>? exampleSentences;
  final List<String>? synonyms;
  final List<Map<String, String>>? synonymsEnriched;
  final String? usageNotes;
  final List<String>? usageNotesList;
  final Map<String, dynamic>? grammar;
  final String? didYouMean;
  // Native variants
  final String? exampleNative;
  final List<String>? synonymsNative;
  final String? usageNotesNative;
  // Language info
  final String sourceLang;
  final String targetLang;
  // State flags
  final bool isEnriching;
  final bool isSaved;
  final bool alreadyInDeck;
  // SM-2 data for review progress (vocabulary detail only)
  final FlashCard? fullCard;
  // Collection
  final String? collectionId;
  final ValueChanged<String?>? onCollectionChanged;
  // Callbacks
  final VoidCallback? onSave;
  final VoidCallback? onSkip;
  final VoidCallback? onClose;
  final void Function(String corrected)? onDidYouMeanTap;
  // External native toggle
  final bool? showNative;
  final ValueChanged<bool>? onNativeChanged;

  const WordCardDetail({
    super.key,
    required this.cardContext,
    required this.word,
    required this.translation,
    this.ipa,
    this.cefrLevel,
    this.parentWord,
    this.status,
    this.exampleSentence,
    this.exampleSentences,
    this.synonyms,
    this.synonymsEnriched,
    this.usageNotes,
    this.usageNotesList,
    this.grammar,
    this.didYouMean,
    this.exampleNative,
    this.synonymsNative,
    this.usageNotesNative,
    this.sourceLang = 'EN',
    this.targetLang = 'UK',
    this.isEnriching = false,
    this.isSaved = false,
    this.alreadyInDeck = false,
    this.fullCard,
    this.collectionId,
    this.onCollectionChanged,
    this.onSave,
    this.onSkip,
    this.onClose,
    this.onDidYouMeanTap,
    this.showNative,
    this.onNativeChanged,
  });

  @override
  ConsumerState<WordCardDetail> createState() => _WordCardDetailState();
}

class _WordCardDetailState extends ConsumerState<WordCardDetail> {
  bool _showNativeInternal = false;
  bool _spoilerOn = false;
  bool _displaySwapped = false;

  bool get _showNative => widget.showNative ?? _showNativeInternal;

  void _setNative(bool v) {
    if (widget.onNativeChanged != null) {
      widget.onNativeChanged!(v);
    } else {
      setState(() => _showNativeInternal = v);
    }
  }

  bool get _hasNativeContent =>
      widget.exampleNative != null ||
      (widget.synonymsNative != null && widget.synonymsNative!.isNotEmpty) ||
      widget.usageNotesNative != null;

  bool get _showStatusPill =>
      widget.cardContext == WordCardContext.vocabularyDetail ||
      widget.cardContext == WordCardContext.inDeck;

  bool get _showReviewProgress =>
      widget.cardContext == WordCardContext.vocabularyDetail;

  bool get _showFromBadge =>
      widget.parentWord != null &&
      widget.cardContext != WordCardContext.translateResult;

  String get _displayWord =>
      _displaySwapped ? widget.translation : widget.word;

  String get _displayTranslation =>
      _displaySwapped ? widget.word : widget.translation;

  // All examples: prefer array, fallback to single
  List<String> get _examples {
    if (widget.exampleSentences != null && widget.exampleSentences!.isNotEmpty) {
      return widget.exampleSentences!;
    }
    if (widget.exampleSentence != null) return [widget.exampleSentence!];
    return [];
  }

  // All usage notes: prefer array, fallback to single
  List<String> get _usageNotes {
    if (widget.usageNotesList != null && widget.usageNotesList!.isNotEmpty) {
      return widget.usageNotesList!;
    }
    if (widget.usageNotes != null) return [widget.usageNotes!];
    return [];
  }

  // Effective synonyms with optional CEFR
  List<_SynonymEntry> get _synonymEntries {
    if (widget.synonymsEnriched != null &&
        widget.synonymsEnriched!.isNotEmpty) {
      return widget.synonymsEnriched!
          .map((e) => _SynonymEntry(
                word: e['word'] ?? '',
                level: e['level'],
              ))
          .where((e) => e.word.isNotEmpty)
          .toList();
    }
    if (widget.synonyms != null && widget.synonyms!.isNotEmpty) {
      return widget.synonyms!
          .map((s) => _SynonymEntry(word: s))
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final examples = _examples;
    final usageNotes = _usageNotes;
    final synonymEntries = _synonymEntries;
    final hasGrammar = widget.grammar != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Word Box ──────────────────────────────────────────────────────
        _buildWordBox(),

        // ── Did-you-mean ──────────────────────────────────────────────────
        if (widget.didYouMean != null) _buildDidYouMean(),

        // ── Synonyms Box ──────────────────────────────────────────────────
        if (!widget.isEnriching && synonymEntries.isNotEmpty)
          _buildSynonymsBox(synonymEntries),

        // ── Accordion Box ─────────────────────────────────────────────────
        if (!widget.isEnriching &&
            (examples.isNotEmpty || usageNotes.isNotEmpty || hasGrammar))
          _buildAccordionBox(examples, usageNotes),

        // ── Shimmer placeholders ──────────────────────────────────────────
        if (widget.isEnriching) _buildShimmer(),

        // ── Bottom controls zone ──────────────────────────────────────────
        _buildBottomControls(),

        // ── Review progress ───────────────────────────────────────────────
        if (_showReviewProgress && widget.fullCard != null)
          _buildReviewProgress(widget.fullCard!),
      ],
    );
  }

  // ── Word Box ────────────────────────────────────────────────────────────

  Widget _buildWordBox() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface3.withOpacity(0.5), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: word + CEFR + status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _displayWord,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (widget.cefrLevel != null) ...[
                          const SizedBox(width: 6),
                          CefrBadge(level: widget.cefrLevel, fontSize: 11),
                        ],
                      ],
                    ),
                    if (widget.isEnriching && widget.ipa == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: ShimmerWidget(width: 80, height: 14, borderRadius: 6),
                      )
                    else if (widget.ipa != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          widget.ipa!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'JetBrains Mono',
                            color: AppColors.textDim,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (_showStatusPill && widget.status != null)
                _StatusPill(status: widget.status!),
            ],
          ),

          // From-parent badge
          if (_showFromBadge) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.indigoDim,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link_rounded, size: 12, color: AppColors.indigo),
                  const SizedBox(width: 4),
                  Text(
                    'From \u201c${widget.parentWord}\u201d',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.indigo,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              height: 1,
              color: Colors.white.withOpacity(0.06),
            ),
          ),

          // Translation row
          Row(
            children: [
              Expanded(
                child: SpoilerOverlay(
                  seed: 0,
                  isHidden: _spoilerOn,
                  child: Text(
                    _displayTranslation,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _spoilerOn = !_spoilerOn),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.accentDim,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _spoilerOn
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 16,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Did-you-mean banner ──────────────────────────────────────────────

  Widget _buildDidYouMean() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withOpacity(0.15)),
      ),
      child: GestureDetector(
        onTap: widget.onDidYouMeanTap != null
            ? () => widget.onDidYouMeanTap!(widget.didYouMean!)
            : null,
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                size: 15, color: AppColors.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  children: [
                    const TextSpan(text: 'Did you mean: '),
                    TextSpan(
                      text: widget.didYouMean,
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                        decoration: widget.onDidYouMeanTap != null
                            ? TextDecoration.underline
                            : null,
                        decorationColor: AppColors.accent,
                      ),
                    ),
                    const TextSpan(text: '?'),
                  ],
                ),
              ),
            ),
            if (widget.onDidYouMeanTap != null) ...[
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded,
                  size: 13, color: AppColors.accent),
            ],
          ],
        ),
      ),
    );
  }

  // ── Synonyms Box ─────────────────────────────────────────────────────

  Widget _buildSynonymsBox(List<_SynonymEntry> entries) {
    final savedSynonyms = widget.fullCard != null
        ? ref.watch(synonymChildrenProvider(widget.fullCard!.id))
        : <String>{};

    // Show native synonyms when native toggle is active
    final showNativeSynonyms = _showNative &&
        widget.synonymsNative != null &&
        widget.synonymsNative!.isNotEmpty;

    return SpoilerOverlay(
      seed: 2,
      isHidden: _spoilerOn,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.surface3.withOpacity(0.5), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.link_rounded, size: 13, color: AppColors.textDim),
                SizedBox(width: 5),
                Text(
                  'Synonyms',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textDim,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: showNativeSynonyms
                  ? Wrap(
                      key: const ValueKey('native'),
                      spacing: 7,
                      runSpacing: 7,
                      children: widget.synonymsNative!
                          .map((s) => _SynonymChip(
                                word: s,
                                onTap: null,
                              ))
                          .toList(),
                    )
                  : Wrap(
                      key: const ValueKey('learning'),
                      spacing: 7,
                      runSpacing: 7,
                      children: entries.map((entry) {
                        final alreadySaved =
                            savedSynonyms.contains(entry.word.toLowerCase());
                        return _SynonymChip(
                          word: entry.word,
                          level: entry.level,
                          isSaved: alreadySaved,
                          onTap: alreadySaved
                              ? null
                              : () => showSynonymCardSheet(
                                    context,
                                    ref,
                                    entry.word,
                                    widget.sourceLang,
                                    widget.targetLang,
                                    parentCardId: widget.fullCard?.id,
                                    parentWord: widget.word,
                                  ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Accordion Box ────────────────────────────────────────────────────

  Widget _buildAccordionBox(List<String> examples, List<String> usageNotes) {
    final hasGrammar = widget.grammar != null;

    return SpoilerOverlay(
      seed: 3,
      isHidden: _spoilerOn,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.surface3.withOpacity(0.5), width: 0.5),
        ),
        child: Column(
          children: [
            if (examples.isNotEmpty)
              AccordionItem(
                label: 'Examples',
                count: examples.length,
                initiallyExpanded: true,
                showDivider: usageNotes.isNotEmpty || hasGrammar,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Column(
                    key: ValueKey(_showNative),
                    children: _showNative && widget.exampleNative != null
                        ? [
                            AccordionContentCard(
                              isLast: true,
                              child: _BoldWordText(
                                text: widget.exampleNative!,
                                boldWord: widget.word,
                              ),
                            ),
                          ]
                        : examples
                            .asMap()
                            .entries
                            .map((e) => AccordionContentCard(
                                  isLast: e.key == examples.length - 1,
                                  child: _BoldWordText(
                                    text: e.value,
                                    boldWord: widget.word,
                                  ),
                                ))
                            .toList(),
                  ),
                ),
              ),
            if (usageNotes.isNotEmpty)
              AccordionItem(
                label: 'Usage',
                count: usageNotes.length,
                showDivider: hasGrammar,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _showNative && widget.usageNotesNative != null
                      ? AccordionContentCard(
                          key: const ValueKey('native'),
                          isLast: true,
                          child: Text(
                            widget.usageNotesNative!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textMuted,
                              height: 1.6,
                            ),
                          ),
                        )
                      : Column(
                          key: const ValueKey('learning'),
                          children: usageNotes
                              .asMap()
                              .entries
                              .map((e) => AccordionContentCard(
                                    isLast: e.key == usageNotes.length - 1,
                                    child: Text(
                                      e.value,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textMuted,
                                        height: 1.6,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                ),
              ),
            if (hasGrammar)
              AccordionItem(
                label: 'Grammar',
                showDivider: false,
                child: _buildGrammarContent(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrammarContent() {
    final g = widget.grammar!;
    return AccordionContentCard(
      isLast: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (g['type'] != null) _GrammarRow(label: 'TYPE', value: g['type']),
          if (g['pattern'] != null)
            _GrammarRow(label: 'PATTERN', value: g['pattern']),
          if (g['related'] != null)
            _GrammarRow(label: 'RELATED FORMS', value: g['related']),
        ],
      ),
    );
  }

  // ── Shimmer placeholders ──────────────────────────────────────────────

  Widget _buildShimmer() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.surface3.withOpacity(0.5), width: 0.5),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerWidget(height: 14, borderRadius: 6),
          SizedBox(height: 8),
          ShimmerWidget(width: 200, height: 14, borderRadius: 6),
          SizedBox(height: 16),
          Row(children: [
            ShimmerWidget(width: 62, height: 28, borderRadius: 14),
            SizedBox(width: 6),
            ShimmerWidget(width: 80, height: 28, borderRadius: 14),
            SizedBox(width: 6),
            ShimmerWidget(width: 54, height: 28, borderRadius: 14),
          ]),
          SizedBox(height: 16),
          ShimmerWidget(height: 13, borderRadius: 6),
          SizedBox(height: 5),
          ShimmerWidget(width: 160, height: 13, borderRadius: 6),
        ],
      ),
    );
  }

  // ── Bottom controls ──────────────────────────────────────────────────

  Widget _buildBottomControls() {
    final ctx = widget.cardContext;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.04)),
        ),
      ),
      child: Column(
        children: [
          // Controls row
          Row(
            children: [
              if (widget.onCollectionChanged != null)
                CollectionSelector(
                  selectedId: widget.collectionId,
                  onSelected: widget.onCollectionChanged!,
                  openUpward: ctx == WordCardContext.vocabularyDetail,
                  alignLeft: true,
                ),
              const SizedBox(width: 8),
              _SwapButton(
                onTap: () =>
                    setState(() => _displaySwapped = !_displaySwapped),
              ),
              const Spacer(),
              LangToggle(
                sourceLang: widget.sourceLang,
                targetLang: widget.targetLang,
                isNative: _showNative,
                hasNativeContent: _hasNativeContent,
                onChanged: _setNative,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Action buttons
          ..._buildActionButtons(ctx),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(WordCardContext ctx) {
    switch (ctx) {
      case WordCardContext.translateResult:
        return [
          if (widget.isSaved)
            _ActionButton.saved()
          else if (widget.alreadyInDeck)
            _ActionButton.alreadyInDeck()
          else
            _ActionButton.primary(
              label: 'Save to Vocabulary',
              icon: Icons.add_rounded,
              onTap: widget.onSave,
            ),
          const SizedBox(height: 6),
          _ActionButton.secondary(
            label: 'Skip',
            onTap: widget.onSkip,
          ),
        ];
      case WordCardContext.inDeck:
        return [
          _ActionButton.alreadyInDeck(),
          const SizedBox(height: 6),
          _ActionButton.secondary(
            label: 'Skip',
            onTap: widget.onSkip,
          ),
        ];
      case WordCardContext.vocabularyDetail:
        return [
          _ActionButton.secondary(
            label: 'Close',
            onTap: widget.onClose,
          ),
        ];
      case WordCardContext.synonymSheet:
        return [
          if (widget.isSaved)
            _ActionButton.saved()
          else if (widget.alreadyInDeck)
            _ActionButton.alreadyInDeck()
          else
            _ActionButton.primary(
              label: 'Save to Vocabulary',
              icon: Icons.add_rounded,
              onTap: widget.onSave,
            ),
          const SizedBox(height: 6),
          _ActionButton.secondary(
            label: 'Close',
            onTap: widget.onClose,
          ),
        ];
    }
  }

  // ── Review Progress ──────────────────────────────────────────────────

  Widget _buildReviewProgress(FlashCard card) {
    final progress = _cardProgress(card);
    final totalEstimate = progress > 0
        ? (card.repetitions / progress).round()
        : 7;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.surface3.withOpacity(0.5), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with progress ring
          Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CustomPaint(
                  painter: _ProgressRingPainter(progress: progress),
                  child: Center(
                    child: Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _masteryLabel(card),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${card.repetitions} of ~$totalEstimate repetitions to master',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.6,
            children: [
              _StatBox(
                value: '${card.repetitions}',
                label: 'Repetitions',
                description: 'Times you\u2019ve reviewed this word',
              ),
              _StatBox(
                value: '${card.intervalDays} day${card.intervalDays == 1 ? '' : 's'}',
                label: 'Interval',
                description: 'Gap between reviews',
              ),
              _StatBox(
                value: card.easeFactor.toStringAsFixed(2),
                label: 'Ease Factor',
                description: 'Higher = fewer reviews needed',
              ),
              _StatBox(
                value: _fmtDate(card.nextReview),
                label: 'Next Review',
                description: 'When this word appears next',
              ),
              _StatBox(
                value: _fmtDate(card.createdAt),
                label: 'Added',
                description: 'When you saved this word',
              ),
              _StatBox(
                value: '~$totalEstimate',
                label: 'Total Needed',
                description: 'Estimated reps to master',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Supporting widgets ──────────────────────────────────────────────────────

class _SynonymEntry {
  final String word;
  final String? level;
  const _SynonymEntry({required this.word, this.level});
}

class _SynonymChip extends StatelessWidget {
  final String word;
  final String? level;
  final bool isSaved;
  final VoidCallback? onTap;

  const _SynonymChip({
    required this.word,
    this.level,
    this.isSaved = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isSaved ? AppColors.green : AppColors.surface3;
    final textColor = isSaved ? AppColors.green : AppColors.text;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSaved) ...[
              Icon(Icons.check_rounded, size: 12, color: AppColors.green),
              const SizedBox(width: 4),
            ],
            Text(
              word,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            if (level != null) ...[
              const SizedBox(width: 6),
              Text(
                level!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSaved
                      ? AppColors.green.withOpacity(0.5)
                      : AppColors.textDim,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final CardStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      CardStatus.pending => 'New',
      CardStatus.learning => 'Learning',
      CardStatus.mastered => 'Mastered',
    };
    final color = switch (status) {
      CardStatus.pending => AppColors.indigo,
      CardStatus.learning => AppColors.accent,
      CardStatus.mastered => AppColors.green,
    };
    final bgColor = switch (status) {
      CardStatus.pending => AppColors.indigoDim,
      CardStatus.learning => AppColors.accentDim,
      CardStatus.mastered => AppColors.greenDim,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _SwapButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SwapButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surface3),
        ),
        child: const Icon(
          Icons.swap_horiz_rounded,
          size: 16,
          color: AppColors.textDim,
        ),
      ),
    );
  }
}

class _GrammarRow extends StatelessWidget {
  final String label;
  final String value;
  const _GrammarRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textDim,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color bgColor;
  final Color textColor;
  final Color? borderColor;
  final double fontSize;
  final FontWeight fontWeight;
  final double verticalPadding;

  const _ActionButton._({
    required this.label,
    this.icon,
    this.onTap,
    required this.bgColor,
    required this.textColor,
    this.borderColor,
    required this.fontSize,
    required this.fontWeight,
    required this.verticalPadding,
  });

  factory _ActionButton.primary({
    required String label,
    IconData? icon,
    VoidCallback? onTap,
  }) =>
      _ActionButton._(
        label: label,
        icon: icon,
        onTap: onTap,
        bgColor: AppColors.accent,
        textColor: const Color(0xFF1A1A1A),
        fontSize: 14,
        fontWeight: FontWeight.w600,
        verticalPadding: 13,
      );

  factory _ActionButton.secondary({
    required String label,
    VoidCallback? onTap,
  }) =>
      _ActionButton._(
        label: label,
        onTap: onTap,
        bgColor: Colors.transparent,
        textColor: AppColors.textMuted,
        borderColor: AppColors.surface3,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        verticalPadding: 11,
      );

  factory _ActionButton.saved() => _ActionButton._(
        label: 'Saved to your vocabulary',
        icon: Icons.check_circle_rounded,
        bgColor: AppColors.greenDim,
        textColor: AppColors.green,
        borderColor: AppColors.green.withOpacity(0.3),
        fontSize: 14,
        fontWeight: FontWeight.w600,
        verticalPadding: 13,
      );

  factory _ActionButton.alreadyInDeck() => _ActionButton._(
        label: 'Already in vocabulary',
        icon: Icons.layers_rounded,
        bgColor: AppColors.indigoDim,
        textColor: AppColors.indigo,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        verticalPadding: 13,
      );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: borderColor != null
              ? Border.all(color: borderColor!)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: fontWeight,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final String description;

  const _StatBox({
    required this.value,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.textDim,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  const _ProgressRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    const strokeWidth = 4.0;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.surface3
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Foreground arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -1.5708, // -π/2 (start from top)
        progress * 6.2832, // progress * 2π
        false,
        Paint()
          ..color = AppColors.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) => old.progress != progress;
}

// ── Bold word text ────────────────────────────────────────────────────────

class _BoldWordText extends StatelessWidget {
  final String text;
  final String boldWord;

  const _BoldWordText({required this.text, required this.boldWord});

  @override
  Widget build(BuildContext context) {
    final idx = text.toLowerCase().indexOf(boldWord.toLowerCase());
    const style = TextStyle(
      fontSize: 14.5,
      color: AppColors.text,
      height: 1.6,
    );
    if (idx == -1) return Text(text, style: style);

    return Text.rich(
      TextSpan(
        style: style,
        children: [
          if (idx > 0) TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + boldWord.length),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
          if (idx + boldWord.length < text.length)
            TextSpan(text: text.substring(idx + boldWord.length)),
        ],
      ),
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

double _cardProgress(FlashCard c) {
  if (c.repetitions == 0) return 0.0;
  if (c.intervalDays < 7) return 0.25;
  if (c.intervalDays < 21) return 0.6;
  return 1.0;
}

String _fmtDate(DateTime d) {
  const m = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${m[d.month - 1]} ${d.day}';
}

String _masteryLabel(FlashCard c) {
  if (c.repetitions == 0) return 'New';
  if (c.intervalDays < 7) return 'Learning';
  if (c.intervalDays < 21) return 'Review';
  return 'Mature';
}
