import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../modules/collections/collection_provider.dart';

/// Compact collection picker: [folder icon + name + chevron] [× clear]
///
/// [openUpward] — dropdown appears above the trigger (default: false = below).
/// [alignLeft]  — dropdown left-aligns with the trigger (default: false = center).
class CollectionSelector extends ConsumerStatefulWidget {
  final String? selectedId;
  final ValueChanged<String?> onSelected;
  final bool openUpward;
  final bool alignLeft;

  const CollectionSelector({
    super.key,
    required this.selectedId,
    required this.onSelected,
    this.openUpward = false,
    this.alignLeft = false,
  });

  @override
  ConsumerState<CollectionSelector> createState() =>
      _CollectionSelectorState();
}

class _CollectionSelectorState extends ConsumerState<CollectionSelector>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _entry;
  late final AnimationController _chevronCtrl;

  bool get _isOpen => _entry != null;

  @override
  void initState() {
    super.initState();
    _chevronCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _entry?.remove();
    _chevronCtrl.dispose();
    super.dispose();
  }

  void _toggle(BuildContext context) {
    if (_isOpen) {
      _close();
    } else {
      _open(context);
    }
  }

  void _open(BuildContext context) {
    _chevronCtrl.forward();
    final overlay = Overlay.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    _entry = OverlayEntry(
      builder: (_) => _DropdownOverlay(
        link: _layerLink,
        minWidth: screenWidth * 0.55,
        selectedId: widget.selectedId,
        openUpward: widget.openUpward,
        alignLeft: widget.alignLeft,
        onSelect: (id) {
          widget.onSelected(id);
          _close();
        },
        onDismiss: _close,
        onAdd: () {
          _close();
          context.push('/collections/new');
        },
      ),
    );
    overlay.insert(_entry!);
    setState(() {});
  }

  void _close() {
    _chevronCtrl.reverse();
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final collections = ref.watch(collectionProvider).collections;
    final selected =
        collections.where((c) => c.id == widget.selectedId).firstOrNull;
    final hasSelection = selected != null;
    final label = selected?.name ?? 'No collection';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Trigger
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: () => _toggle(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surface3),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder_rounded,
                    size: 14,
                    color: hasSelection
                        ? AppColors.accent
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: hasSelection
                            ? AppColors.text
                            : AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 0.5)
                        .animate(CurvedAnimation(
                      parent: _chevronCtrl,
                      curve: Curves.easeInOut,
                    )),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Clear button — only when something is selected
        if (hasSelection) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => widget.onSelected(null),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface2,
                border: Border.all(color: AppColors.surface3),
              ),
              child: const Center(
                child: Icon(
                  Icons.close_rounded,
                  size: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Dropdown overlay ──────────────────────────────────────────────────────────

class _DropdownOverlay extends ConsumerWidget {
  final LayerLink link;
  final double minWidth;
  final String? selectedId;
  final bool openUpward;
  final bool alignLeft;
  final ValueChanged<String?> onSelect;
  final VoidCallback onDismiss;
  final VoidCallback onAdd;

  const _DropdownOverlay({
    required this.link,
    required this.minWidth,
    required this.selectedId,
    required this.openUpward,
    required this.alignLeft,
    required this.onSelect,
    required this.onDismiss,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(collectionProvider).collections;

    // Anchor points depend on open direction and alignment
    final Alignment targetAnchor = openUpward
        ? (alignLeft ? Alignment.topLeft : Alignment.topCenter)
        : (alignLeft ? Alignment.bottomLeft : Alignment.bottomCenter);
    final Alignment followerAnchor = openUpward
        ? (alignLeft ? Alignment.bottomLeft : Alignment.bottomCenter)
        : (alignLeft ? Alignment.topLeft : Alignment.topCenter);
    final Offset offset = Offset(0, openUpward ? -6 : 6);

    return Stack(
      children: [
        // Transparent backdrop
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.translucent,
          ),
        ),

        // Floating dropdown anchored to trigger
        CompositedTransformFollower(
          link: link,
          showWhenUnlinked: false,
          targetAnchor: targetAnchor,
          followerAnchor: followerAnchor,
          offset: offset,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(
                minWidth: minWidth,
                maxWidth: minWidth * 1.4,
                maxHeight: 300,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.surface3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DropItem(
                          label: 'No collection',
                          color: AppColors.textMuted,
                          isSelected: selectedId == null,
                          onTap: () => onSelect(null),
                        ),
                        ...collections.map((c) => _DropItem(
                              label: c.name,
                              emoji: c.emoji,
                              color: c.flutterColor ?? AppColors.accent,
                              isSelected: selectedId == c.id,
                              onTap: () => onSelect(c.id),
                            )),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Divider(
                            color: AppColors.surface3,
                            height: 1,
                            thickness: 1,
                          ),
                        ),
                        _DropItem(
                          label: '+ Create new collection',
                          color: AppColors.accent,
                          isSelected: false,
                          onTap: onAdd,
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Item ──────────────────────────────────────────────────────────────────────

class _DropItem extends StatelessWidget {
  final String label;
  final String? emoji;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final bool bold;

  const _DropItem({
    required this.label,
    this.emoji,
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isSelected ? AppColors.accent : color;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: AppTheme.emojiStyle.copyWith(fontSize: 14)),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: (isSelected || bold) ? FontWeight.w600 : FontWeight.w400,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
