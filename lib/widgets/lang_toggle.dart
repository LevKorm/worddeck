import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Pill-style language toggle for switching between learning and native language.
///
/// Renders as a single rounded pill with two tappable segments.
/// Hidden when [hasNativeContent] is false.
class LangToggle extends StatelessWidget {
  final String sourceLang;
  final String targetLang;
  final bool isNative;
  final ValueChanged<bool> onChanged;
  final bool hasNativeContent;

  const LangToggle({
    super.key,
    required this.sourceLang,
    required this.targetLang,
    required this.isNative,
    required this.onChanged,
    required this.hasNativeContent,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasNativeContent) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surface3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Pill(
            label: _label(sourceLang),
            selected: !isNative,
            onTap: () => onChanged(false),
          ),
          _Pill(
            label: _label(targetLang),
            selected: isNative,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }

  static String _label(String langCode) {
    switch (langCode.toUpperCase()) {
      case 'EN':
        return '🇬🇧  EN';
      case 'UK':
      case 'UA':
        return '🇺🇦  UA';
      case 'DE':
        return '🇩🇪  DE';
      case 'FR':
        return '🇫🇷  FR';
      case 'ES':
        return '🇪🇸  ES';
      case 'PL':
        return '🇵🇱  PL';
      default:
        return langCode.toUpperCase();
    }
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.black : AppColors.textMuted,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
