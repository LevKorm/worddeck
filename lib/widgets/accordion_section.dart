import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// A single accordion item with animated expand/collapse.
class AccordionItem extends StatefulWidget {
  final String label;
  final int? count;
  final bool initiallyExpanded;
  final Widget child;
  final bool showDivider;

  const AccordionItem({
    super.key,
    required this.label,
    this.count,
    this.initiallyExpanded = false,
    required this.child,
    this.showDivider = true,
  });

  @override
  State<AccordionItem> createState() => _AccordionItemState();
}

class _AccordionItemState extends State<AccordionItem>
    with SingleTickerProviderStateMixin {
  late bool _expanded = widget.initiallyExpanded;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
    value: widget.initiallyExpanded ? 1.0 : 0.0,
  );
  late final Animation<double> _heightFactor = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                // Dot + label
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppColors.textDim,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                if (widget.count != null) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${widget.count}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDim,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                // Arrow button
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      Icons.expand_more,
                      size: 16,
                      color: AppColors.textDim,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Body
        ClipRect(
          child: AnimatedBuilder(
            animation: _heightFactor,
            builder: (context, child) {
              return Align(
                alignment: Alignment.topCenter,
                heightFactor: _heightFactor.value,
                child: child,
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: widget.child,
            ),
          ),
        ),
        // Divider
        if (widget.showDivider)
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.04),
          ),
      ],
    );
  }
}

/// Container for accordion content items (example text, usage note, etc.)
class AccordionContentCard extends StatelessWidget {
  final Widget child;
  final bool isLast;

  const AccordionContentCard({
    super.key,
    required this.child,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}
