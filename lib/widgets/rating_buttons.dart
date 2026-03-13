import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import '../models/review_rating.dart';

/// The four SM-2 rating buttons shown after revealing a review card.
///
/// [intervals] maps each [ReviewRating] to a human-readable interval preview
/// (e.g. `{ReviewRating.good: '7 days'}`).
class RatingButtons extends StatelessWidget {
  final Map<ReviewRating, String> intervals;
  final ValueChanged<ReviewRating> onRate;

  const RatingButtons({
    super.key,
    required this.intervals,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ReviewRating.values
          .map(
            (rating) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _RatingButton(
                  rating: rating,
                  interval: intervals[rating] ?? '',
                  onTap: () => onRate(rating),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _RatingButton extends StatefulWidget {
  final ReviewRating rating;
  final String interval;
  final VoidCallback onTap;

  const _RatingButton({
    required this.rating,
    required this.interval,
    required this.onTap,
  });

  @override
  State<_RatingButton> createState() => _RatingButtonState();
}

class _RatingButtonState extends State<_RatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    HapticFeedback.lightImpact();
    await _ctrl.forward();
    await _ctrl.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _ratingColor(widget.rating);

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Material(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: color.withAlpha(77)),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.rating.label,
                  style: theme.textTheme.labelLarge?.copyWith(color: color),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.interval,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color.withAlpha(179),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color _ratingColor(ReviewRating r) {
  switch (r) {
    case ReviewRating.again:
      return AppColors.ratingAgain;
    case ReviewRating.hard:
      return AppColors.ratingHard;
    case ReviewRating.good:
      return AppColors.ratingGood;
    case ReviewRating.easy:
      return AppColors.ratingEasy;
  }
}
