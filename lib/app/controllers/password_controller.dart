// lib/app/controllers/password_controller.dart
//
// Manages password breach checks, password visibility, and result/error state
// for the Password Health screen.

import 'package:get/get.dart';

import '../models/password_check_result.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';

class PasswordController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  RxBool isChecking = false.obs;
  RxString errorMessage = ''.obs;
  Rxn<PasswordCheckResult> result = Rxn<PasswordCheckResult>();
  RxBool obscurePassword = true.obs;

  // -- Breach check --
  Future<void> checkPassword(String password) async {
    errorMessage.value = '';
    result.value = null;

    final validationError = Validators.password(password);
    if (validationError != null) {
      errorMessage.value = validationError;
      return;
    }

    isChecking.value = true;

    try {
      final checkResult = await _apiService.checkPassword(password);
      if (_apiService.errorMessage.isNotEmpty) {
        errorMessage.value = _apiService.errorMessage;
        return;
      }
      result.value = checkResult;
    } catch (_) {
      errorMessage.value =
          'Could not connect to breach database. Please try again.';
    } finally {
      isChecking.value = false;
    }
  }

  // -- Reset --
  void clearResult() {
    errorMessage.value = '';
    result.value = null;
  }
}
