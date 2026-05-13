import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'dart:async';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;
  Rxn<User> currentUser = Rxn<User>();

  late StreamSubscription<User?> _authSub;   // ← store the subscription

  @override
  void onInit() {
    super.onInit();

    // Check if already signed in
    currentUser.value = _authService.currentUser;

    // Listen auth state changes
    _authSub = _authService.authStateChanges.listen((user) {
      currentUser.value = user;
    });
  }

  @override
  void onClose() {
    _authSub.cancel();   // ← cancel on controller disposal
    super.onClose();
  }

  // ── Clear error (call when navigating between auth screens) ──
  void clearError() => errorMessage.value = '';

  // ── Register ────────────────────────────────────────────────
  Future<void> register(String email, String password) async {
    errorMessage.value = '';
    isLoading.value = true;

    try {
      final credential =
      await _authService.signUpWithEmail(email, password);
      currentUser.value = credential.user;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _mapError(e.code);
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred.';
    } finally {
      isLoading.value = false;
    }
  }

  // ── Login ────────────────────────────────────────────────────
  Future<void> login(String email, String password) async {
    errorMessage.value = '';
    isLoading.value = true;

    try {
      final credential =
      await _authService.signInWithEmail(email, password);
      currentUser.value = credential.user;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _mapError(e.code);
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred.';
    } finally {
      isLoading.value = false;
    }
  }

  // ── Google Login ─────────────────────────────────────────────
  // Note: Google sign-in can throw PlatformException (not FirebaseAuthException)
  // when the user cancels, so we catch both here.
  Future<void> loginWithGoogle() async {
    errorMessage.value = '';
    isLoading.value = true;

    try {
      final credential = await _authService.signInWithGoogle();
      currentUser.value = credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code != 'google-sign-in-aborted') {
        // Aborted = user cancelled, not an error to surface
        errorMessage.value = _mapError(e.code);
      }
    } catch (e) {
      errorMessage.value = 'Google sign-in failed. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  // ── Reset Password ───────────────────────────────────────────
  Future<void> resetPassword(String email) async {
    errorMessage.value = '';
    isLoading.value = true;

    try {
      await _authService.sendPasswordResetEmail(email);
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _mapError(e.code);
    } catch (e) {
      errorMessage.value = 'Failed to send reset email.';
    } finally {
      isLoading.value = false;
    }
  }

  // ── Logout ───────────────────────────────────────────────────
  Future<void> logout() async {
    errorMessage.value = '';
    isLoading.value = true;

    try {
      await _authService.signOut();
      currentUser.value = null;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _mapError(e.code);
    } catch (e) {
      errorMessage.value = 'Sign out failed.';
    } finally {
      isLoading.value = false;
    }
  }

  // ── Error Mapping ────────────────────────────────────────────
  String _mapError(String code) {
    switch (code) {
    // ── Email / password ──
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
      // Firebase v10+ merges user-not-found + wrong-password into this
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';

    // ── Account state ──
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';

    // ── Network ──
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';

      case 'requires-recent-login':
        return 'For security, please sign out and sign in again before making this change.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      case 'expired-action-code':
        return 'This reset link has expired. Please request a new one.';
      case 'invalid-action-code':
        return 'This reset link is invalid or has already been used.';

    // ── Google ──
      case 'google-sign-in-aborted':
        return ''; // User cancelled — do not show an error

    // ── Fallback ──
      default:
        return 'Something went wrong ($code). Please try again.';
    }
  }
}
