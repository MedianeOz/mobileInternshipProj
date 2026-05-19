// lib/app/bindings/password_binding.dart
//
// Registers dependencies for the Password Health feature.

import 'package:get/get.dart';

import '../controllers/password_controller.dart';
import '../services/api_service.dart';

class PasswordBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ApiService>()) {
      Get.put(ApiService());
    }
    if (!Get.isRegistered<PasswordController>()) {
      Get.put(PasswordController());
    }
  }
}
