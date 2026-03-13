import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/flash_card.dart';
import '../../modules/auth/auth_provider.dart';
import '../../modules/cards/card_provider.dart';
import '../../modules/feed/feed_provider.dart';
import '../../providers/translate_pipeline_provider.dart';
// Feed display imports.
import '../../widgets/feed/feed_post_widget.dart';
// ignore: unused_import
import '../../widgets/feed/reels_mode.dart'; // kept for future use
import '../../modules/collections/collection_provider.dart';
import '../../modules/spaces/space_provider.dart';
import '../../widgets/collection_selector.dart';
import '../../widgets/enrichment_result_card.dart';
import '../../widgets/level_progress_bar.dart';
import '../../widgets/language_selector.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/recent_translations_list.dart';
import '../../widgets/shimmer_widget.dart';
import '../shell/shell_screen.dart';
import 'translate_controller.dart';

// Feed code is kept but not rendered — flip to true to re-enable.
const _kShowFeed = true;

// ── Focus states ───────────────────────────────────────────────────────────────

enum _FocusState { idle, typing, loading, result }

// ── Screen ─────────────────────────────────────────────────────────────────────

class TranslateScreen extends ConsumerStatefulWidget {
  const TranslateScreen({super.key});

  @override
  ConsumerState<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends ConsumerState<TranslateScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  bool _isFocused = false;
  bool _islandVisible = true;
  bool _inFeed = false;
  bool _feedNativePeek = false;
  double _screenHeight = 0;
  String _lastSubmittedText = '';
  Timer? _savedOverlayTimer;
  bool _spoilerOn = false;
  bool _showNative = false;
  String? _saveCollectionId;
  _FocusState _prevFocusState = _FocusState.idle;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pinned = ref.read(pinnedCollectionProvider);
      if (pinned != null && _saveCollectionId == null) {
        setState(() => _saveCollectionId = pinned.id);
      }

      final user = ref.read(currentUserProvider);
      if (user != null) {
        final ctrl = ref.read(translateControllerProvider);
        ref.read(feedProvider.notifier).loadFeed(
          user.userId,
          learningLang: ctrl.targetLang,
          nativeLang: ctrl.sourceLang,
          cardCount: ref.read(cardListProvider).allCards.length,
        );
      }
    });
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final newIslandVisible = offset < 20;
    // Feed starts roughly after the card shell (~75% of screen height)
    final feedThreshold = _screenHeight * 0.6;
    final newInFeed = _screenHeight > 0 && offset > feedThreshold;
    // Reset native peek when scrolling (any movement while peeking)
    final newPeek = _feedNativePeek && offset > feedThreshold;

    if (newIslandVisible != _islandVisible ||
        newInFeed != _inFeed ||
        newPeek != _feedNativePeek) {
      setState(() {
        _islandVisible = newIslandVisible;
        _inFeed = newInFeed;
        _feedNativePeek = newPeek;
      });
    }
  }

  void _resetIslandVisibility() {
    if (!_islandVisible || _inFeed || _feedNativePeek) {
      setState(() {
        _islandVisible = true;
        _inFeed = false;
        _feedNativePeek = false;
      });
    }
  }

  void _onFocusChanged() => setState(() => _isFocused = _focusNode.hasFocus);

  void _onTextChanged() {
    setState(() {});
    final notifier = ref.read(translateControllerProvider.notifier);
    if (_textController.text != _lastSubmittedText) {
      notifier.clearAutoDetected();
    }
    notifier.checkDeckHint(_textController.text);
  }

  @override
  void dispose() {
    _savedOverlayTimer?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _cancelSavedOverlay() {
    _savedOverlayTimer?.cancel();
    _savedOverlayTimer = null;
  }

  Future<void> _submit() async {
    final word = _textController.text.trim();
    if (word.isEmpty) return;
    _cancelSavedOverlay();
    _lastSubmittedText = _textController.text;
    setState(() {
      _spoilerOn = false;
      _showNative = false;
    });
    FocusScope.of(context).unfocus();
    await ref.read(translateControllerProvider.notifier).translate(word);
  }

  Future<void> _retry() async => _submit();

  Future<void> _onSavePressed() async {
    final pipelineTranslation = ref.read(translatePipelineProvider).translation;
    if (pipelineTranslation != null &&
        ref.read(cardListProvider).allCards.any((c) =>
            c.word.toLowerCase() ==
            pipelineTranslation.original.toLowerCase())) {
      return;
    }
    await ref
        .read(translateControllerProvider.notifier)
        .saveToCard(
          collectionId: _saveCollectionId,
          spaceId: ref.read(activeSpaceProvider)?.id,
        );
    if (!mounted) return;
    if (ref.read(translatePipelineProvider).isSaved) {
      _cancelSavedOverlay();
      _savedOverlayTimer = Timer(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        _savedOverlayTimer = null;
        _textController.clear();
        _lastSubmittedText = '';
        ref.read(translateControllerProvider.notifier).skip();
      });
    }
  }

  void _onSkip() {
    _cancelSavedOverlay();
    _textController.clear();
    _lastSubmittedText = '';
    _resetIslandVisibility();
    setState(() {
      _spoilerOn = false;
      _showNative = false;
    });
    ref.read(translateControllerProvider.notifier).skip();
  }

  _FocusState _computeFocusState(TranslatePipelineState pipeline) {
    if (pipeline.hasResult) return _FocusState.result;
    if (pipeline.isLoading) return _FocusState.loading;
    if (_isFocused) return _FocusState.typing;
    return _FocusState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final ctrlState = ref.watch(translateControllerProvider);
    final pipeline = ref.watch(translatePipelineProvider);
    final allCards = ref.watch(cardListProvider).allCards;
    final feedState = _kShowFeed ? ref.watch(feedProvider) : null;

    FlashCard? alreadyInDeckCard;
    if (pipeline.translation != null) {
      final lower = pipeline.translation!.original.toLowerCase();
      for (final c in allCards) {
        if (c.word.toLowerCase() == lower) {
          alreadyInDeckCard = c;
          break;
        }
      }
    }
    final alreadyInDeck = alreadyInDeckCard != null;

    FlashCard? reactiveMatchedCard;
    if (!pipeline.hasResult && _textController.text.trim().isNotEmpty) {
      final typedLower = _textController.text.trim().toLowerCase();
      for (final c in allCards) {
        if (c.word.toLowerCase() == typedLower) {
          reactiveMatchedCard = c;
          break;
        }
      }
    }

    final theme = Theme.of(context);
    final hasText = _textController.text.trim().isNotEmpty;
    final fs = _computeFocusState(pipeline);

    // Save word count snapshot when leaving idle → enables deferred animation
    if (_prevFocusState == _FocusState.idle && fs != _FocusState.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(levelBarSnapshotProvider.notifier).state = allCards.length;
        }
      });
    }
    _prevFocusState = fs;

    final isIdle = fs == _FocusState.idle;
    final isTyping = fs == _FocusState.typing;
    final isResult = fs == _FocusState.result;
    final navVisible = isIdle && !_inFeed;
    final showFeedBelow = _kShowFeed && isIdle;

    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    _screenHeight = screenHeight;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(translateNavHiddenProvider.notifier).state = !navVisible;
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          CustomScrollView(
        controller: _scrollController,
        physics: showFeedBelow
            ? const AlwaysScrollableScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        slivers: [
          // ── Offline banner ───────────────────────────────────────────────
          const SliverToBoxAdapter(child: OfflineBanner()),

          // ── Level progress bar (above card, idle only) ─────────────────
          SliverToBoxAdapter(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: isIdle && _islandVisible
                  ? Padding(
                      padding: EdgeInsets.fromLTRB(
                          24, safeTop + 36, 24, 20),
                      child: const LevelProgressBar(),
                    )
                  : SizedBox(height: safeTop + 40),
            ),
          ),

          // ── Main card shell ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: double.infinity,
              height: isIdle
                  ? screenHeight * 0.78
                  : isTyping
                      ? (keyboardInset > 10
                          ? screenHeight - keyboardInset - safeTop - 40
                          : screenHeight * 0.78)
                      : screenHeight - safeTop - 40,
              child: _buildCardShell(
                fs: fs,
                isIdle: isIdle,
                isTyping: isTyping,
                isResult: isResult,
                alreadyInDeck: alreadyInDeck,
                alreadyInDeckCard: alreadyInDeckCard,
                hasText: hasText,
                ctrlState: ctrlState,
                pipeline: pipeline,
                theme: theme,
                reactiveMatchedCard: reactiveMatchedCard,
                bottomPadding: (isIdle || isTyping)
                    ? 0
                    : safeBottom + 16,
              ),
            ),
          ),

          // ── Auto-detect banner ────────────────────────────────────────────
          if (ctrlState.autoDetectedFrom != null && (isIdle || isTyping))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: _AutoDetectBanner(
                  fromLang: ctrlState.autoDetectedFrom!,
                  toLang: ctrlState.sourceLang,
                  onDismiss: () => ref
                      .read(translateControllerProvider.notifier)
                      .clearAutoDetected(),
                ),
              ),
            ),

          // ── Feed slivers ─────────────────────────────────────────────────
          if (showFeedBelow && feedState != null) ...[
            const SliverToBoxAdapter(child: _PullHandle()),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final post = feedState.posts[i];
                  final user = ref.read(currentUserProvider);
                  final child = FeedPostWidget(
                    post: post,
                    liked: feedState.likedIds.contains(post.id),
                    learningLang: ctrlState.targetLang,
                    nativeLang: ctrlState.sourceLang,
                    showNative: _feedNativePeek,
                    onLike: () {
                      if (user != null) {
                        ref
                            .read(feedProvider.notifier)
                            .toggleLike(user.userId, post.id);
                      }
                    },
                    onOpenReels: () {},
                  );
                  // First post starts at 80% and grows to 100% over 200px of scroll
                  if (i == 0) {
                    return AnimatedBuilder(
                      animation: _scrollController,
                      builder: (ctx, _) {
                        final offset = _scrollController.hasClients
                            ? _scrollController.offset
                            : 0.0;
                        // Scale from 0.8 → 1.0 as scroll goes 0 → 200
                        final t = (offset / 200).clamp(0.0, 1.0);
                        final scale = 0.8 + 0.2 * t;
                        return Transform.scale(
                          scale: scale,
                          alignment: Alignment.topCenter,
                          child: child,
                        );
                      },
                    );
                  }
                  return child;
                },
                childCount: feedState.posts.length,
              ),
            ),
          ],

          // ── Bottom padding sliver ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
                height: showFeedBelow ? 100 + safeBottom : 0),
          ),
        ],
          ),

          // ── Feed overlay buttons (show when in feed) ──────────────────
          // Left: language peek toggle
          Positioned(
            left: 24,
            bottom: safeBottom + 12,
            child: AnimatedOpacity(
              opacity: _inFeed ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 220),
              child: IgnorePointer(
                ignoring: !_inFeed,
                child: _FeedLangButton(
                  // Show the OPPOSITE language's flag — tapping switches to it
                  flag: _feedNativePeek
                      ? AppConstants.flagForCode(ctrlState.targetLang)
                      : AppConstants.flagForCode(ctrlState.sourceLang),
                  label: _feedNativePeek
                      ? AppConstants.languageDisplayName(ctrlState.targetLang)
                      : AppConstants.languageDisplayName(ctrlState.sourceLang),
                  active: _feedNativePeek,
                  onTap: () => setState(() => _feedNativePeek = !_feedNativePeek),
                ),
              ),
            ),
          ),
          // Right: scroll to top
          Positioned(
            right: 24,
            bottom: safeBottom + 12,
            child: AnimatedOpacity(
              opacity: _inFeed ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 220),
              child: IgnorePointer(
                ignoring: !_inFeed,
                child: _FeedScrollTopButton(
                  onTap: () => _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardShell({
    required _FocusState fs,
    required bool isIdle,
    required bool isTyping,
    required bool isResult,
    required bool alreadyInDeck,
    required FlashCard? alreadyInDeckCard,
    required bool hasText,
    required TranslateControllerState ctrlState,
    required TranslatePipelineState pipeline,
    required ThemeData theme,
    required FlashCard? reactiveMatchedCard,
    required double bottomPadding,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).requestFocus(_focusNode),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: switch (fs) {
                  _FocusState.idle || _FocusState.typing => _StageArea(
                      key: const ValueKey('stage'),
                      textController: _textController,
                      focusNode: _focusNode,
                      onSubmit: _submit,
                      hasText: hasText,
                      isTyping: isTyping,
                      recentItems: ctrlState.recentItems,
                      onRecentTap: (item) {
                        _cancelSavedOverlay();
                        _textController.text = item.word;
                        _lastSubmittedText = item.word;
                        FocusScope.of(context).unfocus();
                        if (item.cachedTranslation != null) {
                          ref
                              .read(translateControllerProvider.notifier)
                              .loadFromCache(item);
                        } else {
                          _submit();
                        }
                      },
                      onSeeAll: () => context.push('/recent'),
                      reactiveMatchedCard: reactiveMatchedCard,
                      onLoadDeckCard: () {
                        _cancelSavedOverlay();
                        FocusScope.of(context).unfocus();
                        ref
                            .read(translateControllerProvider.notifier)
                            .loadFromDeckCard(reactiveMatchedCard!);
                      },
                      errorBanner: pipeline.failure != null
                          ? _ErrorBanner(
                              message: pipeline.failure!.message,
                              onRetry: _retry,
                            )
                          : null,
                      selectedCollectionId: _saveCollectionId,
                      onCollectionSelected: (id) =>
                          setState(() => _saveCollectionId = id),
                    ),
                  _FocusState.loading => _buildLoadingContent(),
                  _FocusState.result => SingleChildScrollView(
                      key: const ValueKey('result'),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                            0, MediaQuery.of(context).padding.top + 16, 0, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            EnrichmentResultCard(
                              translation: pipeline.translation!,
                              enrichment: pipeline.enrichment,
                              isEnriching: pipeline.isEnriching,
                              isSaved: pipeline.isSaved,
                              alreadyInDeck: alreadyInDeck,
                              onSave: _onSavePressed,
                              onSkip: _onSkip,
                              showNative: _showNative,
                              onNativeChanged: (v) =>
                                  setState(() => _showNative = v),
                              onDidYouMeanTap: (corrected) {
                                _textController.text = corrected;
                                _lastSubmittedText = corrected;
                                _submit();
                              },
                              collectionId: alreadyInDeck
                                  ? alreadyInDeckCard?.collectionId
                                  : _saveCollectionId,
                              onCollectionChanged: alreadyInDeck
                                  ? (alreadyInDeckCard != null
                                      ? (id) => ref
                                          .read(cardListProvider.notifier)
                                          .updateCardCollection(
                                              alreadyInDeckCard.id, id)
                                      : null)
                                  : (id) =>
                                      setState(() => _saveCollectionId = id),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                },
              ),
            ),
            if (bottomPadding > 0) SizedBox(height: bottomPadding),
          ],
      ),
    );
  }

  Widget _buildLoadingContent() {
    // Card-shaped skeleton that mirrors the TranslationCard layout.
    // No word text — avoids the visible jump from typing (centered) to loading (top).
    return Padding(
      key: const ValueKey('loading'),
      padding: EdgeInsets.fromLTRB(
          0, MediaQuery.of(context).padding.top + 16, 0, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Word + copy button row
            Row(children: [
              const ShimmerWidget(width: 130, height: 32, borderRadius: 8),
              const Spacer(),
              const ShimmerWidget(width: 32, height: 32, borderRadius: 8),
            ]),
            const SizedBox(height: 8),
            // IPA
            const ShimmerWidget(width: 80, height: 14, borderRadius: 6),
            const SizedBox(height: 20),
            // Translation box
            const ShimmerWidget(height: 56, borderRadius: 10),
            const SizedBox(height: 20),
            // Example label
            const ShimmerWidget(width: 70, height: 11, borderRadius: 5),
            const SizedBox(height: 8),
            const ShimmerWidget(height: 14, borderRadius: 6),
            const SizedBox(height: 5),
            const ShimmerWidget(width: 200, height: 14, borderRadius: 6),
            const SizedBox(height: 18),
            // Synonyms label
            const ShimmerWidget(width: 70, height: 11, borderRadius: 5),
            const SizedBox(height: 8),
            Row(children: const [
              ShimmerWidget(width: 62, height: 28, borderRadius: 14),
              SizedBox(width: 6),
              ShimmerWidget(width: 80, height: 28, borderRadius: 14),
              SizedBox(width: 6),
              ShimmerWidget(width: 54, height: 28, borderRadius: 14),
            ]),
            const SizedBox(height: 24),
            // Save button
            const ShimmerWidget(height: 44, borderRadius: 12),
          ],
        ),
      ),
    );
  }
}

// ── Stage area (idle / typing) ─────────────────────────────────────────────────

class _StageArea extends StatelessWidget {
  final TextEditingController textController;
  final FocusNode focusNode;
  final VoidCallback onSubmit;
  final bool hasText;
  final bool isTyping;
  final List<RecentItem> recentItems;
  final ValueChanged<RecentItem> onRecentTap;
  final VoidCallback onSeeAll;
  final FlashCard? reactiveMatchedCard;
  final VoidCallback onLoadDeckCard;
  final Widget? errorBanner;
  final String? selectedCollectionId;
  final ValueChanged<String?> onCollectionSelected;


  const _StageArea({
    super.key,
    required this.textController,
    required this.focusNode,
    required this.onSubmit,
    required this.hasText,
    required this.isTyping,
    required this.recentItems,
    required this.onRecentTap,
    required this.onSeeAll,
    required this.reactiveMatchedCard,
    required this.onLoadDeckCard,
    required this.selectedCollectionId,
    required this.onCollectionSelected,
    this.errorBanner,
  });

  @override
  Widget build(BuildContext context) {
    final inputFontSize = isTyping ? 32.0 : 28.0;
    final hintFontSize = isTyping ? 28.0 : 24.0;

    // Stack layout keeps the TextField at a fixed proportional position
    // (Alignment(0, -0.1) ≈ 45 % from top) regardless of what appears or
    // disappears in the bottom section, eliminating the position jump that
    // occurred with the old flex-zone Column approach.
    return Stack(
      children: [
        // ── Full-area tap zone (behind everything) ────────────────────────
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => focusNode.requestFocus(),
          ),
        ),

        // ── TextField + CollectionSelector — centered as one group ────────
        // They are aligned together so the selector always appears just
        // below the input, and neither jumps when other elements hide/show.
        Positioned.fill(
          child: Align(
            alignment: const Alignment(0, 0.01),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: TextField(
                    controller: textController,
                    focusNode: focusNode,
                    cursorColor: AppColors.accent,
                    style: TextStyle(
                      fontSize: inputFontSize,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'Enter a word\nor a phrase...',
                      hintStyle: TextStyle(
                        fontSize: hintFontSize * 1.2,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDim,
                        height: 1.15,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      isCollapsed: true,
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => onSubmit(),
                  ),
                ),
                // CollectionSelector sits just below the input — hidden while typing
                if (!isTyping) ...[
                  const SizedBox(height: 18),
                  CollectionSelector(
                    selectedId: selectedCollectionId,
                    onSelected: onCollectionSelected,
                  ),
                ],
              ],
            ),
          ),
        ),

        // ── Bottom section — hints + recents ─────────────────────────────
        if (!isTyping)
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (reactiveMatchedCard != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _InDeckHintChip(onTap: onLoadDeckCard),
                  ),
                if (errorBanner != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: errorBanner!,
                  ),
                if (recentItems.isNotEmpty)
                  RecentCarousel(
                    items: recentItems.take(8).toList(),
                    onTap: onRecentTap,
                    onSeeAll: onSeeAll,
                  ),
              ],
            ),
          ),

        // ── Submit button ────────────────────────────────────────────────
        if (hasText)
          Positioned(
            right: 16,
            bottom: 12,
            child: GestureDetector(
              onTap: onSubmit,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.black,
                  size: 22,
                ),
              ),
            ),
          ),
      ],
    );
  }

}

// ── Pull handle ───────────────────────────────────────────────────────────────

class _PullHandle extends StatelessWidget {
  const _PullHandle();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 14),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.textDim.withAlpha(100),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

// ── In-deck hint chip ─────────────────────────────────────────────────────────

class _InDeckHintChip extends StatelessWidget {
  final VoidCallback onTap;
  const _InDeckHintChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.indigoDim,
          borderRadius: BorderRadius.circular(AppColors.radiusFull),
          border: Border.all(color: AppColors.indigo.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.layers_rounded, size: 13, color: AppColors.indigo),
            SizedBox(width: 6),
            Text(
              'Already in your vocabulary — tap to view',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.indigo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Auto-detect banner ────────────────────────────────────────────────────────

class _AutoDetectBanner extends StatelessWidget {
  final String fromLang;
  final String toLang;
  final VoidCallback onDismiss;

  const _AutoDetectBanner({
    required this.fromLang,
    required this.toLang,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final fromName = AppConstants.languageNames[fromLang] ?? fromLang;
    final toName = AppConstants.languageNames[toLang] ?? toLang;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accentGlow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accentDim),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_fix_high_rounded,
              size: 14, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Detected $fromName → translating to $toName',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close_rounded,
                size: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ── Feed overlay: language peek button ────────────────────────────────────────

class _FeedLangButton extends StatelessWidget {
  final String flag;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FeedLangButton({
    required this.flag,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: active
              ? AppColors.accent.withOpacity(0.15)
              : AppColors.bg.withOpacity(0.96),
          borderRadius: BorderRadius.circular(AppColors.radiusFull),
          border: Border.all(
            color: active
                ? AppColors.accent.withOpacity(0.4)
                : AppColors.surface3.withOpacity(0.5),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.accent : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Feed overlay: scroll-to-top button ────────────────────────────────────────

class _FeedScrollTopButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FeedScrollTopButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.bg.withOpacity(0.96),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.surface3.withOpacity(0.5),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: const Icon(
          Icons.keyboard_arrow_up_rounded,
          color: AppColors.textMuted,
          size: 22,
        ),
      ),
    );
  }
}

// ── Error banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.redDim,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.red.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 14, color: AppColors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: AppColors.red),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

