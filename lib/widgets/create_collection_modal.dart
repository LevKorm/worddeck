import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_colors.dart';
import '../models/collection.dart';
import 'emoji_picker_field.dart';
import '../modules/auth/auth_provider.dart';
import '../modules/collections/collection_provider.dart';

/// Compact centered modal for quickly creating a new collection.
/// Returns the created collection ID on success, or null if dismissed.
Future<String?> showCreateCollectionModal(
  BuildContext context,
  WidgetRef ref,
) {
  return showDialog<String>(
    context: context,
    builder: (_) => _CollectionModal(ref: ref),
  );
}

/// Opens the same modal pre-filled for editing an existing collection.
Future<void> showEditCollectionModal(
  BuildContext context,
  WidgetRef ref,
  Collection existing,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => _CollectionModal(ref: ref, existing: existing),
  );
}

class _CollectionModal extends StatefulWidget {
  final WidgetRef ref;
  final Collection? existing;
  const _CollectionModal({required this.ref, this.existing});

  @override
  State<_CollectionModal> createState() => _CollectionModalState();
}

class _CollectionModalState extends State<_CollectionModal> {
  late final TextEditingController _nameCtrl;
  late String _emoji;
  late String? _color;
  bool _saving = false;
  bool _showEmojiPicker = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _emoji = widget.existing?.emoji ?? '📚';
    _color = widget.existing?.color ?? Collection.palette[5];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);

    final user = widget.ref.read(currentUserProvider);
    if (user == null) {
      setState(() => _saving = false);
      return;
    }

    if (_isEdit) {
      final updated = widget.existing!.copyWith(
        name: name,
        emoji: _emoji,
        color: _color,
      );
      await widget.ref.read(collectionProvider.notifier).update(updated);
      if (mounted) Navigator.of(context).pop();
    } else {
      final created = await widget.ref.read(collectionProvider.notifier).create(
            userId: user.userId,
            name: name,
            emoji: _emoji,
            color: _color,
          );
      if (mounted) Navigator.of(context).pop(created?.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEdit ? 'Edit collection' : 'New collection',
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text),
            ),
            const SizedBox(height: 16),

            // Emoji + name row
            Row(
              children: [
                EmojiPickerField(
                  emoji: _emoji,
                  onTap: () => setState(() => _showEmojiPicker = !_showEmojiPicker),
                  isExpanded: _showEmojiPicker,
                  size: 44,
                  fontSize: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    autofocus: true,
                    style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.text,
                        fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Collection name',
                      hintStyle: const TextStyle(
                          color: AppColors.textDim, fontSize: 15),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: AppColors.surface2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppColors.radiusSm),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _save(),
                  ),
                ),
              ],
            ),

            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: _showEmojiPicker
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: InlineEmojiPicker(
                        selected: _emoji,
                        onPicked: (e) => setState(() {
                          _emoji = e;
                          _showEmojiPicker = false;
                        }),
                        height: 200,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 14),

            _ColorPalette(
              selected: _color,
              onSelect: (c) => setState(() => _color = c),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_isEdit ? 'Save' : 'Create'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

// ── Color palette ─────────────────────────────────────────────────────────────

class _ColorPalette extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _ColorPalette({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: Collection.palette.map((hex) {
        final isSelected = selected == hex;
        Color c;
        try {
          c = Color(int.parse(hex.replaceFirst('#', '0xFF')));
        } catch (_) {
          c = AppColors.textMuted;
        }
        return GestureDetector(
          onTap: () => onSelect(hex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 26,
            height: 26,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.text : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
