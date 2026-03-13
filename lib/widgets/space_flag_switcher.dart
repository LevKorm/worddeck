import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_colors.dart';
import '../modules/auth/auth_provider.dart';
import '../modules/spaces/space_provider.dart';

/// Horizontal row of flag buttons for switching between spaces.
/// Returns [SizedBox.shrink] when user has fewer than 2 spaces.
class SpaceFlagSwitcher extends ConsumerWidget {
  const SpaceFlagSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceState = ref.watch(spaceProvider);
    if (spaceState.spaces.length < 2) return const SizedBox.shrink();

    final activeId = spaceState.activeSpaceId;
    final userId = ref.read(currentUserProvider)?.userId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: spaceState.spaces.map((space) {
          final isActive = space.id == activeId;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: isActive || userId == null
                  ? null
                  : () => ref
                      .read(spaceProvider.notifier)
                      .switchSpace(userId, space.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? AppColors.accent.withAlpha(20)
                      : AppColors.surface2,
                  border: Border.all(
                    color: isActive ? AppColors.accent : AppColors.surface3,
                    width: isActive ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    space.learningFlag,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
