// lib/app/bindings/knowledge_binding.dart

import 'package:get/get.dart';

import '../controllers/knowledge_controller.dart';
import '../services/storage_service.dart';

class KnowledgeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<StorageService>()) {
      Get.lazyPut<StorageService>(() => StorageService(), fenix: true);
    }
    if (!Get.isRegistered<KnowledgeController>()) {
      Get.lazyPut<KnowledgeController>(() => KnowledgeController(),
          fenix: true);
    }
  }
}
