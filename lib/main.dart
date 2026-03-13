import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

// TODO: migrate to package:web when the web OAuth URL cleanup API is stable
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html show window;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    authOptions: const FlutterAuthClientOptions(
      // PKCE is required on web so the OAuth code exchange works correctly
      // after the redirect back to the app.
      authFlowType: kIsWeb ? AuthFlowType.pkce : AuthFlowType.implicit,
    ),
  );

  // On web: strip ?code= from the URL after Supabase has exchanged it.
  // Leaving it in the URL causes a second exchange attempt on any re-init,
  // which invalidates the session and produces 401s on subsequent calls.
  if (kIsWeb) {
    final uri = Uri.parse(html.window.location.href);
    if (uri.queryParameters.containsKey('code')) {
      html.window.history.replaceState(null, '', uri.path);
    }
  }

  // Firebase is initialized lazily in NotificationService.initialize()
  // to avoid crashing when google-services.json is not yet configured.

  runApp(const ProviderScope(child: WordDeckApp()));
}
