import '../models/user_profile.dart';

abstract class IAuthService {
  Future<UserProfile> signInWithGoogle();
  Future<void> signOut();
  Stream<UserProfile?> get authStateChanges;
  UserProfile? get currentUser;
}
