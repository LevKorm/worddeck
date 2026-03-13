import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../modules/auth/auth_provider.dart';
import '../models/collection.dart';
import '../models/flash_card.dart';
import '../screens/auth/login_screen.dart';
import '../screens/collections/create_collection_screen.dart';
import '../screens/collections/manage_collections_screen.dart';
import '../screens/deck/deck_screen.dart';
import '../screens/deck/word_detail_screen.dart';
import '../screens/recent/recent_screen.dart';
import '../screens/review/review_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/shell/shell_screen.dart';
import '../screens/stats/achievements_screen.dart';
import '../screens/stats/stats_screen.dart';
import '../screens/translate/translate_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authValue    = ref.read(authStateProvider);
      final isLoading    = authValue.isLoading;
      final isAuthed     = authValue.valueOrNull != null;
      final isOnLogin    = state.matchedLocation == '/login';

      if (isLoading) return null;
      if (!isAuthed && !isOnLogin) return '/login';
      if (isAuthed  &&  isOnLogin) return '/';
      return null;
    },
    routes: [
      // ── Auth ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),

      // ── Settings, Stats, Recent — pushed above shell (no bottom nav) ───
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/stats',
        builder: (_, __) => const StatsScreen(),
      ),
      GoRoute(
        path: '/stats/achievements',
        builder: (_, __) => const AchievementsScreen(),
      ),
      GoRoute(
        path: '/recent',
        builder: (_, __) => const RecentScreen(),
      ),
      GoRoute(
        path: '/collections/new',
        builder: (_, __) => const CreateCollectionScreen(),
      ),
      GoRoute(
        path: '/collections/edit',
        builder: (_, state) => CreateCollectionScreen(
          collection: state.extra is Collection ? state.extra as Collection : null,
        ),
      ),
      GoRoute(
        path: '/collections/manage',
        builder: (_, __) => const ManageCollectionsScreen(),
      ),
      GoRoute(
        path: '/word',
        redirect: (_, state) =>
            state.extra is FlashCard ? null : '/deck',
        builder: (_, state) =>
            WordDetailScreen(card: state.extra as FlashCard),
      ),

      // ── Main shell with bottom nav (3 tabs) ───────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => ShellScreen(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/',       builder: (_, __) => const TranslateScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/deck',   builder: (_, __) => const DeckScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/review', builder: (_, __) => const ReviewScreen()),
          ]),
        ],
      ),
    ],
  );
});

/// ChangeNotifier that triggers GoRouter to re-evaluate the redirect when
/// the Riverpod auth state changes.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
