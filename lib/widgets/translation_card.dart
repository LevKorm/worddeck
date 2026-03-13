import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_theme.dart';
import 'cefr_badge.dart';
import 'lang_toggle.dart';
import 'shimmer_widget.dart';
import 'spoiler_overlay.dart';

/// Rich translation result card with all enrichment sections.
///
/// Flat-props widget — no model imports. Receives raw strings only.
class TranslationCard extends StatefulWidget {
  final String word;
  final String? ipa;
  final String? partOfSpeech;
  final String translation;
  final String? example;
  final String? exampleTranslation;
  final List<String>? synonyms;
  final String? usageNotes;
  final String? didYouMean;
  final String? exampleNative;
  final List<String>? synonymsNative;
  final String? usageNotesNative;
  final String sourceLang;
  final String targetLang;
  final VoidCallback onSave;
  final VoidCallback? onSkip;
  final VoidCallback? onCopy;
  final String? cefrLevel;
  final bool isSaved;
  final bool alreadyInDeck;

  /// True while Gemini enrichment is still loading — shows shimmer
  /// placeholders in place of IPA, example, synonyms, and usage notes.
  final bool isEnriching;

  /// When false, the lang toggle is hidden inside the card so the parent
  /// can render it externally (e.g. below the card).
  final bool showLangToggle;

  /// External showNative override. When provided, the card uses this value
  /// instead of its own internal state. Pair with [onNativeChanged].
  final bool? showNative;
  final ValueChanged<bool>? onNativeChanged;

  /// Called when the user taps a synonym chip (learning-language only).
  /// Null disables tappable chips.
  final void Function(String synonym)? onSynonymTap;
  final void Function(String corrected)? onDidYouMeanTap;

  const TranslationCard({
    super.key,
    required this.word,
    this.ipa,
    this.partOfSpeech,
    required this.translation,
    this.example,
    this.exampleTranslation,
    this.synonyms,
    this.usageNotes,
    this.didYouMean,
    this.exampleNative,
    this.synonymsNative,
    this.usageNotesNative,
    this.sourceLang = 'EN',
    this.targetLang = 'UK',
    required this.onSave,
    this.onSkip,
    this.onCopy,
    this.cefrLevel,
    this.isSaved = false,
    this.alreadyInDeck = false,
    this.isEnriching = false,
    this.showLangToggle = true,
    this.showNative,
    this.onNativeChanged,
    this.onSynonymTap,
    this.onDidYouMeanTap,
  });

  @override
  State<TranslationCard> createState() => _TranslationCardState();
}

class _TranslationCardState extends State<TranslationCard> {
  bool _showNativeInternal = false;
  bool _spoilerOn  = false;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Word + copy button ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.word,
                              style: theme.textTheme.headlineLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (widget.cefrLevel != null) ...[
                            const SizedBox(width: 8),
                            CefrBadge(level: widget.cefrLevel, fontSize: 12),
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
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            widget.ipa!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  color: theme.colorScheme.onSurfaceVariant,
                  tooltip: 'Copy word',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.word));
                    if (widget.onCopy != null) widget.onCopy!();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ── Part of speech badge ────────────────────────────────────────
          if (widget.partOfSpeech != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  widget.partOfSpeech!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // ── Did-you-mean banner ─────────────────────────────────────────
          if (widget.didYouMean != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: GestureDetector(
                onTap: widget.onDidYouMeanTap != null
                    ? () => widget.onDidYouMeanTap!(widget.didYouMean!)
                    : null,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: widget.onDidYouMeanTap != null
                        ? Border.all(color: Colors.amber.withAlpha(40))
                        : null,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 15, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.amber.shade800,
                            ),
                            children: [
                              const TextSpan(text: 'Did you mean: '),
                              TextSpan(
                                text: widget.didYouMean,
                                style: TextStyle(
                                  color: Colors.amber.shade800,
                                  fontWeight: FontWeight.w700,
                                  decoration: widget.onDidYouMeanTap != null
                                      ? TextDecoration.underline
                                      : null,
                                  decorationColor: Colors.amber.shade800,
                                ),
                              ),
                              const TextSpan(text: '?'),
                            ],
                          ),
                        ),
                      ),
                      if (widget.onDidYouMeanTap != null) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded,
                            size: 13, color: Colors.amber.shade700),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          // ── Lang toggle row ─────────────────────────────────────────────
          if (widget.showLangToggle)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  LangToggle(
                    sourceLang: widget.sourceLang,
                    targetLang: widget.targetLang,
                    isNative: _showNative,
                    hasNativeContent: _hasNativeContent,
                    onChanged: _setNative,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // ── Translation box with embedded eye button ────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 16, top: 16, bottom: 16, right: 8),
              decoration: const BoxDecoration(
                gradient: AppColors.translationGradient,
                borderRadius: BorderRadius.all(Radius.circular(AppColors.radiusSm)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: SpoilerOverlay(
                      seed: 0,
                      isHidden: _spoilerOn,
                      child: Text(
                        widget.translation,
                        style: AppTheme.translationBoxStyle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _spoilerOn = !_spoilerOn),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _spoilerOn
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Enrichment sections (also hidden by spoiler) ────────────────
          SpoilerOverlay(
            seed: 1,
            isHidden: _spoilerOn,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // ── Shimmer placeholders while Gemini is loading ──────────
                  if (widget.isEnriching) ...[
                    const SizedBox(height: 16),
                    _SectionInline(
                      label: 'EXAMPLE',
                      icon: Icons.format_quote_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          ShimmerWidget(height: 14, borderRadius: 6),
                          SizedBox(height: 5),
                          ShimmerWidget(width: 200, height: 14, borderRadius: 6),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionInline(
                      label: 'SYNONYMS',
                      icon: Icons.account_tree_rounded,
                      child: Row(children: const [
                        ShimmerWidget(width: 62, height: 28, borderRadius: 14),
                        SizedBox(width: 6),
                        ShimmerWidget(width: 80, height: 28, borderRadius: 14),
                        SizedBox(width: 6),
                        ShimmerWidget(width: 54, height: 28, borderRadius: 14),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    _SectionInline(
                      label: 'USAGE',
                      icon: Icons.lightbulb_outline_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          ShimmerWidget(height: 13, borderRadius: 6),
                          SizedBox(height: 5),
                          ShimmerWidget(width: 160, height: 13, borderRadius: 6),
                        ],
                      ),
                    ),
                  ],

                  // ── Real enrichment content ───────────────────────────────
                  if (!widget.isEnriching) ...[
                    // Example sentence
                    if (widget.example != null) ...[
                      const SizedBox(height: 16),
                      _SectionInline(
                        label: 'EXAMPLE',
                        icon: Icons.format_quote_rounded,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Column(
                            key: ValueKey(_showNative),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _BoldWordText(
                                text: (_showNative && widget.exampleNative != null)
                                    ? widget.exampleNative!
                                    : widget.example!,
                                boldWord: widget.word,
                                style: theme.textTheme.bodyMedium,
                              ),
                              if (!_showNative &&
                                  widget.exampleTranslation != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  widget.exampleTranslation!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Synonyms
                    if (widget.synonyms != null &&
                        widget.synonyms!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _SectionInline(
                        label: 'SYNONYMS',
                        icon: Icons.account_tree_rounded,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Wrap(
                            key: ValueKey(_showNative),
                            spacing: 6,
                            runSpacing: 6,
                            children: ((_showNative &&
                                        widget.synonymsNative != null &&
                                        widget.synonymsNative!.isNotEmpty)
                                    ? widget.synonymsNative!
                                    : widget.synonyms!)
                                .map((s) {
                                  final tappable = !_showNative &&
                                      widget.onSynonymTap != null;
                                  return tappable
                                      ? ActionChip(
                                          label: Text(s),
                                          visualDensity: VisualDensity.compact,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          onPressed: () =>
                                              widget.onSynonymTap!(s),
                                        )
                                      : Chip(
                                          label: Text(s),
                                          visualDensity: VisualDensity.compact,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        );
                                })
                                .toList(),
                          ),
                        ),
                      ),
                    ],

                    // Usage notes
                    if (widget.usageNotes != null) ...[
                      const SizedBox(height: 14),
                      _SectionInline(
                        label: 'USAGE',
                        icon: Icons.lightbulb_outline_rounded,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Text(
                            key: ValueKey(_showNative),
                            (_showNative && widget.usageNotesNative != null)
                                ? widget.usageNotesNative!
                                : widget.usageNotes!,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),

          // ── Action buttons ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: child,
                    ),
                    child: widget.isSaved
                        ? const _SavedBadge(key: ValueKey('saved'))
                        : widget.alreadyInDeck
                            ? const _AlreadyInDeckBadge(key: ValueKey('in-deck'))
                            : FilledButton.icon(
                                key: const ValueKey('save'),
                                onPressed: widget.onSave,
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Save to Vocabulary'),
                              ),
                  ),
                ),
                if (widget.onSkip != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onSkip,
                      child: const Text('Skip'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Saved badge (green — just saved this session) ─────────────────────────

class _SavedBadge extends StatelessWidget {
  const _SavedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.green.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.green.withAlpha(80)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 16, color: AppColors.green),
          const SizedBox(width: 8),
          Text(
            'Saved to your vocabulary',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Already-in-deck badge (blue — word was already saved before) ───────────

class _AlreadyInDeckBadge extends StatelessWidget {
  const _AlreadyInDeckBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.indigo.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.indigo.withAlpha(80)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.layers_rounded,
              size: 16, color: AppColors.indigo),
          const SizedBox(width: 8),
          Text(
            'Already in your vocabulary',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.indigo,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section header helper (no outer padding — used inside SpoilerOverlay) ──

class _SectionInline extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;

  const _SectionInline({
    required this.label,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

// ── Section header helper (with horizontal padding — kept for other uses) ───

class _Section extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;

  const _Section({
    required this.label,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13,
                  color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

// ── Example text with the looked-up word bolded ────────────────────────────

class _BoldWordText extends StatelessWidget {
  final String text;
  final String boldWord;
  final TextStyle? style;

  const _BoldWordText({
    required this.text,
    required this.boldWord,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final idx = text.toLowerCase().indexOf(boldWord.toLowerCase());
    if (idx == -1) return Text(text, style: style);

    final base = style ?? DefaultTextStyle.of(context).style;
    final bold = base.copyWith(fontWeight: FontWeight.bold);

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          if (idx > 0) TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + boldWord.length),
            style: bold,
          ),
          if (idx + boldWord.length < text.length)
            TextSpan(text: text.substring(idx + boldWord.length)),
        ],
      ),
    );
  }
}
