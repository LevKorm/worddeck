import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../models/flash_card.dart';
import '../../modules/cards/card_provider.dart';
import '../../modules/spaces/space_provider.dart';
import '../../widgets/word_card_detail.dart';
import 'deck_controller.dart';

class WordDetailScreen extends ConsumerStatefulWidget {
  final FlashCard card;

  const WordDetailScreen({super.key, required this.card});

  @override
  ConsumerState<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends ConsumerState<WordDetailScreen> {
  bool _showNative = false;

  @override
  Widget build(BuildContext context) {
    // Use reactive card so collection changes are reflected immediately.
    final card = ref
            .watch(cardListProvider)
            .allCards
            .where((c) => c.id == widget.card.id)
            .firstOrNull ??
        widget.card;
    final theme = Theme.of(context);
    final activeSpace = ref.watch(activeSpaceProvider);
    final sourceLang = activeSpace?.nativeLanguage ?? 'EN';
    final targetLang = activeSpace?.learningLanguage ?? 'UK';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          card.word,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.copy_rounded,
                size: 20, color: theme.colorScheme.onSurfaceVariant),
            tooltip: 'Copy word',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: card.word));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied to clipboard'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                size: 20, color: theme.colorScheme.error),
            tooltip: 'Delete word',
            onPressed: () => _confirmDelete(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
            bottom: 32 + MediaQuery.of(context).padding.bottom),
        child: WordCardDetail(
          cardContext: WordCardContext.vocabularyDetail,
          word: card.word,
          translation: card.translation ?? '',
          ipa: card.transcription,
          cefrLevel: card.cefrLevel,
          parentWord: card.parentWord,
          status: card.status,
          exampleSentence: card.exampleSentence,
          exampleSentences: card.exampleSentences,
          synonyms: card.synonyms,
          synonymsEnriched: card.synonymsEnriched,
          usageNotes: card.usageNotes,
          usageNotesList: card.usageNotesList,
          grammar: card.grammar,
          exampleNative: card.exampleSentenceNative,
          synonymsNative: card.synonymsNative,
          usageNotesNative: card.usageNotesNative,
          sourceLang: sourceLang,
          targetLang: targetLang,
          fullCard: card,
          collectionId: card.collectionId,
          onCollectionChanged: (id) => ref
              .read(cardListProvider.notifier)
              .updateCardCollection(card.id, id),
          onClose: () => context.pop(),
          showNative: _showNative,
          onNativeChanged: (v) => setState(() => _showNative = v),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete word?'),
        content: Text(
          '\u201c${widget.card.word}\u201d will be permanently removed from your vocabulary.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref.read(deckControllerProvider.notifier).deleteCard(widget.card.id);
      context.pop();
    }
  }
}
