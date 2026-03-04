import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_provider.dart';

const _kPermissionAsked = 'notif_permission_asked';

/// Wraps the app and, after the first frame, requests notification permission
/// once — on first launch only. Firebase must already be initialized before
/// this triggers; if initialization fails the request is silently skipped.
class NotificationBootstrap extends ConsumerStatefulWidget {
  final Widget child;

  const NotificationBootstrap({super.key, required this.child});

  @override
  ConsumerState<NotificationBootstrap> createState() =>
      _NotificationBootstrapState();
}

class _NotificationBootstrapState
    extends ConsumerState<NotificationBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAskPermission());
  }

  Future<void> _maybeAskPermission() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kPermissionAsked) == true) return;

    // Mark as asked so we don't show again
    await prefs.setBool(_kPermissionAsked, true);

    // Small delay so the app UI is fully ready
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Only request if notifications are NOT already enabled
    final settings = ref.read(notificationSettingsProvider);
    if (settings.enabled) return;

    // Show a rationale dialog first
    final granted = await _showRationaleDialog();
    if (!mounted) return;

    if (granted) {
      try {
        await ref.read(notificationSettingsProvider.notifier).setEnabled(true);
        // Permission request happens inside the service on Settings screen;
        // here we just flip the preference so it shows as enabled.
      } catch (_) {
        // Firebase not configured — silently skip
      }
    }
  }

  Future<bool> _showRationaleDialog() async {
    if (!mounted) return false;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Stay on track 🔔'),
            content: const Text(
              'Enable reminders so WordDeck can nudge you when words are due for review. '
              'You can always change this in Settings.',
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
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
