import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/feed_post.dart';
import 'slide_content.dart';

/// Horizontal card carousel with:
/// - Feed mode: AspectRatio(4/5) slide area + action bar below.
/// - Reels mode: SizedBox.expand full-screen + action bar overlaid at bottom.
class FeedCarousel extends StatefulWidget {
  final FeedPost post;
  final bool liked;
  final bool reelsMode;
  final VoidCallback onLike;

  /// Null when already in reels mode (hides expand button).
  final VoidCallback? onOpenReels;

  /// Called when user saves a suggested post to their deck.
  final VoidCallback? onSave;

  final String learningLang;
  final String nativeLang;
  final bool showNative;

  const FeedCarousel({
    super.key,
    required this.post,
    required this.liked,
    this.reelsMode = false,
    required this.onLike,
    this.onOpenReels,
    this.onSave,
    this.learningLang = 'EN',
    this.nativeLang   = 'UK',
    this.showNative   = false,
  });

  @override
  State<FeedCarousel> createState() => _FeedCarouselState();
}

class _FeedCarouselState extends State<FeedCarousel> {
  late final PageController _pageCtrl;
  int  _current = 0;
  bool _saved   = false;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goTo(int idx) {
    _pageCtrl.animateToPage(
      idx,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  void _onSave() {
    setState(() => _saved = true);
    widget.onSave?.call();
  }

  @override
  Widget build(BuildContext context) {
    final slides   = widget.post.slides;
    final total    = slides.isEmpty ? 1 : slides.length;
    final suggested = widget.post.suggested;

    // ── Slide area stack ──────────────────────────────────────────────────────
    final slideStack = Stack(
      fit: StackFit.expand,
      children: [
        // Pages
        slides.isEmpty
            ? const ColoredBox(color: Color(0xFF1A1A2E))
            : PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _current = i),
                itemCount: total,
                itemBuilder: (ctx, i) => SlideContent(
                  slide: slides[i],
                  showNative: widget.showNative,
                  reelsMode: widget.reelsMode,
                  isSuggested: suggested,
                ),
              ),

        // Word label (slides 2+) — top center
        if (widget.post.word != null && _current > 0)
          Positioned(
            top: widget.reelsMode ? 64 : 12,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                widget.post.word!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                ),
              ),
            ),
          ),

        // Progress dots — bottom center (inside slide image)
        if (total > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: _ProgressDots(total: total, current: _current),
          ),

        // Left arrow
        if (_current > 0)
          Positioned(
            left: 6,
            top: 0,
            bottom: 0,
            child: _ArrowBtn(left: true, onTap: () => _goTo(_current - 1)),
          ),

        // Right arrow
        if (_current < total - 1)
          Positioned(
            right: 6,
            top: 0,
            bottom: 0,
            child: _ArrowBtn(left: false, onTap: () => _goTo(_current + 1)),
          ),
      ],
    );

    // ── Reels mode: full-screen with overlaid action bar ──────────────────────
    if (widget.reelsMode) {
      return SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            slideStack,
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _ActionBar(
                reelsMode: true,
                liked: widget.liked,
                saved: _saved,
                onLike: widget.onLike,
                onOpenReels: null,
                onSave: suggested ? _onSave : null,
              ),
            ),
          ],
        ),
      );
    }

    // ── Feed mode: slide only (action bar hidden)
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: slideStack,
    );
  }
}

// ── Progress dots ─────────────────────────────────────────────────────────────

class _ProgressDots extends StatelessWidget {
  final int total;
  final int current;

  const _ProgressDots({required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    if (total <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == current;
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? Colors.white
                : Colors.white.withOpacity(0.25),
          ),
        );
      }),
    );
  }
}

// ── Arrow button ──────────────────────────────────────────────────────────────

class _ArrowBtn extends StatelessWidget {
  final bool left;
  final VoidCallback onTap;

  const _ArrowBtn({required this.left, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            left ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
            size: 22,
            color: Colors.white.withAlpha(70),
            shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
          ),
        ),
      ),
    );
  }
}

// ── Action bar ────────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final bool reelsMode;
  final bool liked;
  final bool saved;
  final VoidCallback onLike;
  final VoidCallback? onOpenReels;
  final VoidCallback? onSave;

  const _ActionBar({
    required this.reelsMode,
    required this.liked,
    required this.saved,
    required this.onLike,
    this.onOpenReels,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(14, 10, 14, reelsMode ? 32 : 10),
      color: reelsMode
          ? Colors.black.withAlpha(160)
          : AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: like + expand
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onLike,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    liked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 20,
                    color: liked ? AppColors.red : AppColors.textMuted,
                  ),
                ),
              ),
              if (!reelsMode && onOpenReels != null) ...[
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: onOpenReels,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Right: save label (suggested posts only)
          if (onSave != null)
            GestureDetector(
              onTap: saved ? null : onSave,
              child: Text(
                saved ? 'Saved ✓' : 'Save',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: saved ? AppColors.accent : AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
