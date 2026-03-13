import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/deck_filter_providers.dart';

class SortFilterDropdown extends StatefulWidget {
  final DeckSortOption sortOption;
  final DeckStatusFilter statusFilter;
  final ValueChanged<DeckSortOption> onSortChanged;
  final ValueChanged<DeckStatusFilter> onStatusChanged;

  const SortFilterDropdown({
    super.key,
    required this.sortOption,
    required this.statusFilter,
    required this.onSortChanged,
    required this.onStatusChanged,
  });

  @override
  State<SortFilterDropdown> createState() => _SortFilterDropdownState();
}

class _SortFilterDropdownState extends State<SortFilterDropdown> {
  OverlayEntry? _overlay;
  final _triggerKey = GlobalKey();

  void _toggle() {
    if (_overlay != null) {
      _dismiss();
    } else {
      _show();
    }
  }

  void _dismiss() {
    _overlay?.remove();
    _overlay = null;
  }

  void _show() {
    final box = _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);
    final size = box.size;

    _overlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _dismiss,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: pos.dx,
            top: pos.dy + size.height + 6,
            child: _DropdownMenu(
              sortOption: widget.sortOption,
              statusFilter: widget.statusFilter,
              onSortChanged: (v) {
                widget.onSortChanged(v);
                _dismiss();
              },
              onStatusChanged: (v) {
                widget.onStatusChanged(v);
                _dismiss();
              },
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  @override
  void dispose() {
    _dismiss();
    super.dispose();
  }

  String get _label {
    final sort = widget.sortOption == DeckSortOption.dateAdded
        ? 'Newest'
        : widget.sortOption == DeckSortOption.alphabetical
            ? 'A → Z'
            : widget.sortOption.label;
    if (widget.statusFilter != DeckStatusFilter.all) {
      return '$sort · ${widget.statusFilter.label}';
    }
    return sort;
  }

  bool get _hasFilter => widget.statusFilter != DeckStatusFilter.all;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _triggerKey,
      onTap: _toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _hasFilter ? AppColors.accentDim : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: _hasFilter ? AppColors.accent : AppColors.surface3,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _hasFilter ? AppColors.accent : AppColors.textDim,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: _hasFilter ? AppColors.accent : AppColors.textDim,
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownMenu extends StatelessWidget {
  final DeckSortOption sortOption;
  final DeckStatusFilter statusFilter;
  final ValueChanged<DeckSortOption> onSortChanged;
  final ValueChanged<DeckStatusFilter> onStatusChanged;

  const _DropdownMenu({
    required this.sortOption,
    required this.statusFilter,
    required this.onSortChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 190,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surface3, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SORT BY section
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 6),
              child: Text(
                'SORT BY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDim,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            _RadioItem(
              label: 'Newest first',
              isActive: sortOption == DeckSortOption.dateAdded,
              onTap: () => onSortChanged(DeckSortOption.dateAdded),
            ),
            _RadioItem(
              label: 'Alphabetical',
              isActive: sortOption == DeckSortOption.alphabetical,
              onTap: () => onSortChanged(DeckSortOption.alphabetical),
            ),
            // Divider
            Container(
              height: 0.5,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
              color: AppColors.surface3,
            ),
            // SHOW section
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 6),
              child: Text(
                'SHOW',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDim,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            for (final f in DeckStatusFilter.values)
              _RadioItem(
                label: f.label,
                isActive: statusFilter == f,
                onTap: () => onStatusChanged(f),
              ),
          ],
        ),
      ),
    );
  }
}

class _RadioItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _RadioItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isActive ? AppColors.accent : AppColors.textMuted,
              ),
            ),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? AppColors.accent : AppColors.surface3,
                  width: 1.5,
                ),
              ),
              child: isActive
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
