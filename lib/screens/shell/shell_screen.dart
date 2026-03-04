import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../modules/notifications/notification_provider.dart';
import '../../providers/statistics_provider.dart';
import '../../widgets/nav_bar.dart';

/// Provider that signals screens to scroll to top.
/// Incremented every time the user taps the already-active bottom nav tab.
final scrollToTopProvider = StateProvider<int>((ref) => 0);

const _kPermissionAsked = 'notif_permission_asked';

class ShellScreen extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const ShellScreen({super.key, required this.navigationShell});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRequestNotificationPermission();
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
    final dueCount = ref.watch(fullStatisticsProvider).dueToday;

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: AppNavBar(
        currentIndex: widget.navigationShell.currentIndex,
        reviewBadgeCount: dueCount,
        onTap: (index) {
          if (index == widget.navigationShell.currentIndex) {
            // Same tab tapped → signal scroll to top
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
    );
  }
}
