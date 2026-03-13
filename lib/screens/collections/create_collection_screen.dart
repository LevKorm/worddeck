import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/collection.dart';
import '../../widgets/emoji_picker_field.dart';
import '../../modules/auth/auth_provider.dart';
import '../../modules/collections/collection_provider.dart';

/// Full-screen form for creating or editing a collection.
/// Pass [collection] via `extra` to enter edit mode.
class CreateCollectionScreen extends ConsumerStatefulWidget {
  final Collection? collection; // non-null → edit mode
  const CreateCollectionScreen({super.key, this.collection});

  @override
  ConsumerState<CreateCollectionScreen> createState() =>
      _CreateCollectionScreenState();
}

class _CreateCollectionScreenState
    extends ConsumerState<CreateCollectionScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late String _emoji;
  late String? _color;
  bool _saving = false;
  bool _showEmojiPicker = false;

  bool get _isEdit => widget.collection != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.collection?.name ?? '');
    _descCtrl =
        TextEditingController(text: widget.collection?.description ?? '');
    _emoji = widget.collection?.emoji ?? '📚';
    _color = widget.collection?.color ?? Collection.palette[5];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);

    if (_isEdit) {
      final desc = _descCtrl.text.trim();
      final updated = widget.collection!.copyWith(
        name: name,
        emoji: _emoji,
        color: _color,
        description: desc.isEmpty ? null : desc,
        clearDescription: desc.isEmpty,
      );
      await ref.read(collectionProvider.notifier).update(updated);
      if (mounted) context.pop('updated');
    } else {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        setState(() => _saving = false);
        return;
      }

      final created = await ref.read(collectionProvider.notifier).create(
            userId: user.userId,
            name: name,
            emoji: _emoji,
            color: _color,
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
          );

      if (mounted) {
        if (created != null) {
          context.pop(created.id);
        } else {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create collection')),
          );
        }
      }
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete collection'),
        content: Text(
            'Delete "${widget.collection!.name}"? Words will not be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref.read(collectionProvider.notifier).delete(widget.collection!.id);
      if (mounted) context.pop('deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit collection' : 'New collection'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.red),
              onPressed: _delete,
            ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_isEdit ? 'Save' : 'Create'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          // Emoji + name row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EmojiPickerField(
                emoji: _emoji,
                onTap: () => setState(() => _showEmojiPicker = !_showEmojiPicker),
                isExpanded: _showEmojiPicker,
                size: 56,
                fontSize: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Name',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameCtrl,
                      autofocus: !_isEdit,
                      style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.text,
                          fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'e.g. Gaming, Work, Series…',
                        hintStyle: const TextStyle(
                            color: AppColors.textDim, fontSize: 15),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        filled: true,
                        fillColor: AppColors.surface2,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppColors.radiusSm),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Inline emoji picker
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _showEmojiPicker
                ? Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: InlineEmojiPicker(
                      selected: _emoji,
                      onPicked: (e) => setState(() {
                        _emoji = e;
                        _showEmojiPicker = false;
                      }),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 24),

          // Color label
          const Text(
            'Color',
            style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          _ColorGrid(
            selected: _color,
            onSelect: (c) => setState(() => _color = c),
          ),

          const SizedBox(height: 24),

          // Description (optional)
          const Text(
            'Description (optional)',
            style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            style: const TextStyle(fontSize: 14, color: AppColors.text),
            decoration: InputDecoration(
              hintText: 'What words will go here?',
              hintStyle:
                  const TextStyle(color: AppColors.textDim, fontSize: 14),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              filled: true,
              fillColor: AppColors.surface2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppColors.radiusSm),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Preview
          _CollectionPreview(
            emoji: _emoji,
            name: _nameCtrl.text.isEmpty ? 'Collection name' : _nameCtrl.text,
            colorHex: _color,
          ),
        ],
      ),
    );
  }
}

// ── Color grid ────────────────────────────────────────────────────────────────

class _ColorGrid extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _ColorGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
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
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.text : Colors.transparent,
                width: 3,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Preview ───────────────────────────────────────────────────────────────────

class _CollectionPreview extends StatelessWidget {
  final String emoji;
  final String name;
  final String? colorHex;

  const _CollectionPreview({
    required this.emoji,
    required this.name,
    this.colorHex,
  });

  @override
  Widget build(BuildContext context) {
    Color accent = AppColors.accent;
    if (colorHex != null) {
      try {
        accent = Color(int.parse(colorHex!.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(color: AppColors.surface3.withAlpha(128)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withAlpha(35),
              borderRadius: BorderRadius.circular(AppColors.radiusSm),
            ),
            child: Text(emoji, style: AppTheme.emojiStyle.copyWith(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: name == 'Collection name'
                        ? AppColors.textDim
                        : AppColors.text,
                  ),
                ),
                const Text(
                  'Preview',
                  style: TextStyle(fontSize: 12, color: AppColors.textDim),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
