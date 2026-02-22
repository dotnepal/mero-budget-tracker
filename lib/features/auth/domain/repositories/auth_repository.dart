import '../entities/app_user.dart';

abstract class AuthRepository {
  /// Stream that emits the current user whenever auth state changes.
  /// Emits null when the user signs out.
  Stream<AppUser?> get authStateChanges;

  /// Returns the currently signed-in user, or null if unauthenticated.
  AppUser? get currentUser;

  /// Signs in with Google. Throws an exception on failure or cancellation.
  Future<AppUser> signInWithGoogle();

  /// Signs out and clears the Google session.
  Future<void> signOut();
}
