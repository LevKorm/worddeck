import 'dart:math';
import 'package:flutter/material.dart';

/// 3D flip flashcard used in the review session.
///
/// The flip animation is driven by the [isFlipped] prop:
/// flip state is owned by the parent; this widget only animates the change.
class ReviewCard extends StatefulWidget {
  final String word;
  final String? ipa;
  final String? partOfSpeech;
  final String translation;
  final String? example;
  final String? exampleTranslation;
  final List<String>? synonyms;
  final String? usageNotes;

  /// Whether the card is currently showing the back (answer) side.
  final bool isFlipped;

  /// Called when the user taps the card to flip it.
  final VoidCallback onFlip;

  /// Short AI hint shown on the front (e.g. "verb • formal register").
  /// Not the definition — just enough context to jog memory.
  final String? contextDescription;

  const ReviewCard({
    super.key,
    required this.word,
    this.ipa,
    this.partOfSpeech,
    required this.translation,
    this.example,
    this.exampleTranslation,
    this.synonyms,
    this.usageNotes,
    required this.isFlipped,
    required this.onFlip,
    this.contextDescription,
  });

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.isFlipped) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(ReviewCard old) {
    super.didUpdateWidget(old);
    if (widget.isFlipped != old.isFlipped) {
      if (widget.isFlipped) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onFlip,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (ctx, _) {
          final angle = _anim.value * pi;
          final isFront = angle < pi / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isFront
                ? _buildFront(ctx)
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _buildBack(ctx),
                  ),
          );
        },
      ),
    );
  }

  // ── Front side ─────────────────────────────────────────────────────────

  Widget _buildFront(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: theme.colorScheme.outline.withAlpha(51)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withAlpha(13),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.translate_rounded,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
          ),
          const SizedBox(height: 24),

          // Word
          Text(
            widget.word,
            style: theme.textTheme.displayLarge
                ?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),

          // IPA
          if (widget.ipa != null) ...[
            const SizedBox(height: 10),
            Text(
              widget.ipa!,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          // Part of speech badge
          if (widget.partOfSpeech != null) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          ],

          // Context hint
          if (widget.contextDescription != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.contextDescription!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          const Spacer(),

          // Tap hint
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
              ),
              const SizedBox(width: 6),
              Text(
                'Tap to flip',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Back side ───────────────────────────────────────────────────────────

  Widget _buildBack(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: theme.colorScheme.primary.withAlpha(77)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Translation
            Text(
              widget.translation,
              style: theme.textTheme.displayLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),

            // Example sentence
            if (widget.example != null) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _BoldWordText(
                      text: widget.example!,
                      boldWord: widget.word,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.exampleTranslation != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.exampleTranslation!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Synonyms
            if (widget.synonyms != null &&
                widget.synonyms!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: widget.synonyms!
                    .map((s) => Chip(
                          label: Text(s),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],

            // Usage notes
            if (widget.usageNotes != null) ...[
              const SizedBox(height: 12),
              Text(
                widget.usageNotes!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Bold word helper ───────────────────────────────────────────────────────

class _BoldWordText extends StatelessWidget {
  final String text;
  final String boldWord;
  final TextStyle? style;
  final TextAlign textAlign;

  const _BoldWordText({
    required this.text,
    required this.boldWord,
    this.style,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final idx = text.toLowerCase().indexOf(boldWord.toLowerCase());
    if (idx == -1) {
      return Text(text, style: style, textAlign: textAlign);
    }

    final base = style ?? DefaultTextStyle.of(context).style;
    final bold = base.copyWith(fontWeight: FontWeight.bold);

    return RichText(
      textAlign: textAlign,
      text: TextSpan(
        style: base,
        children: [
          if (idx > 0) TextSpan(text: text.substring(0, idx)),
          TextSpan(
              text: text.substring(idx, idx + boldWord.length),
              style: bold),
          if (idx + boldWord.length < text.length)
            TextSpan(text: text.substring(idx + boldWord.length)),
        ],
      ),
    );
  }
}
