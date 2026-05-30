import 'package:cybershield_app/app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../helpers/mocks.mocks.dart';

void main() {
  late MockFirebaseAuth firebaseAuth;
  late MockGoogleSignIn googleSignIn;
  late MockFlutterSecureStorage storage;
  late MockUserCredential credential;
  late AuthService service;

  setUp(() {
    firebaseAuth = MockFirebaseAuth();
    googleSignIn = MockGoogleSignIn();
    storage = MockFlutterSecureStorage();
    credential = MockUserCredential();
    service = AuthService(
      firebaseAuth: firebaseAuth,
      googleSignIn: googleSignIn,
      storage: storage,
    );
  });

  group('AuthService', () {
    test('signUpWithEmail writes logged-in flag on success', () async {
      when(
        firebaseAuth.createUserWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async => credential);
      when(storage.write(key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async {});

      final result = await service.signUpWithEmail('user@example.com', 'pass');

      expect(result, credential);
      verify(storage.write(key: 'is_logged_in', value: 'true')).called(1);
    });

    test('signUpWithEmail rethrows FirebaseAuthException on failure', () async {
      when(
        firebaseAuth.createUserWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      expect(
        service.signUpWithEmail('user@example.com', 'pass'),
        throwsA(isA<FirebaseAuthException>()),
      );
    });

    test('signInWithEmail writes logged-in flag on success', () async {
      when(
        firebaseAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async => credential);
      when(storage.write(key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async {});

      final result = await service.signInWithEmail('user@example.com', 'pass');

      expect(result, credential);
      verify(storage.write(key: 'is_logged_in', value: 'true')).called(1);
    });

    test('signInWithEmail rethrows FirebaseAuthException with original code',
        () async {
      when(
        firebaseAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenThrow(FirebaseAuthException(code: 'wrong-password'));

      await expectLater(
        service.signInWithEmail('user@example.com', 'bad'),
        throwsA(
          isA<FirebaseAuthException>()
              .having((error) => error.code, 'code', 'wrong-password'),
        ),
      );
    });

    test('signOut signs out providers and deletes secure storage key',
        () async {
      when(googleSignIn.signOut()).thenAnswer((_) async => null);
      when(firebaseAuth.signOut()).thenAnswer((_) async {});
      when(storage.delete(key: anyNamed('key'))).thenAnswer((_) async {});

      await service.signOut();

      verify(googleSignIn.signOut()).called(1);
      verify(firebaseAuth.signOut()).called(1);
      verify(storage.delete(key: 'is_logged_in')).called(1);
    });

    test('signOut rethrows FirebaseAuthException on failure', () async {
      when(googleSignIn.signOut()).thenAnswer((_) async => null);
      when(firebaseAuth.signOut()).thenThrow(
        FirebaseAuthException(code: 'network-request-failed'),
      );

      await expectLater(
        service.signOut(),
        throwsA(
          isA<FirebaseAuthException>().having(
            (error) => error.code,
            'code',
            'network-request-failed',
          ),
        ),
      );
    });

    test('sendPasswordResetEmail calls FirebaseAuth', () async {
      when(firebaseAuth.sendPasswordResetEmail(email: anyNamed('email')))
          .thenAnswer((_) async {});

      await service.sendPasswordResetEmail('user@example.com');

      verify(firebaseAuth.sendPasswordResetEmail(email: 'user@example.com'))
          .called(1);
    });

    test('signInWithGoogle throws aborted when GoogleSignIn returns null',
        () async {
      when(googleSignIn.signIn()).thenAnswer((_) async => null);

      await expectLater(
        service.signInWithGoogle(),
        throwsA(
          isA<FirebaseAuthException>().having(
            (error) => error.code,
            'code',
            'google-sign-in-aborted',
          ),
        ),
      );
    });
  });
}
