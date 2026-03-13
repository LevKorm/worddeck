import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

/// Max width for the app on wide screens (web/desktop).
/// On narrower screens the app fills the full width naturally.
const double _kMobileBreakpoint = 430.0;

class WordDeckApp extends ConsumerWidget {
  const WordDeckApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'WordDeck',
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: kIsWeb
          ? (context, child) {
              return ColoredBox(
                color: AppTheme.darkTheme.scaffoldBackgroundColor,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _kMobileBreakpoint),
                    child: SelectionArea(child: child!),
                  ),
                ),
              );
            }
          : null,
    );
  }
}
