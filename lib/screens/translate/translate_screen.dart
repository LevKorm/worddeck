import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/statistics_provider.dart';
import '../../providers/translate_pipeline_provider.dart';
import '../../widgets/enrichment_result_card.dart';
import '../../widgets/language_selector.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/recent_translations_list.dart';
import '../../widgets/streak_badge.dart';
import '../../widgets/translation_input.dart';
import '../shell/shell_screen.dart';
import 'translate_controller.dart';

class TranslateScreen extends ConsumerStatefulWidget {
  const TranslateScreen({super.key});

  @override
  ConsumerState<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends ConsumerState<TranslateScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final word = _textController.text.trim();
    if (word.isEmpty) return;
    // Dismiss keyboard before translating
    FocusScope.of(context).unfocus();
    await ref.read(translateControllerProvider.notifier).translate(word);
  }

  Future<void> _retry() async {
    await _submit();
  }

  @override
  Widget build(BuildContext context) {
    // Scroll to top when user taps the active Translate tab
    ref.listen(scrollToTopProvider, (_, __) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    final ctrlState = ref.watch(translateControllerProvider);
    final pipeline  = ref.watch(translatePipelineProvider);
    final session   = ref.watch(sessionStatsProvider);

    return LoadingOverlay(
      isLoading: pipeline.isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Translate'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: StreakBadge(streakDays: session.currentStreak),
            ),
          ],
        ),
        body: Column(
          children: [
            // Offline banner at top
            const OfflineBanner(),

            // Main scrollable content
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  // Language selector
                  LanguageSelectorWidget(
                    sourceLang: ctrlState.sourceLang,
                    targetLang: ctrlState.targetLang,
                    onSourceChanged: (lang) => ref
                        .read(translateControllerProvider.notifier)
                        .setSourceLang(lang),
                    onTargetChanged: (lang) => ref
                        .read(translateControllerProvider.notifier)
                        .setTargetLang(lang),
                    onSwap: () => ref
                        .read(translateControllerProvider.notifier)
                        .swapLanguages(),
                  ),
                  const SizedBox(height: 16),

                  // Input field
                  TranslationInputField(
                    controller: _textController,
                    isLoading: pipeline.isLoading,
                    onSubmit: _submit,
                  ),

                  // Error banner with retry
                  if (pipeline.failure != null) ...[
                    const SizedBox(height: 12),
                    _ErrorBanner(
                      message: pipeline.failure!.message,
                      onRetry: _retry,
                    ),
                  ],

                  // Translation result
                  if (pipeline.hasResult) ...[
                    const SizedBox(height: 16),
                    EnrichmentResultCard(
                      translation: pipeline.translation!,
                      enrichment: pipeline.enrichment,
                      isSaved: pipeline.isSaved,
                      onSave: () => ref
                          .read(translateControllerProvider.notifier)
                          .saveToCard(),
                      onSkip: () => ref
                          .read(translateControllerProvider.notifier)
                          .skip(),
                      onCopy: () => Clipboard.setData(
                        ClipboardData(
                          text:
                              '${pipeline.translation!.original} — ${pipeline.translation!.translation}',
                        ),
                      ),
                    ),
                  ],

                  // Recent translations list (only when no active result)
                  if (!pipeline.hasResult && ctrlState.recentItems.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    RecentTranslationsList(
                      items: ctrlState.recentItems,
                      onTap: (word) {
                        _textController.text = word;
                        _submit();
                      },
                      onClear: () => ref
                          .read(translateControllerProvider.notifier)
                          .clearRecents(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorBanner({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: theme.colorScheme.onErrorContainer, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onErrorContainer,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
