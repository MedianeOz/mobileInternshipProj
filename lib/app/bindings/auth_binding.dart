import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AuthService>()) {
      Get.put(AuthService());
    }
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController());
    }
  }
}
