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
  static const Duration _messagingTimeout = Duration(seconds: 8);
  final Map<String, bool> _desiredTopicSubscriptions = <String, bool>{};
  bool _shouldOpenAlertsWhenShellReady = false;
  bool _isInitialized = false;
  Future<void> _topicQueue = Future<void>.value();

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    _listenForeground();
    _listenBackground();
    unawaited(_handleInitialMessage());
    unawaited(_configureMessaging());
  }

  Future<void> _configureMessaging() async {
    await _requestPermission();
    await _guardMessagingCall(
      _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      ),
      operation: 'set foreground presentation options',
    );
    await _logToken();
    await _subscribeToBaseTopics();
  }

  Future<void> _requestPermission() async {
    final settings = await _guardMessagingCall(
      _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      ),
      operation: 'request permission',
    );
    if (settings == null) return;
    if (kDebugMode) {
      debugPrint(
          '[FCM] Permission status: ${settings.authorizationStatus.name}');
    }
  }

  Future<void> _logToken() async {
    final token = await _guardMessagingCall(
      _messaging.getToken(),
      operation: 'get token',
    );
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
    await syncAlertTopicSubscriptions(
      allNotificationsEnabled: true,
      criticalAlertsEnabled: false,
    );
  }

  Future<void> syncAlertTopicSubscriptions({
    bool? allNotificationsEnabled,
    bool? criticalAlertsEnabled,
  }) async {
    final profile = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : null;
    final allEnabled =
        allNotificationsEnabled ?? profile?.allNotificationsEnabled.value;
    final criticalOnly =
        criticalAlertsEnabled ?? profile?.criticalAlertsEnabled.value;

    if (allEnabled == false) {
      await _unsubscribeFromTopic(AppStrings.fcmAllAlertsTopic);
      await _unsubscribeFromTopic(AppStrings.fcmCriticalAlertsTopic);
      return;
    }

    if (criticalOnly == true) {
      await _unsubscribeFromTopic(AppStrings.fcmAllAlertsTopic);
      await _subscribeToTopic(AppStrings.fcmCriticalAlertsTopic);
      return;
    }

    await _subscribeToTopic(AppStrings.fcmAllAlertsTopic);
    await _unsubscribeFromTopic(AppStrings.fcmCriticalAlertsTopic);
  }

  Future<void> subscribeToWatchlistTopics(List<String> watchlist) async {
    final topics = watchlist
        .map(_topicFromTech)
        .where((topic) => topic.isNotEmpty)
        .toSet();
    for (final topic in topics) {
      await _subscribeToTopic(topic);
    }
  }

  Future<void> unsubscribeFromWatchlistTopics(List<String> watchlist) async {
    final topics = watchlist
        .map(_topicFromTech)
        .where((topic) => topic.isNotEmpty)
        .toSet();
    for (final topic in topics) {
      await _unsubscribeFromTopic(topic);
    }
  }

  String _topicFromTech(String tech) {
    final normalized = tech
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    if (normalized.isEmpty) return '';
    return 'tech_$normalized';
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

  Future<void> _subscribeToTopic(String topic) async {
    await _setTopicSubscription(topic, shouldSubscribe: true);
  }

  Future<void> _unsubscribeFromTopic(String topic) async {
    await _setTopicSubscription(topic, shouldSubscribe: false);
  }

  Future<void> _setTopicSubscription(
    String topic, {
    required bool shouldSubscribe,
  }) {
    final normalizedTopic = topic.trim();
    if (normalizedTopic.isEmpty) return Future<void>.value();

    if (_desiredTopicSubscriptions[normalizedTopic] == shouldSubscribe) {
      return Future<void>.value();
    }
    _desiredTopicSubscriptions[normalizedTopic] = shouldSubscribe;

    _topicQueue = _topicQueue.then(
      (_) => _applyLatestTopicSubscription(normalizedTopic),
    );
    return _topicQueue;
  }

  Future<void> _applyLatestTopicSubscription(String topic) async {
    final shouldSubscribe = _desiredTopicSubscriptions[topic];
    if (shouldSubscribe == null) return;

    if (shouldSubscribe) {
      await _guardMessagingCall(
        _messaging.subscribeToTopic(topic),
        operation: 'subscribe to $topic',
      );
      return;
    }

    await _guardMessagingCall(
      _messaging.unsubscribeFromTopic(topic),
      operation: 'unsubscribe from $topic',
    );
  }

  Future<T?> _guardMessagingCall<T>(
    Future<T> future, {
    required String operation,
  }) async {
    try {
      return await future.timeout(_messagingTimeout);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[FCM] Could not $operation: $error');
      }
      return null;
    }
  }
}
