import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/services/storage_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final storageService = StorageService();
  await storageService.init();
  Get.put<StorageService>(storageService);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CyberShieldApp());
}

class CyberShieldApp extends StatelessWidget {
  const CyberShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'CyberShield',
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.LOGIN,
      getPages: AppPages.routes,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}
