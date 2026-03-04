import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../contracts/i_auth_service.dart';
import '../../models/user_profile.dart';
import 'supabase_auth_service.dart';

/// Raw Supabase client — single instance from supabase_flutter.
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

/// IAuthService singleton.
final authServiceProvider = Provider<IAuthService>(
  (ref) => SupabaseAuthService(ref.read(supabaseClientProvider)),
);

/// Stream of the current user. Emits null when signed out.
final authStateProvider = StreamProvider<UserProfile?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges,
);

/// Synchronous bool for quick auth checks (GoRouter guard, UI guards).
final isAuthenticatedProvider = Provider<bool>(
  (ref) => ref.watch(authStateProvider).valueOrNull != null,
);

/// Current user profile (null when not authenticated).
final currentUserProvider = Provider<UserProfile?>(
  (ref) => ref.watch(authStateProvider).valueOrNull,
);
