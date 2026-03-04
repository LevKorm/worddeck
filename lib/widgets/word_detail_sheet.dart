import 'package:flutter/material.dart';
import '../models/flash_card.dart';

/// Bottom sheet showing full card details and SM-2 stats.
/// Height: 70%–95% of screen, draggable.
class WordDetailSheet extends StatelessWidget {
  final FlashCard card;
  final VoidCallback onDelete;

  const WordDetailSheet({
    super.key,
    required this.card,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mastery = _masteryLabel(card);
    final masteryColor = _masteryColor(mastery);
    final progress = _masteryProgress(card);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Word + IPA
                    Text(card.word,
                        style: theme.textTheme.displayMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    if (card.transcription != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        card.transcription!,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Badges row
                    Row(
                      children: [
                        _Badge(
                          label: mastery,
                          color: masteryColor,
                        ),
                        const SizedBox(width: 8),
                        _Badge(
                          label: _statusLabel(card.status),
                          color: _statusColor(card.status),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Translation highlight
                    if (card.translation != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withAlpha(15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          card.translation!,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),

                    // Example
                    if (card.exampleSentence != null) ...[
                      const SizedBox(height: 20),
                      _DetailSection(
                        icon: Icons.format_quote_rounded,
                        title: 'Example',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _BoldWordText(
                              text: card.exampleSentence!,
                              boldWord: card.word,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Synonyms
                    if (card.synonyms != null &&
                        card.synonyms!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _DetailSection(
                        icon: Icons.account_tree_rounded,
                        title: 'Synonyms',
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: card.synonyms!
                              .map((s) => Chip(
                                    label: Text(s),
                                    visualDensity: VisualDensity.compact,
                                  ))
                              .toList(),
                        ),
                      ),
                    ],

                    // Usage notes
                    if (card.usageNotes != null) ...[
                      const SizedBox(height: 20),
                      _DetailSection(
                        icon: Icons.lightbulb_outline_rounded,
                        title: 'Usage Notes',
                        child: Text(card.usageNotes!,
                            style: theme.textTheme.bodyMedium),
                      ),
                    ],

                    // Review progress
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    _DetailSection(
                      icon: Icons.bar_chart_rounded,
                      title: 'Review Progress',
                      child: Column(
                        children: [
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor:
                                  masteryColor.withAlpha(38),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  masteryColor),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Stats table
                          _StatRow(
                            label: 'Repetitions',
                            value: '${card.repetitions}',
                          ),
                          _StatRow(
                            label: 'Current interval',
                            value: '${card.intervalDays} days',
                          ),
                          _StatRow(
                            label: 'Ease factor',
                            value: card.easeFactor.toStringAsFixed(2),
                          ),
                          _StatRow(
                            label: 'Next review',
                            value: _fmtDate(card.nextReview),
                          ),
                          _StatRow(
                            label: 'Added',
                            value: _fmtDate(card.createdAt),
                          ),
                        ],
                      ),
                    ),

                    // Delete button
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(
                              color: theme.colorScheme.error.withAlpha(128)),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 18),
                        label: const Text('Delete word'),
                        onPressed: () => _confirmDelete(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete word?'),
        content: Text(
          '"${card.word}" will be permanently removed from your deck.',
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
    if (confirmed == true) {
      onDelete();
    }
  }
}

// ── Badge ──────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Detail section ─────────────────────────────────────────────────────────

class _DetailSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _DetailSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16,
                color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

// ── Stat row ───────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          Text(value, style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }
}

// ── Bold word in example ───────────────────────────────────────────────────

class _BoldWordText extends StatelessWidget {
  final String text;
  final String boldWord;
  final TextStyle? style;

  const _BoldWordText({
    required this.text,
    required this.boldWord,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final idx = text.toLowerCase().indexOf(boldWord.toLowerCase());
    if (idx == -1) return Text(text, style: style);

    final base = style ?? DefaultTextStyle.of(context).style;
    final bold = base.copyWith(fontWeight: FontWeight.bold);

    return RichText(
      text: TextSpan(
        style: base,
        children: [
          if (idx > 0) TextSpan(text: text.substring(0, idx)),
          TextSpan(
              text: text.substring(idx, idx + boldWord.length),
              style: bold),
          if (idx + boldWord.length < text.length)
            TextSpan(text: text.substring(idx + boldWord.length)),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

String _masteryLabel(FlashCard c) {
  if (c.repetitions == 0) return 'New';
  if (c.intervalDays < 7) return 'Learning';
  if (c.intervalDays < 21) return 'Review';
  return 'Mature';
}

Color _masteryColor(String label) {
  switch (label) {
    case 'New':
      return const Color(0xFF6B7280);
    case 'Learning':
      return const Color(0xFFF97316);
    case 'Review':
      return const Color(0xFF8B5CF6);
    case 'Mature':
      return const Color(0xFF22C55E);
    default:
      return const Color(0xFF6B7280);
  }
}

double _masteryProgress(FlashCard c) {
  if (c.repetitions == 0) return 0.0;
  if (c.intervalDays < 7) return 0.25;
  if (c.intervalDays < 21) return 0.6;
  return 1.0;
}

String _statusLabel(CardStatus s) {
  switch (s) {
    case CardStatus.pending:
      return 'Pending';
    case CardStatus.learning:
      return 'Learning';
    case CardStatus.mastered:
      return 'Mastered';
  }
}

Color _statusColor(CardStatus s) {
  switch (s) {
    case CardStatus.pending:
      return const Color(0xFF9CA3AF);
    case CardStatus.learning:
      return const Color(0xFF3B82F6);
    case CardStatus.mastered:
      return const Color(0xFF22C55E);
  }
}

String _fmtDate(DateTime d) {
  const m = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${m[d.month - 1]} ${d.day}, ${d.year}';
}
