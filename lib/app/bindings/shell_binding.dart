// lib/app/bindings/shell_binding.dart
//
// Registers shared authenticated-app dependencies for the persistent tab shell.

import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/password_controller.dart';
import '../controllers/threat_feed_controller.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class ShellBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AuthService>()) {
      Get.put(AuthService());
    }
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController());
    }
    if (!Get.isRegistered<ApiService>()) {
      Get.put(ApiService());
    }
    if (!Get.isRegistered<ThreatFeedController>()) {
      Get.put(ThreatFeedController());
    }
    if (!Get.isRegistered<PasswordController>()) {
      Get.put(PasswordController());
    }
  }
}
