import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Animated shimmer placeholder rectangle used in the translate screen loading state.
///
/// Sweeps a highlight gradient left-to-right with a 1.5s repeat cycle.
class ShimmerWidget extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const ShimmerWidget({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-2.0 + 3.0 * t, 0),
              end: Alignment(-1.0 + 3.0 * t, 0),
              colors: const [
                AppColors.surface2,
                AppColors.surface3,
                AppColors.surface2,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
