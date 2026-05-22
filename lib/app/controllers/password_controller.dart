// lib/app/controllers/password_controller.dart
//
// Manages local password analysis, breach checks, visibility, and result state
// for the Password Shield screen.

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

import '../models/password_check_result.dart';
import '../services/api_service.dart';
import '../utils/password_analyzer.dart';

class PasswordController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  static const _offlineBreachMessage =
      'No internet connection. Breach check requires network access. Your local strength analysis is still accurate.';

  RxString password = ''.obs;
  Rx<PasswordStrengthResult> strengthResult = PasswordAnalyzer.evaluate('').obs;
  RxBool isBreachChecked = false.obs;
  Rxn<PasswordCheckResult> breachResult = Rxn<PasswordCheckResult>();
  RxString errorMessage = ''.obs;
  RxBool isChecking = false.obs;
  RxBool obscureText = true.obs;

  void analyzePassword(String value) {
    password.value = value;
    strengthResult.value = PasswordAnalyzer.evaluate(value);
    isBreachChecked.value = false;
    breachResult.value = null;
    errorMessage.value = '';
  }

  Future<void> checkBreach() async {
    final currentPassword = password.value;
    if (currentPassword.isEmpty || isChecking.value) {
      return;
    }

    isChecking.value = true;
    errorMessage.value = '';
    breachResult.value = null;
    isBreachChecked.value = false;

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        errorMessage.value = _offlineBreachMessage;
        isChecking.value = false;
        return;
      }

      final checkResult = await _apiService.checkPassword(currentPassword);
      if (_apiService.errorMessage.isNotEmpty) {
        errorMessage.value = _isNetworkError(_apiService.errorMessage)
            ? _offlineBreachMessage
            : _apiService.errorMessage;
        return;
      }
      breachResult.value = checkResult;
      isBreachChecked.value = true;
    } catch (_) {
      final connectivityResult = await Connectivity().checkConnectivity();
      errorMessage.value = connectivityResult.contains(ConnectivityResult.none)
          ? _offlineBreachMessage
          : 'Could not connect to breach database. Please try again.';
    } finally {
      isChecking.value = false;
    }
  }

  void clearAll() {
    password.value = '';
    strengthResult.value = PasswordAnalyzer.evaluate('');
    isBreachChecked.value = false;
    breachResult.value = null;
    errorMessage.value = '';
    isChecking.value = false;
    obscureText.value = true;
  }

  bool _isNetworkError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('network') ||
        normalized.contains('connect') ||
        normalized.contains('connection');
  }
}
