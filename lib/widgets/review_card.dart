import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'cefr_badge.dart';
import 'lang_toggle.dart';

/// 3D flip flashcard used in the review session.
///
/// The flip animation is driven by the [isFlipped] prop:
/// flip state is owned by the parent; this widget only animates the change.
/// Tapping the card toggles between front and back.
class ReviewCard extends StatefulWidget {
  final String word;
  final String? ipa;
  final String? partOfSpeech;
  final String translation;
  final String? example;
  final String? exampleTranslation;
  final List<String>? synonyms;
  final String? usageNotes;
  final String? exampleNative;
  final List<String>? synonymsNative;
  final String? usageNotesNative;
  final String sourceLang;
  final String targetLang;
  final bool isFlipped;
  final VoidCallback onFlip;
  final String? contextDescription;
  final String? cefrLevel;
  final void Function(String synonym)? onSynonymTap;

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
    this.exampleNative,
    this.synonymsNative,
    this.usageNotesNative,
    this.sourceLang = 'EN',
    this.targetLang = 'UK',
    required this.isFlipped,
    required this.onFlip,
    this.contextDescription,
    this.cefrLevel,
    this.onSynonymTap,
  });

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _showNative = false;

  bool get _hasNativeContent =>
      widget.exampleNative != null ||
      (widget.synonymsNative != null && widget.synonymsNative!.isNotEmpty) ||
      widget.usageNotesNative != null;

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
    return AnimatedBuilder(
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
              ? GestureDetector(
                  onTap: widget.onFlip,
                  child: _buildFront(ctx),
                )
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(pi),
                  child: GestureDetector(
                    onTap: widget.onFlip,
                    child: _buildBack(ctx),
                  ),
                ),
        );
      },
    );
  }

  // ── Front side ─────────────────────────────────────────────────────────

  Widget _buildFront(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surface3, width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // Word
          Text(
            widget.word,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          // IPA
          if (widget.ipa != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.ipa!,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          // CEFR badge
          if (widget.cefrLevel != null) ...[
            const SizedBox(height: 12),
            CefrBadge(level: widget.cefrLevel, fontSize: 11),
          ],

          const Spacer(flex: 3),

          // Tap hint
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 14,
                color: AppColors.textDim.withAlpha(120),
              ),
              const SizedBox(width: 6),
              Text(
                'Tap to reveal',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textDim.withAlpha(120),
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
    return Container(
      constraints: const BoxConstraints.expand(),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withAlpha(40),
          width: 0.5,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            // Small word label at top
            Text(
              widget.word,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textDim,
              ),
            ),
            const SizedBox(height: 8),

            // Translation — big and prominent
            Text(
              widget.translation,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),

            // Lang toggle
            if (_hasNativeContent) ...[
              const SizedBox(height: 16),
              LangToggle(
                sourceLang: widget.sourceLang,
                targetLang: widget.targetLang,
                isNative: _showNative,
                hasNativeContent: _hasNativeContent,
                onChanged: (v) => setState(() => _showNative = v),
              ),
            ],

            // Example sentence
            if (widget.example != null) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Column(
                    key: ValueKey(_showNative),
                    children: [
                      _BoldWordText(
                        text: (_showNative && widget.exampleNative != null)
                            ? widget.exampleNative!
                            : widget.example!,
                        boldWord: widget.word,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.text,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Synonyms
            if (widget.synonyms != null && widget.synonyms!.isNotEmpty) ...[
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Wrap(
                  key: ValueKey(_showNative),
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: ((_showNative &&
                              widget.synonymsNative != null &&
                              widget.synonymsNative!.isNotEmpty)
                          ? widget.synonymsNative!
                          : widget.synonyms!)
                      .map((s) {
                    final tappable =
                        !_showNative && widget.onSynonymTap != null;
                    return GestureDetector(
                      onTap: tappable ? () => widget.onSynonymTap!(s) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: tappable
                              ? AppColors.accentDim
                              : AppColors.surface2,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: tappable
                                ? AppColors.accent.withAlpha(60)
                                : AppColors.surface3,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            fontSize: 13,
                            color: tappable
                                ? AppColors.accent
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            // Usage notes
            if (widget.usageNotes != null) ...[
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  key: ValueKey(_showNative),
                  (_showNative && widget.usageNotesNative != null)
                      ? widget.usageNotesNative!
                      : widget.usageNotes!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Tap hint
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  size: 14,
                  color: AppColors.textDim.withAlpha(120),
                ),
                const SizedBox(width: 6),
                Text(
                  'Tap to flip back',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textDim.withAlpha(120),
                  ),
                ),
              ],
            ),
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

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          if (idx > 0) TextSpan(text: text.substring(0, idx)),
          TextSpan(
              text: text.substring(idx, idx + boldWord.length), style: bold),
          if (idx + boldWord.length < text.length)
            TextSpan(text: text.substring(idx + boldWord.length)),
        ],
      ),
      textAlign: textAlign,
    );
  }
}
