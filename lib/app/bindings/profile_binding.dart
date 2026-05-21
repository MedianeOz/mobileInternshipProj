// lib/app/bindings/profile_binding.dart

import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../services/auth_service.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AuthService>()) {
      Get.put(AuthService());
    }
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController());
    }
    if (!Get.isRegistered<ProfileController>()) {
      Get.put(ProfileController());
    }
  }
}
