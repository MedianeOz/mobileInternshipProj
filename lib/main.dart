import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/services/notification_service.dart';
import 'app/services/storage_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('[FCM] Background message received: ${message.messageId}');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const CyberShieldBootstrapApp());
}

class CyberShieldBootstrapApp extends StatefulWidget {
  const CyberShieldBootstrapApp({super.key});

  @override
  State<CyberShieldBootstrapApp> createState() =>
      _CyberShieldBootstrapAppState();
}

class _CyberShieldBootstrapAppState extends State<CyberShieldBootstrapApp> {
  late Future<void> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Hive.initFlutter().timeout(const Duration(seconds: 10));

    final storageService = StorageService();
    await storageService.init().timeout(const Duration(seconds: 12));
    if (!Get.isRegistered<StorageService>()) {
      Get.put<StorageService>(storageService);
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 25));

    if (!Get.isRegistered<NotificationService>()) {
      Get.put<NotificationService>(NotificationService());
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          final notificationService = Get.find<NotificationService>();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(notificationService.init());
          });
          return const CyberShieldApp();
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: _BootstrapErrorView(
              error: snapshot.error.toString(),
              onRetry: () {
                setState(() {
                  _bootstrapFuture = _bootstrap();
                });
              },
            ),
          );
        }

        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: _BootstrapLoadingView(),
        );
      },
    );
  }
}

class _BootstrapLoadingView extends StatelessWidget {
  const _BootstrapLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D0F14),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CYBERSHIELD',
                style: TextStyle(
                  color: Color(0xFF00E5A0),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.5,
                ),
              ),
              SizedBox(height: 18),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Color(0xFF00E5A0),
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BootstrapErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _BootstrapErrorView({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Could not start CyberShield',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF8A8F9E),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5A0),
                    foregroundColor: const Color(0xFF0D0F14),
                  ),
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
