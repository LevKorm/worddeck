# WordDeck — Claude Code Reference

## What it is
Flutter flashcard app for language learning. Users translate words (DeepL), get AI enrichment (Gemini), save as flashcards, review via SM-2 spaced repetition. Has an Instagram-style Discovery Feed that generates carousel posts for every saved word. Synonym chips on cards are tappable — they open a translate+enrich sheet to save the synonym as a linked child card.

## Key facts
- Flutter 3.41.3 + Riverpod 2.5 (`StateNotifierProvider` throughout, no `AsyncNotifier`) + GoRouter 14
- Supabase backend (DB + Auth + Edge Functions + RLS)
- Deployed as Flutter web on Vercel — live at **https://worddeck.vercel.app**
- Auth: Google OAuth only — PKCE on web, implicit on mobile
- JWT auth **enabled** on all 4 edge functions — return 401 if `Authorization: Bearer <token>` missing
- All functions deployed with `--no-verify-jwt` — gateway does NOT verify JWT signature; in-function Bearer check is the guard. Prevents 401s from expired/refreshing tokens.
- `user_id` in all edge functions comes from JWT `sub` claim, never from request body
- Config loaded from `.env` via `flutter_dotenv` → `AppConstants`

## Deploy commands
```bash
# Web (must run vercel from build/web, NOT project root)
flutter build web --release && cd build/web && ~/.npm-global/bin/vercel --prod --yes

# Edge functions
supabase functions deploy translate-gemini --project-ref kzvzrmmfgrcacycindnp --no-verify-jwt
supabase functions deploy enrich --project-ref kzvzrmmfgrcacycindnp --no-verify-jwt
supabase functions deploy generate-feed --project-ref kzvzrmmfgrcacycindnp --no-verify-jwt
supabase functions deploy generate-suggestions --project-ref kzvzrmmfgrcacycindnp --no-verify-jwt
```

## Supabase
- Project ref: `kzvzrmmfgrcacycindnp`
- URL: `https://kzvzrmmfgrcacycindnp.supabase.co`
- Anon key format: `sb_publishable_*` — NOT a JWT, do not use as Bearer token manually

## Database schema (key tables)
```
cards
  id uuid PK, user_id uuid FK, word text, translation text,
  transcription text, example_sentence text, synonyms text[],
  usage_notes text, example_sentence_native text,
  synonyms_native text[], usage_notes_native text,
  parent_card_id uuid FK cards(id) ON DELETE SET NULL,  ← migration 003
  parent_word text,                                      ← migration 003
  word_lang text,                                        ← migration 007
  translation_lang text,                                 ← migration 007
  status text (pending/learning/mastered),
  ease_factor float, interval_days int, repetitions int,
  next_review timestamptz, created_at timestamptz

card_feed_content
  id uuid PK, user_id uuid FK, card_id uuid FK (nullable for suggested),
  word text, slides jsonb[], status text (ready/failed/pending),
  suggested bool, suggest_reason jsonb,
  liked bool, generated_at timestamptz

user_settings
  user_id uuid PK, native_language text, learning_language text,
  notif_enabled bool, notif_min_hour int, notif_max_hour int,
  notif_frequency text, push_subscription jsonb,
  created_at timestamptz, notif_last_sent timestamptz
```

Migrations applied in order:
1. (initial schema — not in migrations folder)
2. `002_native_language_fields.sql`
3. `003_parent_card_fields.sql`
4. `004_collections.sql` — collections table + collection_id FK on cards
5. `005_spaces.sql` — spaces table
6. `006_cefr_level.sql` — cefr_level text column on cards
7. `007_word_lang_fields.sql` — word_lang, translation_lang text columns on cards
8. `008_grammar_synonyms_fields.sql` — grammar jsonb, synonyms_enriched jsonb, example_sentences text[], usage_notes_list text[] (PENDING — apply in dashboard)

## Patterns — always follow these

**Riverpod:** `StateNotifierProvider` everywhere. No `AsyncNotifier`. State via `copyWith`.

**UserProfile:** primary key field is `userId` (not `id`). Always use `user.userId`.

**Optimistic updates** (cards + feed likes):
1. Patch in-memory state immediately
2. Write cache immediately (cards only)
3. Fire-and-forget Supabase: `.then<void>((_) {}, onError: (_) {})`

**Fire-and-forget Supabase Functions:**
```dart
_supabase.functions.invoke('fn-name', body: {...}).ignore();
```

**Stale-while-revalidate** (cards AND feed):
1. Emit SharedPreferences cache immediately → no spinner for returning users
2. Fetch Supabase in background → overwrite state + update cache
- `CardCache` — caches all cards per user (`cards_v1_{userId}`)
- `FeedCache` — caches only user's own (non-suggested) posts (`feed_cache_{userId}`)

**No await on review ratings** — `rate()` in `review_provider.dart` is sync void. Delegates write to `updateCard()` which is already optimistic.

**Feed generation after save** — both `translate_pipeline_provider.dart` and `synonym_card_sheet.dart` fire `triggerFeedGeneration()` after every successful `saveCard()`. Languages come from `currentUserProvider` — never hardcoded.

**Enrichment interface** — `enrichmentServiceProvider` returns `IEnrichmentService`. The interface now includes `enrichWithTranslation()` — **no cast needed**:
```dart
// Correct:
ref.read(enrichmentServiceProvider).enrichWithTranslation(word: ..., translation: ..., sourceLang: ..., targetLang: ...)
// Do NOT do this (outdated):
ref.read(enrichmentServiceProvider) as GeminiEnrichmentService
```

## Architecture layers
```
contracts/          Pure Dart interfaces (ICardRepository, IFeedRepository, IEnrichmentService, etc.)
modules/            Business logic + Riverpod providers (one folder per domain)
  auth/             SupabaseAuthService, auth_provider.dart
  cards/            CardListNotifier, SupabaseCardRepository, card_provider.dart
  enrichment/       GeminiEnrichmentService, enrichment_provider.dart
  feed/             FeedNotifier(repo, cache), FeedMixer, SupabaseFeedRepository, feed_provider.dart
  review/           SM2Engine, review_provider.dart
  translation/      DeepLTranslationService, translation_provider.dart
  notifications/    Firebase push (lazy-guarded, not fully configured — skips silently, logs in debug)
providers/          Cross-cutting providers
  translate_pipeline_provider.dart  ← orchestrates translate→enrich→save→feed trigger
  connectivity_provider.dart        ← isOfflineProvider (bool), connectivityProvider (stream)
  statistics_provider.dart          ← fullStatisticsProvider
  synonym_children_provider.dart    ← synonymChildrenProvider.family(cardId) → Set<String>
  theme_provider.dart
screens/            UI + screen-level controllers
  shell/            ShellScreen (bottom nav, eager card load, notif permission)
  translate/        TranslateScreen, TranslateController
  deck/             DeckScreen, DeckController
  review/           ReviewScreen, ReviewController
  stats/            StatsScreen, StatsController
  settings/         SettingsScreen, SettingsController
  auth/             Auth screens
widgets/            Reusable UI
  feed/             All feed components (carousel, slides, reels, theme, video placeholder)
  deck/             Vocabulary screen components (cefr_milestone_bar, collection_tabs, sort_filter_dropdown, view_mode_toggle, cefr_accordion, big_word_card, stream_word_row)
  stats/            Stats screen components (level_hero_card, level_journey_list, level_tips_card)
  synonym_card_sheet.dart  ← translate+enrich bottom sheet for synonym cards
  word_card_detail.dart    ← unified card detail (WordCardContext enum: translateResult/inDeck/vocabularyDetail/synonymSheet)
  accordion_section.dart   ← animated expand/collapse sections (AccordionItem + AccordionContentCard)
  translation_card.dart    ← search result card
  enrichment_result_card.dart  ← thin adapter: TranslationResult+EnrichmentResult → WordCardDetail
  review_card.dart         ← 3D flip flashcard
  word_card.dart           ← deck list tile
models/             Pure data classes (fromJson/toJson/copyWith)
core/
  cache/            CardCache, FeedCache (SharedPreferences SWR)
  cefr/             CefrLevelCalculator (weighted scoring, level thresholds, CefrMeta)
  constants/        AppConstants (env vars, lang codes, SM-2 defaults), LevelDefinitions (14-level progression)
  errors/           AppException, Failure types
  theme/            AppTheme
  network/          (http utils)
```

## Key providers
| Provider | Type | What it does |
|---|---|---|
| `currentUserProvider` | `UserProfile?` | Current auth state |
| `cardListProvider` | `CardListState` | All cards, stale-while-revalidate |
| `translatePipelineProvider` | `TranslatePipelineState` | translate → enrich → save pipeline |
| `feedProvider` | `FeedState` | Posts, filter, liked IDs — SWR from FeedCache |
| `feedRepositoryProvider` | `IFeedRepository` | Supabase feed repo |
| `feedCacheProvider` | `FeedCache` | SharedPreferences cache for feed posts |
| `synonymChildrenProvider(cardId)` | `Set<String>` | Words already saved as children of a card |
| `isOfflineProvider` | `bool` | Synchronous offline check |
| `scrollToTopProvider` | `int` | Shell tab double-tap → scroll to top signal |
| `cefrLevelProvider` | `CefrLevelResult` | Weighted CEFR level from card mastery |
| `cefrBreakdownProvider` | `Map<String, int>` | Card count per CEFR level |
| `deckViewModeProvider` | `DeckViewMode` | Big/standard/stream view mode |
| `deckCefrGroupingProvider` | `bool` | CEFR accordion grouping toggle |

## Unified WordCardDetail widget
`lib/widgets/word_card_detail.dart` — single widget for all card detail views, driven by `WordCardContext` enum:
- `translateResult` — fresh translation result (save button, no review stats)
- `inDeck` — word already in vocabulary (blue "Already in vocabulary" hint)
- `vocabularyDetail` — full card detail from deck (review stats, collection selector, swap button)
- `synonymSheet` — synonym bottom sheet (save button, "from X" badge)

Sections: Word Box (word+IPA+CEFR+status+translation with spoiler), Synonyms Box (chips with CEFR), Accordion (Examples/Usage/Grammar via `AccordionSection`), Bottom Controls, Review Progress.

New enrichment fields on `FlashCard` + `EnrichmentResult`:
- `grammar` (`Map<String, dynamic>?`) — type, pattern, related forms
- `synonymsEnriched` (`List<Map<String, String>>?`) — word + CEFR level per synonym
- `exampleSentences` (`List<String>?`) — multiple example sentences
- `usageNotesList` (`List<String>?`) — multiple usage notes

## Synonym-to-Card feature
Tapping a synonym chip creates a new card linked to the parent.

- `synonym_card_sheet.dart` — `showSynonymCardSheet(context, ref, synonym, sourceLang, targetLang, {parentCardId, parentWord})` — runs translate→enrich, shows result, saves with parent link, **then fires `triggerFeedGeneration` for the new card**
- `synonym_children_provider.dart` — `Provider.family<Set<String>, String>` watches `cardListProvider.allCards` and returns the set of lowercased words already saved as children of a given card ID
- `word_detail_sheet.dart` — `ConsumerStatefulWidget`; synonym chips are `ActionChip` with accent color + checkmark if already saved as child; shows "From 'word'" breadcrumb if card has `parentWord`
- `translation_card.dart` — has `onSynonymTap(String)?` callback; passes `ActionChip` when set
- `enrichment_result_card.dart` — `ConsumerWidget`; wires `onSynonymTap` → `showSynonymCardSheet`
- `review_card.dart` — has `onSynonymTap(String)?` callback; `review_screen.dart` wires it with `card.id` as parent
- `FlashCard` model has `parentCardId` and `parentWord` nullable fields
- `SupabaseCardRepository.saveCard()` includes `parent_card_id` and `parent_word` in insert

## Feed system
- `card_feed_content` table — stores generated slide posts per user (`status`: ready/failed/pending)
- `generate-feed` edge function — Gemini slides for one card word; **never writes failed rows** — returns error response only
- `generate-suggestions` edge function — system suggestions (wordOfDay, essential, related, completeSet, commonlyConfused)
- `FeedMixer.mixFeed(userPosts, suggestedPosts, cardCount)` — interleaves at ratio 1:1 / 1:3 / 1:5
- `FeedNotifier.loadFeed(userId, learningLang, nativeLang, {cardCount})` — SWR cache first, then fetch; cleans failed rows; passes `cardCount` to skip DB count call
- `backfillFeedPosts` — processes cards in **batches of 3** with 1s gap (not unbounded concurrent)
- `deleteFailedFeedRows(userId)` — called fire-and-forget on every `loadFeed` to clean up stale failed rows
- 12 generatable slide types: hero, etymology, sentences, funFact, synonymCloud, miniStory, wordFamily, collocations, grammar, commonMistakes, formalityScale, idioms
- 4 special/placeholder types: compareHero, compareGrid, themeHero, video (never generated by per-word prompt)
- All slide widgets share the same constructor: `content`, `extra?`, `showNative`, `reelsMode`
- Gemini prompt now has explicit `extra` JSON schemas for all 12 generatable types

## Feed language resolution
Edge functions `generate-feed` and `generate-suggestions`:
1. Accept `target_lang` / `native_lang` from request body (optional)
2. If missing, look up from `user_settings` table using the authenticated `user_id`
3. Fall back to `EN` / `UK` only if user has no settings row at all

Flutter side: `triggerFeedGeneration(userId, cardId, {targetLang, nativeLang})` — always passes user's `learningLanguage` / `nativeLanguage` from `currentUserProvider`.

## Feed carousel UI
- `FeedPostWidget` — card container: `Container(margin: h16/v6, borderRadius: 16, border: surface3 0.5px, clipBehavior: antiAlias)` wrapping `FeedCarousel`
- `FeedCarousel` — feed mode: `Column(AspectRatio(4/5) slide area + _ActionBar below)`; reels mode: `SizedBox.expand` with `_ActionBar` overlaid at bottom
- Progress dots (`_ProgressDots`) inside slide area as `Positioned(bottom:16)` — NOT in action bar
- Word label on slides 2+ at top center (`Positioned top: 64` reels / `top: 12` normal) — inside slide area Stack
- `_ActionBar` — feed mode below slide: heart icon + expand icon (left) | "Save"/"Saved ✓" text (right, suggested posts only)
- Lang toggle removed from carousel — slides always render `showNative: false`
- `ReelsMode` — vertical `PageView` for full-screen Instagram-style scroll; floating close button; `SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky)`

## Feed slide design system
- `lib/core/theme/feed_slide_gradients.dart` — `FeedSlideGradients` abstract class with 13 dark `LinearGradient` constants (hero/etymology/sentences/funFact/synonymCloud/miniStory/wordFamily/collocations/grammar/commonMistakes/formalityScale/idioms/suggestion) + `forType(String)` lookup
- `FeedSlideFrame` — simplified: just `Container(decoration: BoxDecoration(gradient: gradient), child: child)`; sizing fully handled by parent
- `FeedTheme.typeLabelStyle` — shared `TextStyle` for slide type labels: 11px, w600, letterSpacing 1.2, white@35% (`0x59FFFFFF`)
- Every slide widget: wraps content in `Stack(fit: StackFit.expand)` with `Positioned(top:16, left:16)` type label + `Padding(fromLTRB(24,52,24,48))` content column
- `HeroSlide` redesign: word centered (34px bold white, scales to 24px for long phrases) + translation below (17px white@50%); suggested posts use `suggestion` gradient + "SUGGESTION" label with `Icons.auto_awesome_rounded`

## Navigation structure
- **3 shell tabs**: Translate (`/`), Vocabulary (`/deck`), Review (`/review`)
- **Pushed above shell** (no bottom nav): `/settings`, `/stats`, `/stats/achievements`, `/recent`
- Settings icon on every tab (`AppColors.textMuted` color) → `context.push('/settings')`
- Stats page reached by tapping: stat pills (Translate), word count badge (Vocabulary)
- Recent history page at `/recent` — full list with back button

## Bottom navigation (FloatingPillNav)
`ShellScreen` uses a `Stack` body — **no** `Scaffold.bottomNavigationBar`:
```
Scaffold(body: Stack([
  Positioned.fill → navigationShell,
  Positioned(bottom:0, height:110) → IgnorePointer fade gradient (bg transparent→bg),
  Positioned(left:0, right:0, bottom: safeArea+12) → Center → AnimatedOpacity → FloatingPillNav,
]))
```
`FloatingPillNav` (`lib/widgets/nav_bar.dart`):
- Outer `Container`: `surface3` 0.5px border + drop shadow
- `ClipRRect(999)` → `BackdropFilter(blur:24)` → inner `Container(surface@93%, v:8/h:8 padding)` → `Row(mainAxisSize:min, gaps:8px)` of 3 `_NavItem`
- `_NavItem`: `AnimatedContainer(duration:200ms, curve:easeInOut)`:
  - **Active**: width 120px, `accentDim` bg, `borderRadius:999`, `Row(Icon 20px, SizedBox(6), Text 13px w600)` — all `AppColors.accent`
  - **Inactive**: width 48px, transparent, icon only `AppColors.textDim`
- Red badge (`AppColors.red`) on Review tab when due count > 0
- Nav auto-sizes via `mainAxisSize:min`; centered on screen via `Center` wrapper (NOT stretched left:24/right:24)

**Bottom padding rule**: all scroll screens must add `100 + MediaQuery.of(context).padding.bottom` as bottom inset so content clears the floating nav.

## Translate screen layout — focus states
No `AppBar`. Uses `CustomScrollView` + `SliverToBoxAdapter` (always — never `SliverFillRemaining`).
`Scaffold(resizeToAvoidBottomInset: false)` — keyboard handled manually via `MediaQuery.viewInsets.bottom`.

```
Scaffold(resizeToAvoidBottomInset: false, body: CustomScrollView([
  SliverToBoxAdapter → OfflineBanner
  SliverToBoxAdapter → SizedBox(height: cardHeight, child: _buildCardShell)
    cardHeight = idle: screenHeight*0.73 | typing: screenHeight-keyboardInset | loading/result: screenHeight
  SliverToBoxAdapter → LanguageSelectorWidget  (idle only)
  SliverToBoxAdapter → _AutoDetectBanner        (idle/typing, if autoDetected)
  _PullHandle + SliverList → feed posts         (idle only, _kShowFeed=true)
  SliverToBoxAdapter → bottom padding
]))
```

**Card shell** (`_buildCardShell`): `Container(cardBlack, borderRadius bottomOnly 20)` → `Column`:
- Stats header (`if (isIdle)` only — instantly hidden on typing, no animation)
- `Expanded → AnimatedSwitcher` (fade 300ms): idle/typing → `_StageArea` | loading → shimmer | result → `EnrichmentResultCard`

**Focus states** (`_FocusState` enum, derived from pipeline + `_focusNode.hasFocus`):
- `idle` — stats row, hint text, collection selector, recent strip (3 cards + "See all" h=68), bottom nav visible
- `typing` — input only; stats/chips/recents instantly hidden (no animation); bottom nav hidden; card shrinks as keyboard rises
- `loading` — shimmer only; bottom nav hidden; card is full height
- `result` — `EnrichmentResultCard` (scrollable); bottom nav visible; card is full height

**`_StageArea`** layout (idle + typing):
- `Expanded(flex:3)` transparent tap zone (focuses input)
- `TextField(cursorColor: AppColors.accent)` — 28px idle / 32px typing
- Hint style: `fontSize * 1.2`, `FontWeight.w500`, `height: 1.15`
- `if (!isTyping)` → `CollectionSelector` (no animation, instant hide)
- `if (!isTyping && recents.isNotEmpty)` → recent strip h=68 (instant hide)
- `Expanded(flex:2)` tap zone + submit arrow button (bottom-right, amber circle)

**Space island visibility**: Floating space island + stats row hidden (opacity 0 + IgnorePointer) when not in idle state — only visible when `isIdle && _islandVisible`.

**Nav visibility**: `translateNavHiddenProvider` (StateProvider<bool> in `shell_screen.dart`) — set `!navVisible` via `addPostFrameCallback`. FloatingPillNav + fade gradient wrapped in `AnimatedOpacity`.

**Feed**: enabled (`_kShowFeed = true`). Feed provider initialized in `initState`.

## Recent words
Recents are **space-scoped**: stored under `recent_translations_{spaceId}` in SharedPreferences (falls back to `recent_translations` for no-space). `TranslateController` tracks `_currentSpaceId`; on space switch it reloads recents from the new space key. Each space has a completely independent recent history.

- `_StageArea._maxRecentVisible = 3` — strip shows 3 cards + "See all" arrow card (4th)
- `RecentCarousel` widget (in `widgets/recent_translations_list.dart`) — paged carousel (3 cards/page), auto-scroll 4s, velocity-based swiping, grey progress dots with animated fill, max 8 word cards + 1 "See All" card = 3 pages
- `RecentScreen` at `lib/screens/recent/recent_screen.dart` — full vertical list with WordCard-style cards (22px word, 16px translation, 20px padding, 18px radius — matches vocabulary proportions). "In vocabulary"/"Not saved" badge at bottom-left. Swipe-to-delete with undo (same mechanic as vocabulary). Back button + "Clear all".
- `TranslateController.removeRecent(word)` — removes a single recent item by word
- Tapping a card in full page: `loadFromCache(item)` or `translate(item.word)` then `context.pop()`

## Language selector
`lib/widgets/language_selector.dart` — minimal design (no flags, no pills, no chevrons):
- `LanguageSelectorWidget`: plain `Padding(vertical:4)` row — no outer container/border
- `_LanguageLabel` (renamed from `_LanguageChip`): `GestureDetector + Padding(v:8, h:14)` + `Column(name Text 15px w500 AppColors.text, subtitle Text 11px w400 AppColors.textDim)`
- Subtitles: "Learn" for learning lang, "Fluent" for native lang
- `_SwapButton`: `Container(38×38, surface2, circle shape, swap_horiz icon AppColors.textDim 18px)` — no theme bg

## Vocabulary screen (DeckScreen) — redesigned 2026-03-13
No AppBar. `SafeArea(bottom:false)` → `Column(_Header, Expanded(CustomScrollView))`.

**CustomScrollView slivers (in order):**
1. `CefrMilestoneBar` — level badge + progress bar + "N to next" + info icon → `/stats`
2. `_TodaysFocusCarousel` — cards due within 24h
3. `CollectionTabs` — horizontal scrollable pills replacing old bottom island
4. Toolbar row — `SortFilterDropdown` | `_CefrToggle` | `Spacer` | `ViewModeToggle`
5. Card list — flat or CEFR-grouped depending on toggle
6. Bottom padding

**`_Header`**: "N" (28px w700) + "words" (15px w500 textMuted) | search icon. Taps → `/stats`. Search expands via `AnimatedSize`.

**`CefrMilestoneBar`** (`lib/widgets/deck/cefr_milestone_bar.dart`): `ConsumerWidget` using `cefrLevelProvider`. Shows current level badge, gradient progress bar, points to next level, info button → `/stats`.

**`_TodaysFocusCarousel`**: `PageView(viewportFraction:0.58)`, height 210. Active card: ProgressRing + "Review Now" → `context.go('/review')`. Inactive: dimmed, no ring. Dot indicators (active dot stretches to 16px wide).

**`CollectionTabs`** (`lib/widgets/deck/collection_tabs.dart`): horizontal `SingleChildScrollView` with pill-shaped tabs. Each: emoji + name + count badge, active/inactive accent styling. "+ New" tab at end → `/collections/new`.

**Toolbar:**
- `SortFilterDropdown` (`lib/widgets/deck/sort_filter_dropdown.dart`): OverlayEntry dropdown with SORT BY (Newest/Alphabetical) + SHOW (All/New/Learning/Review/Mature) radio sections. Combined label shows current state (e.g. "Newest · Learning").
- `_CefrToggle`: pill button toggling CEFR accordion grouping on/off (`deckCefrGroupingProvider`)
- `ViewModeToggle` (`lib/widgets/deck/view_mode_toggle.dart`): 3-button segmented control (big/standard/stream) via `deckViewModeProvider`

**View modes** (`DeckViewMode` enum in `deck_filter_providers.dart`):
- `big` → `BigWordCard` (`lib/widgets/deck/big_word_card.dart`): word 22px, translation, example sentence (italic, bordered top), footer with CEFR + status + collection
- `standard` → `WordCard` (`lib/widgets/word_card.dart`): progress ring, CEFR badge, collection badge, due date
- `stream` → `StreamWordRow` (`lib/widgets/deck/stream_word_row.dart`): minimal inline row with word, translation, CEFR code, status dot, collection emoji

**CEFR grouping**: `CefrAccordionGroup` (`lib/widgets/deck/cefr_accordion.dart`) — expandable sections per CEFR level with colored bar header, count, animated chevron, `AnimatedSize` body. `_expandedCefrLevels` Set in deck screen state (default: A1, A2, B1 expanded).

**`WordCard`** (`lib/widgets/word_card.dart`): params: word, translation, progress(0–1), masteryLabel, nextReviewDate, collectionName, collectionColor, cefrLevel, isSelectMode, isSelected. Top row: word + CEFR badge (inline) + progress ring (or `_SelectBox`). Bottom row: `[CollectionBadge][Spacer][schedule icon][due date]`.

**Helpers in `deck_controller.dart`**: `masteryLabelFor(c)`, `masteryProgressFor(c)`, `cardProgress(c)` (smooth 0–1).

**Shared widget**: `lib/widgets/progress_ring.dart` — `CustomPainter` circular ring, used in WordCard and `_TodaysFocusCarousel`.

## CEFR level progress system
Weighted scoring system for language proficiency level estimation.

**Scoring** (`lib/core/cefr/cefr_level_calculator.dart`):
- `pointsForCard()`: repetitions=0 → 0.5, intervalDays<7 → 1.0, intervalDays<21 → 1.5, else → 2.0
- Thresholds: A1=0, A2=30, B1=100, B2=250, C1=500, C2=1000
- `CefrLevelResult`: currentLevel, nextLevel, totalPoints, progress (0–1), pointsToNext
- `cefrLevelMeta`: map of level → `CefrMeta(name, emoji, description)`

**Provider** (`lib/providers/cefr_level_provider.dart`):
- `cefrLevelProvider` — `Provider<CefrLevelResult>` watching `cardListProvider.allCards`
- `cefrBreakdownProvider` — card count per CEFR level

**Stats page "Your Level" section** (`lib/screens/stats/stats_screen.dart`):
- `LevelHeroCard` (`lib/widgets/stats/level_hero_card.dart`): emoji, level code (32px), name, gradient progress bar, points to next, description
- `LevelJourneyList` (`lib/widgets/stats/level_journey_list.dart`): A1→C2 checkpoint timeline with green checkmarks (completed), amber dot (current), empty circles (future)
- `LevelTipsCard` (`lib/widgets/stats/level_tips_card.dart`): "What moves your level up" tips card

## Review screen
No AppBar — `SafeArea` wraps body directly. Progress bar at very top shows daily goal: `reviewsToday / dailyGoal` (persisted, resets midnight). `X / Y` label to the right of bar.
Review sessions are **space-scoped**: `getDueCards(userId, now, spaceId: spaceId)` — only shows cards belonging to the active space. `ReviewController.loadDueCards()` reads `activeSpaceProvider?.id` and passes it through.

**Tinder-style swipe mechanic** (`_SwipeArea` widget):
- Raw pointer tracking via `Listener` — bypasses gesture arena so `SelectionArea` never conflicts
- Horizontal swipe detection: `dx > 8 && dx > dy*1.5 && elapsed < 350ms`
- Fly-away animation on commit (velocity > 300 or offset > 35% width)
- Elastic snap-back on cancel
- Color overlay with "EASY" (green, right) / "HARD" (accent, left) labels
- Tap to flip card, swipe to rate — no "Show Answer" button
- Rating buttons at bottom with `padding.bottom + 88` clearance for floating nav

## Leveling System + Achievements
14-level progression based on word count. All state computed client-side from `allCards.length` — no database changes.

**Level definitions** (`lib/core/constants/level_definitions.dart`):
- `LevelDef` class: level, name, startWords, span, colorPrimary/Secondary, description
- Color gradient evolution: navy (1-3) → indigo/violet (4-5) → purple (6-8) → teal (9-11) → green (12-14)
- Helpers: `getLevelForWords(int)`, `getLevelProgress(int)` (0.0–1.0), `wordsToNextLevel(int)`
- Level thresholds: 0, 8, 20, 40, 70, 110, 165, 235, 325, 435, 575, 745, 945, 1185

**LevelProgressBar** (`lib/widgets/level_progress_bar.dart`):
- Replaces old `_StatsRow` pill on translate screen idle state
- Layout: `[LevelBadge] [wordCount · N to Lv.X] [streak]` top row + `[gradient bar + shimmer] [3 chambers]` bottom row
- Badge taps → `/stats/achievements`, word count taps → `/stats`, streak taps → `/review`
- Chamber cycle: fill with pop animation → at 3 chambers, merge/dissolve → bar grows with spring curve
- Level-up: name flash, badge glow pulse, badge scale bump, bar color transition
- Streak: flame scale bounce, 6 burst particles, +1 float
- Uses `ref.listen(cardListProvider)` and `ref.listen(sessionStatsProvider)` — fully reactive

**Providers** (`lib/providers/statistics_provider.dart`):
- `levelProvider` — derived `LevelDef` from word count
- `levelProgressProvider` — derived 0.0–1.0 progress

**Achievements page** (`lib/screens/stats/achievements_screen.dart`):
- Route: `/stats/achievements` (pushed above shell)
- `_CurrentLevelHero` — gradient card with level number, name, description, progress bar
- 14 × `_LevelAchievementTile` — completed (checkmark), current (mini progress ring), locked (lock icon, dimmed)
- `_ComingSoonCard` — teaser chips for future achievement types (streaks, reviews, collections, multi-language)
- Accessible from Stats screen via `_LevelNavRow`

## Save / vocabulary status UX (TranslationCard)
Three mutually exclusive states in the action button area (isSaved checked before alreadyInDeck):
1. **`isSaved = true`** (just saved this session) → green bubble "Saved to your vocabulary" → card auto-dismisses after 1.2s
2. **`alreadyInDeck = true`** (word already in cards before this interaction) → blue/indigo bubble "Already in your vocabulary" (`layers_rounded` icon, `0xFF6366F1`)
3. **neither** → `FilledButton` "Save to Vocabulary"

Rules:
- `isSaved` is set ONLY by `saveCard()` — never by `restoreFromCache` or `loadFromDeckCard`
- `alreadyInDeck` computed from `allCards.any(word match)` in translate_screen
- `_InDeckHintChip` (below input, before card loads) — also blue/indigo, consistent with above
- No floating overlay — removed; green bubble in card is the only save confirmation

## Design system
Dark-only app (`ThemeMode.dark` hardcoded). Fonts: DM Sans (body) + JetBrains Mono (IPA transcriptions, stat numbers).

`lib/core/constants/app_colors.dart` — single source of truth for all colors:
- `AppColors.bg` (`0xFF0D0D0D`) — scaffold / deepest layer
- `AppColors.cardBlack` (`0xFF131313`) — translate input card (slightly lighter than bg, floats above)
- `AppColors.surface/surface2/surface3` — elevated surfaces
- `AppColors.accent` (amber `0xFFE8A838`) — brand color; `accentDim`/`accentGlow`
- `AppColors.indigo` (`0xFF6366F1`) — vocabulary/saved indicator; `indigoDim`
- `AppColors.green` (`0xFF4ADE80`) — positive/mastered; `greenDim`
- `AppColors.red` (`0xFFF87171`) — error/again; `redDim`
- `AppColors.text/textMuted/textDim`
- `AppColors.ratingAgain/ratingHard/ratingGood/ratingEasy` — SM-2 buttons
- `AppColors.translationGradient` — amber gradient for translation box
- Spacing scale: `spacingXs/Sm/Md/Base/Lg/Xl/Xxl`
- Border radius scale: `radiusXs/Sm/Md/Lg/Xl/Full` + `borderRadiusSm/Md/Lg/Pill`

`lib/core/theme/app_theme.dart` — `abstract final class AppTheme`:
- `AppTheme.darkTheme` — single getter, replaces old light/dark pair
- Custom text styles: `transcriptionStyle` (JetBrains Mono), `statNumberStyle`, `translationBoxStyle` (black on amber), `slideWordHero/slideTranslation/slideTypeLabel`
- Component themes: `CardThemeData`, `DialogThemeData`, `NavigationBarThemeData` with `WidgetStatePropertyAll`

**Never use hardcoded `Color(0xFF...)` for colors that exist in `AppColors`.** Always import and reference `AppColors.*`.

## Spoiler overlay
`lib/widgets/spoiler_overlay.dart` — animated particle overlay hiding card content.
- Eye button embedded in orange translation box (right side, accent container), always visible
- `SpoilerOverlay(seed:0)` wraps translation text; `SpoilerOverlay(seed:1)` wraps enrichment sections
- `repeat(reverse:true)` — ping-pong animation, no jump at loop boundary
- Applied to: `TranslationCard`, `WordDetailSheet`, `SynonymCardSheet` (NOT review cards)

## Statistics
`fullStatisticsProvider` combines `statisticsProvider` (card data) + `sessionStatsProvider` (SharedPreferences).
`SessionStats`: `currentStreak`, `reviewsToday`, `dailyGoal` (default 20, stored in prefs).
`recordReview()` called after each card rating — persists today's count, updates streak.

## Shell screen
`shell_screen.dart` eagerly calls `loadCards(userId)` on mount and on auth change — ensures cards are in state regardless of which tab opens first. Also handles one-time notification permission dialog.

## Languages
- 25 supported DeepL codes: UK, EN, DE, FR, ES, IT, PT, PL, NL, JA, ZH, KO, RU, TR, AR, CS, DA, FI, EL, HU, ID, NB, RO, SK, SV
- Defaults: `nativeLanguage = 'UK'`, `learningLanguage = 'EN'`
- Language display names + flag emojis in `AppConstants`

## Edge function auth pattern
All 4 functions share the same auth guard — added after CORS preflight:
```typescript
const authHeader = req.headers.get('Authorization')
if (!authHeader?.startsWith('Bearer ')) {
  return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, ... })
}
// Supabase gateway verifies JWT signature; we just decode the sub claim:
const payload = JSON.parse(atob(authHeader.slice(7).split('.')[1]))
const user_id = payload.sub  // use this for all DB operations
```
`user_id` from request body is **ignored** in all functions.

## Gemini edge functions
All 4 Gemini functions (`enrich`, `translate-gemini`, `generate-feed`, `generate-suggestions`) use `gemini-2.5-flash` with `thinkingConfig: { thinkingBudget: 0 }`.
`enrich` and `translate-gemini` use:
- `thinkingConfig: { thinkingBudget: 0 }` — **required** to disable thinking mode. Without it, thinking tokens consume `maxOutputTokens` and the actual response is empty.
- `responseMimeType: 'application/json'` — structured JSON output
- `enrich`: `maxOutputTokens: 1024`, `temperature: 0.1`
- `translate-gemini`: `maxOutputTokens: 200`, `temperature: 0.1`

Enrich prompt uses `langName(code)` to convert ISO codes to full names (e.g. `NL` → `Dutch`) — all language fields in prompt are explicit full names. `usage_notes` and `example_sentence` are tagged `in ${srcName}`. Native fields use `translate X to ${tgtName}` phrasing. `did_you_mean` says `correct ${srcName} spelling`.

## Safety patterns (applied 2026-03-12)
- All `DateTime.parse()` in model `fromJson()` replaced with `DateTime.tryParse() ?? DateTime.now()` — prevents crash on null/malformed dates from Supabase
- All `.firstWhere()` in providers replaced with `.firstOrNull` + early return — prevents crash on double-delete or stale state
- `.single()` in feed_repository replaced with `.maybeSingle()` + null check — prevents crash when row missing
- Router extra casts guarded: `/collections/edit` falls back to create mode, `/word` redirects to `/deck` on wrong type
- Animation listener leak in `_SwipeToDelete` fixed: old listener removed before adding new one
- `catchError((_) {})` in card_provider replaced with `.then<void>((_) {}, onError: (_) {})` for correct return type

## Watch out for
- `dart:html` is deprecated but still required for web OAuth URL cleanup — suppress with `// ignore: avoid_web_libraries_in_flutter, deprecated_member_use`; already guarded by `kIsWeb`
- `UserProfile.userId` (not `.id`) — PK field name matches DB column `user_id`
- `suggested=true` posts in `card_feed_content` have no `card_id` — they're system-generated
- `FeedRecentTranslationsList` (in `widgets/feed/`) shows `FlashCard` objects — different from `RecentTranslationsList` (in `widgets/`) which shows `RecentItem` objects from translate controller history
- Enrichment failure in pipeline is non-fatal — translation result is still shown without enrichment
- `vercel --prod` must be run from `build/web/`, not project root — Vercel at project root tries Next.js build
- `FeedCache` only saves **non-suggested** user posts — suggested posts are always re-fetched live
- `backfillFeedPosts` only checks `status = 'ready'` rows as "already covered" — failed rows are transparently retried

## Collections system
- DB: `collections` table + `collection_id` FK on `cards` — migration `004_collections.sql` (apply in Supabase dashboard)
- Data: `Collection` model (`emoji`, `color` hex, `position` int, `isPinned`), `CollectionCache`, `ICollectionRepository`, `SupabaseCollectionRepository`
- Provider: `collectionProvider` (SWR, same pattern as cards), `pinnedCollectionProvider`, `collectionByIdProvider(id?)`, `collectionCardCountProvider(id?)`
- Deck filters: `lib/providers/deck_filter_providers.dart` — `DeckStatusFilter` enum, `DeckSortOption` enum, `DeckViewMode` enum (big/standard/stream), `deckCollectionFilterProvider` (String?), `deckCefrGroupingProvider` (bool), `filteredDeckCardsProvider`
- UI in deck: `CollectionTabs` (horizontal pills in CustomScrollView) + `SortFilterDropdown` (OverlayEntry) + `ViewModeToggle` (segmented control) + `CefrMilestoneBar`
- UI in translate: `CollectionSelector` widget (`lib/widgets/collection_selector.dart`) — `[+ CircleBtn] [label bubble] [▼ CircleBtn]` row with `OverlayEntry` dropdown
- Shell: `loadCollections(userId)` called alongside `loadCards` on init
- Router: `/collections/new` → `CreateCollectionScreen`, `/collections/edit` → `CreateCollectionScreen(collection: ...)`, `/collections/manage` → `ManageCollectionsScreen`
- Translate: `_saveCollectionId` state, `CollectionSelector` in idle+typing stage, auto-selects pinned on mount
- Reorder persistence: `collectionProvider.notifier.update(c.copyWith(position: i))` per item after drag

## Language normalization convention
`FlashCard.word` = **ALWAYS** the learning language (the language the user is studying).
`FlashCard.translation` = **ALWAYS** the native language (the language the user already knows).
`FlashCard.wordLang` / `translationLang` — explicit lang codes (e.g. 'EN' / 'UK').
Enrichment fields (`transcription`, `exampleSentence`, `synonyms`, `usageNotes`) are about the learning-language `word`. The `_native` variants are in the native language.

**Pipeline normalization** (`translate_pipeline_provider.dart`):
After translation, if `sourceLang != learningLanguage` (user typed in native), the result is swapped so `word` = learning-language word before enrichment + save. Enrichment is always called with the learning-language word as primary.

## Word↔Translation swap (study preference)
`_SwapButton` (swap_horiz icon, `AppColors.surface2` bg) on word detail screen only. Positioned in the row below the card between CollectionSelector and LangToggle.
- **UI-only toggle** — changes display order (which word is shown as headline vs translation box) for study purposes
- Does NOT mutate the DB — toggles `_displaySwapped` state in `WordDetailScreen`
- Removed from translate screen (pipeline normalization handles direction automatically)
- Deck hint check (`checkDeckHint`) matches both `card.word` and `card.translation`

## Swipe-to-delete (vocabulary)
Custom `_SwipeToDelete` widget in deck_screen.dart (not Flutter's `Dismissible`):
- Rubber-band resistance: `damping = 0.35`, threshold `0.55` of card width
- Red delete button reveals underneath on swipe left
- Full swipe past threshold → delete with undo
- `_UndoRow` shows countdown (4,3,2,1) then finalizes deletion
- `_PendingDelete` tracks pending deletes in `_pendingDeletes` map

## Inline emoji picker
`lib/widgets/emoji_picker_field.dart`:
- `EmojiPickerField` — tappable emoji button toggling picker visibility
- `InlineEmojiPicker` — 8 category tabs, scrollable emoji grid, search with `_emojiKeywords` map
- Used in `CreateCollectionScreen` (create + edit modes)

## TODO
- Firebase push notifications not fully configured (lazy init silently skipped; logs in `kDebugMode`)
- `dart:html` → migrate to `package:web` when web OAuth cleanup API is stable
- `video_slide.dart` is a placeholder — YouGlish integration pending
- `decoration` field on `FeedSlide`/`FeedPost` reserved for vector graphic overlays
- `compareHero`, `compareGrid`, `themeHero` slide types exist in client but no generation path yet
- Feed enabled (`_kShowFeed = true` in `translate_screen.dart`)
