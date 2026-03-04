import 'package:supabase_flutter/supabase_flutter.dart';
import '../../contracts/i_auth_service.dart';
import '../../core/errors/app_exception.dart' as app_ex;
import '../../models/user_profile.dart';

/// Google OAuth via Supabase.
///
/// Sign-in flow (mobile):
///   1. signInWithGoogle() → opens OS browser via supabase_flutter
///   2. User completes Google OAuth
///   3. Browser deep-links back to com.levkorm.worddeck://login-callback
///   4. supabase_flutter intercepts the link, exchanges code for session
///   5. authStateChanges fires with the new UserProfile
///   → GoRouter redirect guard sees authenticated user → navigates to /
///
/// Deep-link setup required:
///   Android: AndroidManifest.xml intent-filter for com.levkorm.worddeck
///   iOS:     Info.plist CFBundleURLSchemes entry for com.levkorm.worddeck
class SupabaseAuthService implements IAuthService {
  final SupabaseClient _supabase;

  const SupabaseAuthService(this._supabase);

  static const String _redirectScheme = 'com.levkorm.worddeck://login-callback';

  @override
  UserProfile? get currentUser {
    final user = _supabase.auth.currentUser;
    return user == null ? null : _userToProfile(user);
  }

  @override
  Stream<UserProfile?> get authStateChanges =>
      _supabase.auth.onAuthStateChange.map((state) {
        final user = state.session?.user;
        return user == null ? null : _userToProfile(user);
      });

  @override
  Future<UserProfile> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _redirectScheme,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      // At this point the browser has opened.
      // Session is established asynchronously via deep link.
      // Callers should watch authStateChanges for the signed-in UserProfile.
      final user = _supabase.auth.currentUser;
      if (user != null) return _userToProfile(user);
      // Normal case: return placeholder; auth state stream fires on completion
      return UserProfile.defaults('pending');
    } catch (e) {
      throw app_ex.AuthException('Google sign-in failed', cause: e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw app_ex.AuthException('Sign out failed', cause: e);
    }
  }

  UserProfile _userToProfile(User user) => UserProfile(
        userId: user.id,
        nativeLanguage: user.userMetadata?['native_language'] as String? ?? 'UK',
        learningLanguage: user.userMetadata?['learning_language'] as String? ?? 'EN',
        createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
      );
}
