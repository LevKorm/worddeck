import 'package:flutter/material.dart';
import '../../core/cefr/cefr_level_calculator.dart';
import '../../core/constants/app_colors.dart';

class LevelJourneyList extends StatelessWidget {
  final CefrLevelResult level;

  const LevelJourneyList({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    const levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    final currentIdx = levels.indexOf(level.currentLevel);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'THE JOURNEY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textDim,
                letterSpacing: 1.2,
              ),
            ),
          ),
          for (int i = 0; i < levels.length; i++)
            _CheckpointRow(
              level: levels[i],
              meta: cefrLevelMeta[levels[i]]!,
              state: i < currentIdx
                  ? _CheckpointState.completed
                  : i == currentIdx
                      ? _CheckpointState.current
                      : _CheckpointState.future,
              progressText: i == currentIdx
                  ? '${(level.progress * 100).round()}%'
                  : null,
              isLast: i == levels.length - 1,
              isFirst: i == 0,
            ),
        ],
      ),
    );
  }
}

enum _CheckpointState { completed, current, future }

class _CheckpointRow extends StatelessWidget {
  final String level;
  final CefrMeta meta;
  final _CheckpointState state;
  final String? progressText;
  final bool isLast;
  final bool isFirst;

  const _CheckpointRow({
    required this.level,
    required this.meta,
    required this.state,
    this.progressText,
    required this.isLast,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          // Indicator column with connecting line
          SizedBox(
            width: 32,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Top line
                if (!isFirst)
                  Positioned(
                    top: 0,
                    child: Container(
                      width: 1,
                      height: 13,
                      color: state == _CheckpointState.future
                          ? AppColors.surface3
                          : AppColors.green,
                    ),
                  ),
                // Bottom line
                if (!isLast)
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 1,
                      height: 13,
                      color: state == _CheckpointState.completed
                          ? AppColors.green
                          : AppColors.surface3,
                    ),
                  ),
                // Dot
                _Indicator(state: state),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Level code
          Text(
            level,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: state == _CheckpointState.future
                  ? AppColors.textDim
                  : state == _CheckpointState.current
                      ? AppColors.accent
                      : AppColors.green,
            ),
          ),
          const SizedBox(width: 8),
          // Name
          Expanded(
            child: Text(
              meta.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: state == _CheckpointState.future
                    ? AppColors.textDim
                    : AppColors.text,
              ),
            ),
          ),
          // Right side
          if (state == _CheckpointState.completed)
            const Text(
              '✓ Done',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.green,
              ),
            )
          else if (state == _CheckpointState.current && progressText != null)
            Text(
              progressText!,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
        ],
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  final _CheckpointState state;
  const _Indicator({required this.state});

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case _CheckpointState.completed:
        return Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppColors.green,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
        );
      case _CheckpointState.current:
        return Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      case _CheckpointState.future:
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.surface3, width: 1.5),
          ),
        );
    }
  }
}
