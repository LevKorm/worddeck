import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../models/collection.dart';
import '../../modules/auth/auth_provider.dart';
import '../../modules/collections/collection_provider.dart';
import '../../providers/deck_filter_providers.dart';
import '../../widgets/create_collection_modal.dart';

class ManageCollectionsScreen extends ConsumerWidget {
  const ManageCollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(collectionProvider).collections;
    final allCards = ref.watch(collectionCardCountProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'New collection',
            onPressed: () => showCreateCollectionModal(context, ref),
          ),
        ],
      ),
      body: collections.isEmpty
          ? _EmptyState(onAdd: () => showCreateCollectionModal(context, ref))
          : ReorderableListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              itemCount: collections.length,
              onReorder: (oldIndex, newIndex) =>
                  _onReorder(ref, collections, oldIndex, newIndex),
              itemBuilder: (context, i) {
                final c = collections[i];
                return _CollectionTile(
                  key: ValueKey(c.id),
                  collection: c,
                  onEdit: () => showEditCollectionModal(context, ref, c),
                  onDelete: () =>
                      _confirmDelete(context, ref, c),
                );
              },
            ),
    );
  }

  void _onReorder(
    WidgetRef ref,
    List<Collection> collections,
    int oldIndex,
    int newIndex,
  ) {
    if (newIndex > oldIndex) newIndex--;
    final reordered = [...collections];
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    // Persist updated positions
    final notifier = ref.read(collectionProvider.notifier);
    for (var i = 0; i < reordered.length; i++) {
      final updated = reordered[i].copyWith(position: i);
      notifier.update(updated);
    }
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Collection collection,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${collection.name}"?'),
        content: const Text(
            'The collection will be removed. Cards inside stay in your vocabulary.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              // Reset deck filter if this collection was selected
              if (ref.read(deckCollectionFilterProvider) == collection.id) {
                ref.read(deckCollectionFilterProvider.notifier).state = null;
              }
              ref.read(collectionProvider.notifier).delete(collection.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Collection tile ───────────────────────────────────────────────────────────

class _CollectionTile extends ConsumerWidget {
  final Collection collection;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CollectionTile({
    super.key,
    required this.collection,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardCount = ref.watch(collectionCardCountProvider(collection.id));
    final color = collection.flutterColor ?? AppColors.accent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withAlpha(80)),
            ),
            child: Center(
              child: Text(
                collection.emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          title: Text(
            collection.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          subtitle: Text(
            '$cardCount ${cardCount == 1 ? 'word' : 'words'}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              const Icon(Icons.drag_handle_rounded,
                  color: AppColors.textDim, size: 20),
              const SizedBox(width: 4),
              // Three-dot menu
              PopupMenuButton<_Action>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.textMuted, size: 20),
                color: AppColors.surface2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (action) {
                  if (action == _Action.edit) onEdit();
                  if (action == _Action.delete) onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: _Action.edit,
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined,
                            size: 18, color: AppColors.text),
                        SizedBox(width: 10),
                        Text('Edit', style: TextStyle(color: AppColors.text)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _Action.delete,
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 18,
                            color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 10),
                        Text('Delete',
                            style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 72, color: AppColors.surface3),
      ],
    );
  }
}

enum _Action { edit, delete }

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📂',
              style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'No collections yet',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.text),
          ),
          const SizedBox(height: 8),
          const Text(
            'Group your words into collections\nto stay organised.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('New collection'),
          ),
        ],
      ),
    );
  }
}
