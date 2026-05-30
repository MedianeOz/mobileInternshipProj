// lib/app/services/notification_service.dart
//
// FCM integration: token retrieval, topic subscriptions, and foreground/
// background message handling. Stores received notifications to Hive.

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/notification_controller.dart';
import '../controllers/profile_controller.dart';
import '../models/app_notification.dart';
import '../routes/app_routes.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../views/shell/main_shell_view.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final StorageService _storageService = Get.find<StorageService>();
  bool _shouldOpenAlertsWhenShellReady = false;

  Future<void> init() async {
    await _requestPermission();
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    await _logToken();
    await _subscribeToBaseTopics();
    _listenForeground();
    _listenBackground();
    await _handleInitialMessage();
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    if (kDebugMode) {
      debugPrint(
          '[FCM] Permission status: ${settings.authorizationStatus.name}');
    }
  }

  Future<void> _logToken() async {
    final token = await _messaging.getToken();
    if (kDebugMode) {
      debugPrint('[FCM] Token: $token');
    }
    _messaging.onTokenRefresh.listen((token) {
      if (kDebugMode) {
        debugPrint('[FCM] Refreshed token: $token');
      }
    });
  }

  Future<void> _subscribeToBaseTopics() async {
    await _messaging.subscribeToTopic('cybershield_alerts');
  }

  Future<void> subscribeToWatchlistTopics(List<String> watchlist) async {
    for (final tech in watchlist) {
      final topic = _topicFromTech(tech);
      await _messaging.subscribeToTopic(topic);
    }
  }

  Future<void> unsubscribeFromWatchlistTopics(List<String> watchlist) async {
    for (final tech in watchlist) {
      final topic = _topicFromTech(tech);
      await _messaging.unsubscribeFromTopic(topic);
    }
  }

  String _topicFromTech(String tech) {
    return 'tech_${tech.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';
  }

  void _listenForeground() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('[FCM] Foreground message received: ${message.messageId}');
      }
      _handleMessage(message);
      final notification = _messageToNotification(message);
      if (_shouldDisplay(notification)) {
        _showForegroundSnackbar(message);
      }
    });
  }

  void _listenBackground() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('[FCM] Notification opened: ${message.messageId}');
      }
      unawaited(_handleOpenedMessage(message));
    });
  }

  Future<void> _handleInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message != null) {
      if (kDebugMode) {
        debugPrint('[FCM] Initial notification opened: ${message.messageId}');
      }
      unawaited(_handleOpenedMessage(message));
    }
  }

  void _handleMessage(RemoteMessage message) {
    final notification = _messageToNotification(message);
    if (!_shouldDisplay(notification)) return;
    unawaited(_saveAndRefresh(notification));
  }

  bool _shouldDisplay(AppNotification notification) {
    if (!Get.isRegistered<ProfileController>()) return true;

    final profile = Get.find<ProfileController>();
    return shouldDisplayForPreferences(
      notification,
      allNotificationsEnabled: profile.allNotificationsEnabled.value,
      criticalAlertsEnabled: profile.criticalAlertsEnabled.value,
      quietHoursEnabled: profile.quietHoursEnabled.value,
    );
  }

  @visibleForTesting
  static bool shouldDisplayForPreferences(
    AppNotification notification, {
    required bool allNotificationsEnabled,
    required bool criticalAlertsEnabled,
    required bool quietHoursEnabled,
    DateTime? now,
  }) {
    if (!allNotificationsEnabled) return false;

    if (criticalAlertsEnabled && !_isCriticalAlert(notification)) {
      return false;
    }

    if (quietHoursEnabled) {
      final hour = (now ?? DateTime.now()).hour;
      if (hour >= 22 || hour < 7) return false;
    }

    return true;
  }

  static bool _isCriticalAlert(AppNotification notification) {
    final severity = (notification.severity ?? '').toUpperCase();
    return severity == 'CRITICAL' ||
        severity == 'HIGH' ||
        (notification.baseScore ?? 0) >= 9.0;
  }

  Future<void> _saveAndRefresh(AppNotification notification) async {
    await _storageService.saveNotification(notification.toJson());
    if (!Get.isRegistered<NotificationController>()) return;

    final controller = Get.find<NotificationController>();
    controller.addNotificationInMemory(notification);
    controller.refreshFromStorage();
  }

  Future<void> _handleOpenedMessage(RemoteMessage message) async {
    final notification = _messageToNotification(message).copyWith(isRead: true);
    if (!_shouldDisplay(notification)) return;

    await _saveAndRefresh(notification);
    await _storageService.markNotificationRead(notification.id);

    if (Get.isRegistered<NotificationController>()) {
      Get.find<NotificationController>().refreshFromStorage();
    }
    openAlertsWhenReady();
  }

  void openAlertsWhenReady() {
    _shouldOpenAlertsWhenShellReady = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_shouldOpenAlertsWhenShellReady) return;
      if (Get.isRegistered<MainShellViewState>()) {
        _shouldOpenAlertsWhenShellReady = false;
        Get.find<MainShellViewState>().switchToTab(3);
        return;
      }

      final currentRoute = Get.currentRoute;
      final onAuthRoute = currentRoute == AppRoutes.LOGIN ||
          currentRoute == AppRoutes.REGISTER ||
          currentRoute == AppRoutes.FORGOT_PASSWORD ||
          currentRoute.isEmpty;
      if (!onAuthRoute) {
        Get.offAllNamed(AppRoutes.SHELL);
      }
    });
  }

  bool consumePendingAlertsOpen() {
    if (!_shouldOpenAlertsWhenShellReady) return false;
    _shouldOpenAlertsWhenShellReady = false;
    return true;
  }

  AppNotification _messageToNotification(RemoteMessage message) {
    final data = message.data;
    final title = message.notification?.title ??
        _firstDataValue(data, const [
          'title',
          'notificationTitle',
          'notification_title',
          'alertTitle',
          'alert_title',
        ]) ??
        'CyberShield Alert';
    final body = message.notification?.body ??
        _firstDataValue(data, const [
          'body',
          'message',
          'description',
          'summary',
          'notificationBody',
          'notification_body',
          'alertBody',
          'alert_body',
        ]) ??
        '';
    final cveId = _firstDataValue(data, const [
      'cveId',
      'cveID',
      'cve_id',
      'cve',
      'id',
    ]);
    final baseScoreRaw = _firstDataValue(data, const [
      'baseScore',
      'base_score',
      'cvssScore',
      'cvss_score',
      'score',
    ]);
    final baseScore =
        baseScoreRaw != null ? double.tryParse(baseScoreRaw) : null;

    return AppNotification(
      id: message.messageId ??
          _firstDataValue(data, const ['notificationId', 'notification_id']) ??
          cveId ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      severity: _firstDataValue(data, const [
        'severity',
        'level',
        'priority',
      ]),
      cveId: cveId,
      baseScore: baseScore,
      timestamp: DateTime.now(),
      isRead: false,
    );
  }

  String? _firstDataValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  void _showForegroundSnackbar(RemoteMessage message) {
    final data = message.data;
    final title = message.notification?.title ??
        data['title']?.toString() ??
        'CyberShield Alert';
    final body = message.notification?.body ?? data['body']?.toString() ?? '';
    final severityColor = _snackbarSeverityColor(data['severity']?.toString());

    Get.showSnackbar(
      GetSnackBar(
        title: title,
        message: body,
        backgroundColor: AppColors.surface,
        borderColor: severityColor,
        borderWidth: 1,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 8),
        snackPosition: SnackPosition.TOP,
        icon: Icon(
          Icons.notifications_active_outlined,
          color: severityColor,
          size: 22,
        ),
        shouldIconPulse: false,
        titleText: Text(
          title,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        messageText: Text(
          body,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        mainButton: TextButton(
          onPressed: () {
            Get.closeCurrentSnackbar();
            unawaited(_handleOpenedMessage(message));
          },
          child: Text(
            'View',
            style: TextStyle(
              color: severityColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        onTap: (_) {
          Get.closeCurrentSnackbar();
          unawaited(_handleOpenedMessage(message));
        },
      ),
    );
  }

  Color _snackbarSeverityColor(String? severity) {
    switch (severity?.toUpperCase()) {
      case 'CRITICAL':
        return AppColors.danger;
      case 'HIGH':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }
}
