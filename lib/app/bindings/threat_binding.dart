// lib/app/bindings/threat_binding.dart
//
// Registers dependencies needed by threat intelligence routes.

import 'package:get/get.dart';

import '../controllers/threat_feed_controller.dart';
import '../services/api_service.dart';

class ThreatBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ApiService>()) {
      Get.put(ApiService());
    }
    if (!Get.isRegistered<ThreatFeedController>()) {
      Get.put(ThreatFeedController());
    }
  }
}
