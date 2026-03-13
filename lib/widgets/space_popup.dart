import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../models/space.dart';
import '../modules/auth/auth_provider.dart';
import '../modules/spaces/space_provider.dart';
import 'create_space_dialog.dart';

/// Shows the space switcher popup anchored above [anchorRect].
void showSpacePopup(BuildContext context, WidgetRef ref, Rect anchorRect) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (ctx) => _SpacePopupOverlay(
      anchorRect: anchorRect,
      onDismiss: () => entry.remove(),
      ref: ref,
      parentContext: context,
    ),
  );

  overlay.insert(entry);
}

class _SpacePopupOverlay extends StatelessWidget {
  final Rect anchorRect;
  final VoidCallback onDismiss;
  final WidgetRef ref;
  final BuildContext parentContext;

  const _SpacePopupOverlay({
    required this.anchorRect,
    required this.onDismiss,
    required this.ref,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    final spaceState = ref.read(spaceProvider);
    final activeId = spaceState.activeSpaceId;
    final spaces = spaceState.spaces;

    return Stack(
      children: [
        // Dismiss layer
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDismiss,
            child: const SizedBox.expand(),
          ),
        ),
        // Popup
        Positioned(
          left: anchorRect.left - 20,
          bottom: MediaQuery.of(context).size.height - anchorRect.top + 8,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 260,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                border: Border.all(color: AppColors.surface3, width: 0.5),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 6),
                  ...spaces.map((space) {
                    final isActive = space.id == activeId;
                    return _SpaceRow(
                      space: space,
                      isActive: isActive,
                      onTap: () {
                        onDismiss();
                        if (!isActive) {
                          final userId =
                              ref.read(currentUserProvider)?.userId;
                          if (userId != null) {
                            ref
                                .read(spaceProvider.notifier)
                                .switchSpace(userId, space.id);
                          }
                        }
                      },
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Divider(
                      height: 1,
                      thickness: 0.5,
                      color: AppColors.surface3,
                    ),
                  ),
                  _NewSpaceRow(
                    onTap: () {
                      onDismiss();
                      showCreateSpaceDialog(parentContext);
                    },
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SpaceRow extends StatelessWidget {
  final Space space;
  final bool isActive;
  final VoidCallback onTap;

  const _SpaceRow({
    required this.space,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentDim : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(space.learningFlag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.languageDisplayName(space.learningLanguage),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${space.nativeFlag} ${space.subtitle}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 14, color: Colors.black),
              ),
          ],
        ),
      ),
    );
  }
}

class _NewSpaceRow extends StatelessWidget {
  final VoidCallback onTap;
  const _NewSpaceRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.textDim,
                  width: 1,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: const Icon(Icons.add_rounded,
                  size: 16, color: AppColors.textDim),
            ),
            const SizedBox(width: 10),
            const Text(
              'New space',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
