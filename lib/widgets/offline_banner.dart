import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connectivity_provider.dart';

/// Slide-down banner shown at the top of the screen when there is no network.
/// Wrap the Scaffold body (or place in a Stack) to show this automatically.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);

    if (!isOffline) return const SizedBox.shrink();

    return const ColoredBox(
      color: Color(0xFF374151),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'No internet connection. Some features may be unavailable.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .slideY(begin: -1, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }
}
