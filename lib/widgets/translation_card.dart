import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final VoidCallback onSave;
  final VoidCallback? onSkip;
  final VoidCallback? onCopy;
  final bool isSaved;

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
    required this.onSave,
    this.onSkip,
    this.onCopy,
    this.isSaved = false,
  });

  @override
  State<TranslationCard> createState() => _TranslationCardState();
}

class _TranslationCardState extends State<TranslationCard> {
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
                      Text(
                        widget.word,
                        style: theme.textTheme.headlineLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (widget.ipa != null)
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
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 15, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Did you mean: ${widget.didYouMean}?',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 14),

          // ── Translation highlight bar ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.translation,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),

          // ── Example sentence ────────────────────────────────────────────
          if (widget.example != null) ...[
            const SizedBox(height: 16),
            _Section(
              label: 'EXAMPLE',
              icon: Icons.format_quote_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BoldWordText(
                    text: widget.example!,
                    boldWord: widget.word,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (widget.exampleTranslation != null) ...[
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
          ],

          // ── Synonyms ────────────────────────────────────────────────────
          if (widget.synonyms != null && widget.synonyms!.isNotEmpty) ...[
            const SizedBox(height: 14),
            _Section(
              label: 'SYNONYMS',
              icon: Icons.account_tree_rounded,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.synonyms!
                    .map((s) => Chip(
                          label: Text(s),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            ),
          ],

          // ── Usage notes ─────────────────────────────────────────────────
          if (widget.usageNotes != null) ...[
            const SizedBox(height: 14),
            _Section(
              label: 'USAGE',
              icon: Icons.lightbulb_outline_rounded,
              child: Text(
                widget.usageNotes!,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],

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
                        ? OutlinedButton.icon(
                            key: const ValueKey('saved'),
                            onPressed: null,
                            icon: const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 18),
                            label: const Text('Saved'),
                          )
                        : FilledButton.icon(
                            key: const ValueKey('save'),
                            onPressed: widget.onSave,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Save to Deck'),
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

// ── Section header helper ──────────────────────────────────────────────────

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

    return RichText(
      text: TextSpan(
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
