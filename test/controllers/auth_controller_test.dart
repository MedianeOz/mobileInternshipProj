import 'dart:async';

import 'package:cybershield_app/app/controllers/auth_controller.dart';
import 'package:cybershield_app/app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';

import '../helpers/mocks.mocks.dart';
import '../helpers/test_helpers.dart';

void main() {
  setupGetX();

  late MockAuthService authService;
  late MockUserCredential credential;
  late MockUser user;

  AuthController buildController() {
    Get.put<AuthService>(authService);
    return Get.put(AuthController());
  }

  setUp(() {
    authService = MockAuthService();
    credential = MockUserCredential();
    user = MockUser();
    when(authService.currentUser).thenReturn(null);
    when(authService.authStateChanges).thenAnswer((_) => const Stream.empty());
    when(credential.user).thenReturn(user);
  });

  group('AuthController', () {
    test('onInit sets currentUser from authService.currentUser', () {
      when(authService.currentUser).thenReturn(user);

      final controller = buildController();

      expect(controller.currentUser.value, user);
    });

    test('login sets isLoading true then false', () async {
      final completer = Completer<UserCredential>();
      when(authService.signInWithEmail(any, any))
          .thenAnswer((_) => completer.future);
      final controller = buildController();

      final future = controller.login('user@example.com', 'password');

      expect(controller.isLoading.value, isTrue);
      completer.complete(credential);
      await future;
      expect(controller.isLoading.value, isFalse);
    });

    test('login on success sets currentUser', () async {
      when(authService.signInWithEmail(any, any))
          .thenAnswer((_) async => credential);
      final controller = buildController();

      await controller.login('user@example.com', 'password');

      expect(controller.currentUser.value, user);
    });

    test('login maps wrong-password error', () async {
      when(authService.signInWithEmail(any, any)).thenThrow(
        FirebaseAuthException(code: 'wrong-password'),
      );
      final controller = buildController();

      await controller.login('user@example.com', 'bad');

      expect(controller.errorMessage.value,
          'Incorrect password. Please try again.');
    });

    test('login maps invalid-credential error', () async {
      when(authService.signInWithEmail(any, any)).thenThrow(
        FirebaseAuthException(code: 'invalid-credential'),
      );
      final controller = buildController();

      await controller.login('user@example.com', 'bad');

      expect(controller.errorMessage.value, 'Invalid email or password.');
    });

    test('login maps user-not-found error', () async {
      when(authService.signInWithEmail(any, any)).thenThrow(
        FirebaseAuthException(code: 'user-not-found'),
      );
      final controller = buildController();

      await controller.login('missing@example.com', 'password');

      expect(
          controller.errorMessage.value, 'No account found with this email.');
    });

    test('login maps network-request-failed error', () async {
      when(authService.signInWithEmail(any, any)).thenThrow(
        FirebaseAuthException(code: 'network-request-failed'),
      );
      final controller = buildController();

      await controller.login('user@example.com', 'password');

      expect(
        controller.errorMessage.value,
        'No internet connection. Please check your network.',
      );
    });

    test('login maps too-many-requests error', () async {
      when(authService.signInWithEmail(any, any)).thenThrow(
        FirebaseAuthException(code: 'too-many-requests'),
      );
      final controller = buildController();

      await controller.login('user@example.com', 'password');

      expect(
        controller.errorMessage.value,
        'Too many attempts. Please wait a moment and try again.',
      );
    });

    test('register maps email-already-in-use error', () async {
      when(authService.signUpWithEmail(any, any)).thenThrow(
        FirebaseAuthException(code: 'email-already-in-use'),
      );
      final controller = buildController();

      await controller.register('used@example.com', 'password');

      expect(
        controller.errorMessage.value,
        'An account with this email already exists.',
      );
    });

    test('register maps weak-password error', () async {
      when(authService.signUpWithEmail(any, any)).thenThrow(
        FirebaseAuthException(code: 'weak-password'),
      );
      final controller = buildController();

      await controller.register('user@example.com', '123');

      expect(
        controller.errorMessage.value,
        'Password is too weak. Use at least 6 characters.',
      );
    });

    test('loginWithGoogle aborted does not set errorMessage', () async {
      when(authService.signInWithGoogle()).thenThrow(
        FirebaseAuthException(code: 'google-sign-in-aborted'),
      );
      final controller = buildController();

      await controller.loginWithGoogle();

      expect(controller.errorMessage.value, '');
    });

    test('resetPassword on success clears errorMessage', () async {
      when(authService.sendPasswordResetEmail(any)).thenAnswer((_) async {});
      final controller = buildController()..errorMessage.value = 'stale';

      await controller.resetPassword('user@example.com');

      expect(controller.errorMessage.value, '');
    });

    test('resetPassword maps FirebaseAuthException', () async {
      when(authService.sendPasswordResetEmail(any)).thenThrow(
        FirebaseAuthException(code: 'invalid-email'),
      );
      final controller = buildController();

      await controller.resetPassword('bad-email');

      expect(
          controller.errorMessage.value, 'Please enter a valid email address.');
    });

    test('logout calls service and sets currentUser to null', () async {
      when(authService.signOut()).thenAnswer((_) async {});
      final controller = buildController()..currentUser.value = user;

      await controller.logout();

      verify(authService.signOut()).called(1);
      expect(controller.currentUser.value, isNull);
    });

    test('errorMessage is cleared at the start of key methods', () async {
      final loginCompleter = Completer<UserCredential>();
      when(authService.signInWithEmail(any, any))
          .thenAnswer((_) => loginCompleter.future);
      final controller = buildController()..errorMessage.value = 'stale';
      final loginFuture = controller.login('user@example.com', 'password');
      expect(controller.errorMessage.value, '');
      loginCompleter.complete(credential);
      await loginFuture;

      final registerCompleter = Completer<UserCredential>();
      when(authService.signUpWithEmail(any, any))
          .thenAnswer((_) => registerCompleter.future);
      controller.errorMessage.value = 'stale';
      final registerFuture =
          controller.register('user@example.com', 'password');
      expect(controller.errorMessage.value, '');
      registerCompleter.complete(credential);
      await registerFuture;

      final resetCompleter = Completer<void>();
      when(authService.sendPasswordResetEmail(any))
          .thenAnswer((_) => resetCompleter.future);
      controller.errorMessage.value = 'stale';
      final resetFuture = controller.resetPassword('user@example.com');
      expect(controller.errorMessage.value, '');
      resetCompleter.complete();
      await resetFuture;

      final logoutCompleter = Completer<void>();
      when(authService.signOut()).thenAnswer((_) => logoutCompleter.future);
      controller.errorMessage.value = 'stale';
      final logoutFuture = controller.logout();
      expect(controller.errorMessage.value, '');
      logoutCompleter.complete();
      await logoutFuture;
    });
  });
}
