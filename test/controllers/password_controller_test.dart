import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cybershield_app/app/controllers/password_controller.dart';
import 'package:cybershield_app/app/models/password_check_result.dart';
import 'package:cybershield_app/app/services/api_service.dart';
import 'package:cybershield_app/app/utils/password_analyzer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';

import '../helpers/mocks.mocks.dart';
import '../helpers/test_helpers.dart';

void main() {
  setupGetX();

  late MockApiService apiService;

  PasswordController buildController({
    Future<List<ConnectivityResult>> Function()? checkConnectivity,
  }) {
    Get.put<ApiService>(apiService);
    return Get.put(
      PasswordController(
        checkConnectivity:
            checkConnectivity ?? () async => const [ConnectivityResult.wifi],
      ),
    );
  }

  setUp(() {
    apiService = MockApiService();
    when(apiService.errorMessage).thenReturn('');
  });

  group('PasswordController', () {
    test('analyzePassword empty returns empty and resets breach state', () {
      final controller = buildController()
        ..breachResult.value = const PasswordCheckResult(
          isPwned: true,
          breachCount: 1,
        )
        ..isBreachChecked.value = true;

      controller.analyzePassword('x');
      controller.analyzePassword('');

      expect(controller.strengthResult.value.level, PasswordStrength.empty);
      expect(controller.isBreachChecked.value, isFalse);
    });

    test('analyzePassword non-empty updates strength', () {
      final controller = buildController();

      controller.analyzePassword('Hello123!');

      expect(
          controller.strengthResult.value.level, isNot(PasswordStrength.empty));
    });

    test('analyzePassword sets password value', () {
      final controller = buildController();

      controller.analyzePassword('Hello123!');

      expect(controller.password.value, 'Hello123!');
    });

    test('analyzePassword resets breach result and checked flag', () {
      final controller = buildController()
        ..breachResult.value = const PasswordCheckResult(
          isPwned: true,
          breachCount: 10,
        )
        ..isBreachChecked.value = true;

      controller.analyzePassword('new-password');

      expect(controller.breachResult.value, isNull);
      expect(controller.isBreachChecked.value, isFalse);
    });

    test('clearAll resets all observables to initial state', () {
      final controller = buildController()
        ..analyzePassword('Hello123!')
        ..breachResult.value = const PasswordCheckResult(
          isPwned: true,
          breachCount: 10,
        )
        ..isBreachChecked.value = true
        ..errorMessage.value = 'error'
        ..isChecking.value = true
        ..obscureText.value = false;

      controller.clearAll();

      expect(controller.password.value, '');
      expect(controller.strengthResult.value.level, PasswordStrength.empty);
      expect(controller.breachResult.value, isNull);
      expect(controller.isBreachChecked.value, isFalse);
      expect(controller.errorMessage.value, '');
      expect(controller.isChecking.value, isFalse);
      expect(controller.obscureText.value, isTrue);
    });

    test('checkBreach on empty password returns without setting isChecking',
        () async {
      final controller = buildController();

      await controller.checkBreach();

      expect(controller.isChecking.value, isFalse);
      verifyNever(apiService.checkPassword(any));
    });

    test('checkBreach while isChecking is true is ignored', () async {
      final controller = buildController()
        ..analyzePassword('Hello123!')
        ..isChecking.value = true;

      await controller.checkBreach();

      verifyNever(apiService.checkPassword(any));
    });

    test('checkBreach on success sets checked flag and result', () async {
      when(apiService.checkPassword(any)).thenAnswer(
        (_) async => const PasswordCheckResult(isPwned: false, breachCount: 0),
      );
      final controller = buildController()..analyzePassword('Hello123!');

      await controller.checkBreach();

      expect(controller.isBreachChecked.value, isTrue);
      expect(controller.breachResult.value, isNotNull);
    });

    test('checkBreach uses ApiService error message', () async {
      when(apiService.checkPassword(any)).thenAnswer(
        (_) async => const PasswordCheckResult(isPwned: false, breachCount: 0),
      );
      when(apiService.errorMessage).thenReturn('HIBP unavailable');
      final controller = buildController()..analyzePassword('Hello123!');

      await controller.checkBreach();

      expect(controller.errorMessage.value, 'HIBP unavailable');
    });

    test('checkBreach when connection is none sets offline message', () async {
      final controller = buildController(
        checkConnectivity: () async => const [ConnectivityResult.none],
      )..analyzePassword('Hello123!');

      await controller.checkBreach();

      expect(controller.errorMessage.value, contains('No internet connection'));
      verifyNever(apiService.checkPassword(any));
    });

    test('checkBreach always resets isChecking in finally', () async {
      final completer = Completer<PasswordCheckResult>();
      when(apiService.checkPassword(any)).thenAnswer((_) => completer.future);
      final controller = buildController()..analyzePassword('Hello123!');

      final future = controller.checkBreach();
      expect(controller.isChecking.value, isTrue);
      completer.completeError(Exception('boom'));
      await future;

      expect(controller.isChecking.value, isFalse);
    });
  });
}
