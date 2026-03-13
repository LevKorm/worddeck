import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/deck_filter_providers.dart';

class ViewModeToggle extends StatelessWidget {
  final DeckViewMode mode;
  final ValueChanged<DeckViewMode> onChanged;

  const ViewModeToggle({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surface3, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Btn(
            icon: Icons.crop_square_rounded,
            isActive: mode == DeckViewMode.big,
            onTap: () => onChanged(DeckViewMode.big),
          ),
          _Btn(
            icon: Icons.view_headline_rounded,
            isActive: mode == DeckViewMode.standard,
            onTap: () => onChanged(DeckViewMode.standard),
          ),
          _Btn(
            icon: Icons.notes_rounded,
            isActive: mode == DeckViewMode.stream,
            onTap: () => onChanged(DeckViewMode.stream),
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _Btn({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 28,
        height: 24,
        decoration: BoxDecoration(
          color: isActive ? AppColors.surface3 : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isActive ? AppColors.text : AppColors.textDim,
        ),
      ),
    );
  }
}
