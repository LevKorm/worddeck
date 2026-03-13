import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_profile.dart';
import '../../modules/auth/auth_provider.dart';
import '../../modules/collections/collection_provider.dart';
import '../../modules/notifications/notification_provider.dart';
import '../../modules/spaces/space_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/statistics_provider.dart';
import '../../widgets/nav_bar.dart';
import '../../widgets/preload_icons.dart';
import '../../widgets/space_popup.dart';

import 'splash_helper.dart';

/// Provider that signals screens to scroll to top.
/// Incremented every time the user taps the already-active bottom nav tab.
final scrollToTopProvider = StateProvider<int>((ref) => 0);

/// When true, the floating pill nav (and its gradient) are hidden.
/// Set by TranslateScreen during typing / loading states.
final translateNavHiddenProvider = StateProvider<bool>((ref) => false);

const _kPermissionAsked = 'notif_permission_asked';

class ShellScreen extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const ShellScreen({super.key, required this.navigationShell});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  bool _splashRemoved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRequestNotificationPermission();
      final user = ref.read(currentUserProvider);
      if (user != null) {
        // SpaceNotifier.loadSpaces resolves the active space and then
        // calls cardListProvider.loadCards scoped to that space.
        ref.read(spaceProvider.notifier).loadSpaces(user.userId);
        ref.read(collectionProvider.notifier).loadCollections(user.userId);
      }
      // Remove splash after data providers have kicked off and several
      // frames have painted (so icons/fonts are fully rasterised).
      _removeSplash();
    });
  }

  /// Waits for enough frames to paint so all fonts/icons are rasterised,
  /// then fades out and removes the HTML splash overlay.
  void _removeSplash() {
    if (_splashRemoved || !kIsWeb) return;
    _splashRemoved = true;

    // Wait for 10 frames so Flutter has time to load and rasterise
    // all icons (via PreloadIcons) + emoji text + layout the first screen.
    _waitFrames(10, () {
      removeSplashElement();
    });
  }

  /// Calls [callback] after [count] animation frames have been painted.
  void _waitFrames(int count, VoidCallback callback) {
    if (count <= 0) {
      callback();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _waitFrames(count - 1, callback);
    });
  }

  Future<void> _maybeRequestNotificationPermission() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kPermissionAsked) == true) return;
    await prefs.setBool(_kPermissionAsked, true);

    // Small delay so the UI is fully settled
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Skip if already enabled
    if (ref.read(notificationSettingsProvider).enabled) return;

    final granted = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Stay on track 🔔'),
            content: const Text(
              'Enable reminders so WordDeck can nudge you when words are due '
              'for review. You can always change this in Settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Not now'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Enable'),
              ),
            ],
          ),
        ) ??
        false;

    if (granted && mounted) {
      try {
        await ref
            .read(notificationSettingsProvider.notifier)
            .setEnabled(true);
      } catch (_) {
        // Firebase not configured on this platform — silently skip
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reload card list when the user account changes (logout → new login).
    ref.listen<UserProfile?>(currentUserProvider, (prev, next) {
      if (next != null && next.userId != prev?.userId) {
        ref.read(spaceProvider.notifier).loadSpaces(next.userId);
        ref.read(collectionProvider.notifier).loadCollections(next.userId);
      }
    });

    final dueCount = ref.watch(fullStatisticsProvider).dueToday;
    final navHidden = ref.watch(translateNavHiddenProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Paint all icons at opacity 0 so CanvasKit rasterises every glyph
          // into its cache. Subsequent tabs get instant icons — no flash.
          const Positioned(
            left: 0,
            top: 0,
            child: PreloadIcons(),
          ),

          // Tab content fills the full body
          Positioned.fill(
            child: widget.navigationShell,
          ),

          // Fade gradient — content dissolves behind the nav
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 110,
            child: AnimatedOpacity(
              opacity: navHidden ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.bg.withOpacity(0.0),
                        AppColors.bg.withOpacity(0.6),
                        AppColors.bg,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Floating nav row: [space] [pill nav] [settings]
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            child: AnimatedOpacity(
              opacity: navHidden ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                ignoring: navHidden,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SpaceSwitcherButton(ref: ref),
                    const SizedBox(width: 8),
                    FloatingPillNav(
                      currentIndex: widget.navigationShell.currentIndex,
                      reviewDueCount: dueCount,
                      onTap: (index) {
                        if (index == widget.navigationShell.currentIndex) {
                          ref.read(scrollToTopProvider.notifier).state++;
                        } else {
                          widget.navigationShell.goBranch(
                            index,
                            initialLocation:
                                index == widget.navigationShell.currentIndex,
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _SettingsButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _kBtnDecoration = BoxDecoration(
  color: Color(0xF50D0D0D), // AppColors.bg @ 96%
  shape: BoxShape.circle,
  border: Border.fromBorderSide(
    BorderSide(color: Color(0x80333333), width: 0.5), // surface3 @ 50%
  ),
  boxShadow: [
    BoxShadow(
      color: Color(0x66000000), // black @ 40%
      blurRadius: 20,
      offset: Offset(0, 4),
      spreadRadius: -2,
    ),
  ],
);

class _SpaceSwitcherButton extends StatelessWidget {
  final WidgetRef ref;
  final _key = GlobalKey();

  _SpaceSwitcherButton({required this.ref});

  @override
  Widget build(BuildContext context) {
    final space = ref.watch(activeSpaceProvider);
    final flag = space != null
        ? AppConstants.flagForCode(space.learningLanguage)
        : '🌐';

    return GestureDetector(
      key: _key,
      onTap: () {
        final box = _key.currentContext?.findRenderObject() as RenderBox?;
        if (box == null) return;
        final pos = box.localToGlobal(Offset.zero);
        final rect = pos & box.size;
        showSpacePopup(context, ref, rect);
      },
      child: Container(
        width: 62,
        height: 62,
        decoration: _kBtnDecoration,
        alignment: Alignment.center,
        child: Text(flag, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/settings'),
      child: Container(
        width: 62,
        height: 62,
        decoration: _kBtnDecoration,
        alignment: Alignment.center,
        child: const Icon(Icons.settings_outlined,
            size: 22, color: AppColors.textMuted),
      ),
    );
  }
}
