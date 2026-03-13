import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/flash_card.dart';

/// CEFR level names for display.
const _cefrNames = {
  'A1': 'Beginner',
  'A2': 'Elementary',
  'B1': 'Intermediate',
  'B2': 'Upper Intermediate',
  'C1': 'Advanced',
  'C2': 'Proficiency',
};

/// CEFR level colors.
const _cefrColors = {
  'A1': Color(0xFF4CAF50),
  'A2': Color(0xFF8BC34A),
  'B1': Color(0xFF2196F3),
  'B2': Color(0xFF9C27B0),
  'C1': Color(0xFFFF9800),
  'C2': Color(0xFFF44336),
};

class CefrAccordionGroup extends StatelessWidget {
  final String level;
  final int count;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child; // The cards list

  const CefrAccordionGroup({
    super.key,
    required this.level,
    required this.count,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final color = _cefrColors[level] ?? AppColors.textMuted;
    final name = _cefrNames[level] ?? level;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.surface3, width: 0.5),
            ),
            child: Row(
              children: [
                // Colored bar
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                // Level label
                Expanded(
                  child: Text(
                    '$level — $name',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ),
                // Count
                Text(
                  '$count',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12,
                    color: AppColors.textDim,
                  ),
                ),
                const SizedBox(width: 8),
                // Chevron
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppColors.textDim,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Body
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: child,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// Groups cards by CEFR level in standard order.
Map<String, List<FlashCard>> groupByCefr(List<FlashCard> cards) {
  const order = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  final grouped = <String, List<FlashCard>>{};
  for (final c in cards) {
    final level = c.cefrLevel ?? 'A1';
    grouped.putIfAbsent(level, () => []).add(c);
  }
  // Return in order, only non-empty groups
  final result = <String, List<FlashCard>>{};
  for (final level in order) {
    if (grouped.containsKey(level)) {
      result[level] = grouped[level]!;
    }
  }
  // Add any unknown levels at the end
  for (final entry in grouped.entries) {
    if (!order.contains(entry.key)) {
      result[entry.key] = entry.value;
    }
  }
  return result;
}
