import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../screens/translate/translate_controller.dart';
import '../../widgets/recent_translations_list.dart';

/// Full-page recent search history.
/// Pushed above the shell — has a standard back button.
/// Tapping a word loads it into the translate screen and pops back.
class RecentScreen extends ConsumerStatefulWidget {
  const RecentScreen({super.key});

  @override
  ConsumerState<RecentScreen> createState() => _RecentScreenState();
}

class _RecentScreenState extends ConsumerState<RecentScreen> {
  final Map<String, _PendingDelete> _pendingDeletes = {};

  void _markPendingDelete(RecentItem item) {
    setState(() {
      _pendingDeletes[item.word] = _PendingDelete(item: item);
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _pendingDeletes.containsKey(item.word)) {
        _finalizeDeletion(item.word);
      }
    });
  }

  void _undoDelete(String word) {
    setState(() {
      _pendingDeletes.remove(word);
    });
  }

  void _finalizeDeletion(String word) {
    if (!_pendingDeletes.containsKey(word)) return;
    ref.read(translateControllerProvider.notifier).removeRecent(word);
    if (mounted) {
      setState(() {
        _pendingDeletes.remove(word);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ctrlState = ref.watch(translateControllerProvider);
    final items = ctrlState.recentItems;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Recent',
          style: theme.textTheme.titleMedium,
        ),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () =>
                  ref.read(translateControllerProvider.notifier).clearRecents(),
              child: Text(
                'Clear all',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 48,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No recent searches',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 100 + safeBottom),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, i) {
                final item = items[i];

                // Show undo row in-place for pending deletes
                if (_pendingDeletes.containsKey(item.word)) {
                  return _UndoRow(
                    word: item.word,
                    onUndo: () => _undoDelete(item.word),
                  );
                }

                final card = _RecentWordCard(
                  key: ValueKey('recent_${item.word}'),
                  word: item.word,
                  translation: item.translation,
                  isSaved: item.isSaved,
                  onTap: () {
                    final notifier =
                        ref.read(translateControllerProvider.notifier);
                    if (item.cachedTranslation != null) {
                      notifier.loadFromCache(item);
                    } else {
                      notifier.translate(item.word);
                    }
                    context.pop();
                  },
                );

                return _SwipeToDelete(
                  onDeleted: () => _markPendingDelete(item),
                  child: card,
                );
              },
            ),
    );
  }
}

// ── Recent word card (WordCard proportions) ───────────────────────────────────

class _RecentWordCard extends StatelessWidget {
  final String word;
  final String translation;
  final bool isSaved;
  final VoidCallback onTap;

  const _RecentWordCard({
    super.key,
    required this.word,
    required this.translation,
    required this.isSaved,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.surface3.withOpacity(0.5),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: word + translation
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        word,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        translation,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Bottom: saved indicator
            Row(
              children: [
                if (isSaved) ...[
                  Icon(
                    Icons.layers_rounded,
                    size: 12,
                    color: AppColors.indigo,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'In vocabulary',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.indigo,
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.layers_outlined,
                    size: 12,
                    color: AppColors.textDim,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Not saved',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textDim,
                    ),
                  ),
                ],
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: AppColors.textDim,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Swipe-to-delete ──────────────────────────────────────────────────────────

class _PendingDelete {
  final RecentItem item;
  _PendingDelete({required this.item});
}

class _SwipeToDelete extends StatefulWidget {
  final Widget child;
  final VoidCallback onDeleted;
  const _SwipeToDelete({required this.child, required this.onDeleted});

  @override
  State<_SwipeToDelete> createState() => _SwipeToDeleteState();
}

class _SwipeToDeleteState extends State<_SwipeToDelete>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  late AnimationController _animCtrl;
  Animation<double>? _snapBack;
  VoidCallback? _snapBackListener;
  bool _dismissed = false;
  static const _deleteThreshold = 0.55;
  static const _resistance = 0.35;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails d) {
    if (_dismissed) return;
    final raw = _dragOffset + d.delta.dx;
    if (raw > 0) {
      setState(() => _dragOffset = 0);
      return;
    }
    final width = context.size?.width ?? 300;
    final ratio = (_dragOffset.abs() / width).clamp(0.0, 1.0);
    final dampened = d.delta.dx * (1.0 - ratio * _resistance);
    setState(() {
      _dragOffset = (_dragOffset + dampened).clamp(-width, 0.0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails d) {
    if (_dismissed) return;
    final width = context.size?.width ?? 300;
    final ratio = _dragOffset.abs() / width;

    if (_snapBack != null && _snapBackListener != null) {
      _snapBack!.removeListener(_snapBackListener!);
    }

    if (ratio >= _deleteThreshold) {
      _dismissed = true;
      final startOffset = _dragOffset;
      _snapBack = Tween<double>(begin: startOffset, end: -width)
          .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn));
      _snapBackListener = () => setState(() => _dragOffset = _snapBack!.value);
      _snapBack!.addListener(_snapBackListener!);
      _animCtrl.forward(from: 0).then((_) {
        if (mounted) widget.onDeleted();
      });
    } else {
      final startOffset = _dragOffset;
      _snapBack = Tween<double>(begin: startOffset, end: 0.0).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut),
      );
      _snapBackListener = () {
        if (mounted) setState(() => _dragOffset = _snapBack!.value);
      };
      _snapBack!.addListener(_snapBackListener!);
      _animCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final ratio = (_dragOffset.abs() / width).clamp(0.0, 1.0);
    final showDelete = ratio > 0.05;

    return Stack(
      children: [
        if (showDelete)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Color.lerp(
                  AppColors.red.withOpacity(0.08),
                  AppColors.red.withOpacity(0.25),
                  ratio,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.red.withOpacity(0.5 + ratio * 0.5),
                size: 28,
              ),
            ),
          ),
        GestureDetector(
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          child: Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

// ── Undo row ─────────────────────────────────────────────────────────────────

class _UndoRow extends StatefulWidget {
  final String word;
  final VoidCallback onUndo;
  const _UndoRow({required this.word, required this.onUndo});

  @override
  State<_UndoRow> createState() => _UndoRowState();
}

class _UndoRowState extends State<_UndoRow> {
  int _seconds = 4;
  late final _timer = Timer.periodic(const Duration(seconds: 1), (t) {
    if (!mounted) {
      t.cancel();
      return;
    }
    setState(() => _seconds--);
    if (_seconds <= 0) t.cancel();
  });

  @override
  void initState() {
    super.initState();
    _timer; // start
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.red.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.delete_outline_rounded,
              size: 18, color: AppColors.red.withOpacity(0.6)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '"${widget.word}" removed',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$_seconds',
            style: const TextStyle(
              color: AppColors.textDim,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: widget.onUndo,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Undo',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
