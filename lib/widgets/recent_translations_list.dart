import 'dart:async';

import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/enrichment_result.dart';
import '../models/translation_result.dart';

// ── Model ──────────────────────────────────────────────────────────────────────

class RecentItem {
  final String word;
  final String translation;
  final bool isSaved;
  final TranslationResult? cachedTranslation;
  final EnrichmentResult? cachedEnrichment;

  const RecentItem({
    required this.word,
    required this.translation,
    this.isSaved = false,
    this.cachedTranslation,
    this.cachedEnrichment,
  });

  RecentItem copyWith({bool? isSaved}) => RecentItem(
        word:              word,
        translation:       translation,
        isSaved:           isSaved ?? this.isSaved,
        cachedTranslation: cachedTranslation,
        cachedEnrichment:  cachedEnrichment,
      );
}

// ── Carousel (main screen) ──────────────────────────────────────────────────

/// Paged auto-scrolling carousel of recent translations.
/// Shows 3 cards per page with a "Recent" arrow card as the last item.
/// Supports velocity-based swiping: slow = one page, fast = jump to end/start.
class RecentCarousel extends StatefulWidget {
  final List<RecentItem> items;
  final ValueChanged<RecentItem> onTap;
  final VoidCallback onSeeAll;

  const RecentCarousel({
    super.key,
    required this.items,
    required this.onTap,
    required this.onSeeAll,
  });

  @override
  State<RecentCarousel> createState() => _RecentCarouselState();
}

class _RecentCarouselState extends State<RecentCarousel>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _dotFillController;
  Timer? _autoScrollTimer;
  Timer? _resumeTimer;
  int _currentPage = 0;

  int get _totalCards => widget.items.length + 1; // +1 for see-all
  int get _totalPages => (_totalCards / 3).ceil();
  bool get _showDots => _totalPages > 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _dotFillController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (_totalPages > 1) _startAutoScroll();
  }

  @override
  void didUpdateWidget(RecentCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      // Reset to page 0 when items change
      if (_currentPage >= _totalPages) {
        _currentPage = 0;
        _pageController.jumpToPage(0);
      }
      if (_totalPages > 1) {
        _startAutoScroll();
      } else {
        _autoScrollTimer?.cancel();
        _dotFillController.reset();
      }
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _resumeTimer?.cancel();
    _dotFillController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _dotFillController.forward(from: 0);
    _dotFillController.addStatusListener(_onDotFillComplete);
  }

  void _onDotFillComplete(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (!mounted) return;
    final next = (_currentPage + 1) % _totalPages;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  void _pauseAutoScroll() {
    _autoScrollTimer?.cancel();
    _dotFillController.removeStatusListener(_onDotFillComplete);
    _dotFillController.stop();
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && _totalPages > 1) _startAutoScroll();
    });
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    // Restart dot fill for new page (if auto-scrolling)
    _dotFillController.removeStatusListener(_onDotFillComplete);
    _dotFillController.forward(from: 0);
    _dotFillController.addStatusListener(_onDotFillComplete);
  }

  void _goToPage(int page) {
    _pauseAutoScroll();
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 64,
          child: GestureDetector(
            onHorizontalDragEnd: _totalPages > 1 ? _onSwipeEnd : null,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: _totalPages > 1
                  ? const ClampingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              itemCount: _totalPages,
              itemBuilder: (context, pageIndex) => _buildPage(pageIndex),
            ),
          ),
        ),
        if (_showDots) ...[
          const SizedBox(height: 10),
          _ProgressDots(
            totalPages: _totalPages,
            currentPage: _currentPage,
            fillController: _dotFillController,
            onDotTap: _goToPage,
          ),
        ],
      ],
    );
  }

  void _onSwipeEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dx;
    final isFast = velocity.abs() > 800;
    final isForward = velocity < 0; // swiping left = forward

    if (isFast) {
      final target = isForward ? _totalPages - 1 : 0;
      _pageController.animateToPage(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
    // Slow swipes are handled by PageView physics

    _pauseAutoScroll();
  }

  Widget _buildPage(int pageIndex) {
    final startIdx = pageIndex * 3;
    final totalWords = widget.items.length;

    final children = <Widget>[];
    for (int i = 0; i < 3; i++) {
      if (i > 0) children.add(const SizedBox(width: 8));
      final cardIdx = startIdx + i;
      if (cardIdx < totalWords) {
        children.add(Expanded(
          child: _CarouselWordCard(
            item: widget.items[cardIdx],
            onTap: () => widget.onTap(widget.items[cardIdx]),
          ),
        ));
      } else if (cardIdx == totalWords) {
        children.add(Expanded(
          child: _SeeAllCard(onTap: widget.onSeeAll),
        ));
      } else {
        children.add(const Expanded(child: SizedBox()));
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: children),
    );
  }
}

// ── Carousel word card ────────────────────────────────────────────────────────

class _CarouselWordCard extends StatelessWidget {
  final RecentItem item;
  final VoidCallback onTap;

  const _CarouselWordCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.surface3.withOpacity(0.5),
            width: 0.5,
          ),
        ),
        child: Stack(
          children: [
            // Saved/unsaved icon top-right
            Positioned(
              top: 0,
              right: 0,
              child: Icon(
                item.isSaved ? Icons.layers_rounded : Icons.layers_outlined,
                size: 14,
                color: item.isSaved ? AppColors.indigo : AppColors.textDim,
              ),
            ),
            // Word + translation
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 18),
                  child: Text(
                    item.word,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.translation,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── See-all card ──────────────────────────────────────────────────────────────

class _SeeAllCard extends StatefulWidget {
  final VoidCallback onTap;
  const _SeeAllCard({required this.onTap});

  @override
  State<_SeeAllCard> createState() => _SeeAllCardState();
}

class _SeeAllCardState extends State<_SeeAllCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = _pressed ? AppColors.accent : AppColors.textDim;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: _pressed ? AppColors.accentDim : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _pressed ? AppColors.accent : AppColors.surface3,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_forward_rounded, size: 18, color: color),
            const SizedBox(height: 3),
            Text(
              'Recent',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Progress dots ─────────────────────────────────────────────────────────────

class _ProgressDots extends StatelessWidget {
  final int totalPages;
  final int currentPage;
  final AnimationController fillController;
  final ValueChanged<int> onDotTap;

  const _ProgressDots({
    required this.totalPages,
    required this.currentPage,
    required this.fillController,
    required this.onDotTap,
  });

  static const _dotSize    = 6.0;
  static const _activeWidth = 20.0;
  static const _dotHeight  = 3.0;
  static const _gap        = 4.0;
  static const _radius     = BorderRadius.all(Radius.circular(1.5));

  static final _brightGrey = Colors.white.withOpacity(0.45);
  static final _darkGrey   = Colors.white.withOpacity(0.12);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (i) {
        if (i > 0) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: _gap),
              _buildDot(i),
            ],
          );
        }
        return _buildDot(i);
      }),
    );
  }

  Widget _buildDot(int index) {
    final isActive = index == currentPage;
    final isPast   = index < currentPage;

    if (isActive) {
      return GestureDetector(
        onTap: () => onDotTap(index),
        child: SizedBox(
          width: _activeWidth,
          height: _dotHeight,
          child: ClipRRect(
            borderRadius: _radius,
            child: Container(
              color: _darkGrey,
              child: AnimatedBuilder(
                animation: fillController,
                builder: (context, _) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fillController.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _brightGrey,
                        borderRadius: _radius,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => onDotTap(index),
      child: Container(
        width: _dotSize,
        height: _dotHeight,
        decoration: BoxDecoration(
          color: isPast ? _brightGrey : _darkGrey,
          borderRadius: _radius,
        ),
      ),
    );
  }
}
