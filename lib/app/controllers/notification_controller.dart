// lib/app/controllers/notification_controller.dart
//
// Manages the in-app notification history list, unread badge count, and
// read/clear operations.

import 'dart:async';

import 'package:get/get.dart';

import '../models/app_notification.dart';
import '../models/threat_advisory.dart';
import '../routes/app_routes.dart';
import '../services/storage_service.dart';

class NotificationController extends GetxController {
  RxList<AppNotification> notifications = <AppNotification>[].obs;
  RxInt unreadCount = 0.obs;
  RxBool isLoading = false.obs;
  RxString selectedSeverityFilter = ''.obs;

  @override
  void onInit() {
    super.onInit();
    refreshFromStorage();
  }

  void refreshFromStorage() {
    final storageService = Get.find<StorageService>();
    final rawList = storageService.getNotificationHistory();
    final parsed = rawList
        .map((json) => AppNotification.fromJson(json))
        .where((notification) => notification.id.isNotEmpty)
        .toList();
    notifications.assignAll(parsed);
    unreadCount.value = storageService.getUnreadNotificationCount();
  }

  void addNotificationInMemory(AppNotification notification) {
    final existingIndex =
        notifications.indexWhere((item) => item.id == notification.id);
    if (existingIndex != -1) {
      notifications[existingIndex] = notification;
      _updateUnreadCount();
      return;
    }

    notifications.insert(0, notification);
    _updateUnreadCount();
  }

  void openNotification(AppNotification notification) {
    unawaited(markAsRead(notification.id));

    final cveId = notification.cveId;
    if (cveId == null || cveId.isEmpty) return;

    final advisory = ThreatAdvisory(
      id: cveId,
      description: notification.body.isNotEmpty
          ? notification.body
          : 'No description available for this advisory.',
      baseScore:
          notification.baseScore ?? _scoreFromSeverity(notification.severity),
      severity: _normalizeSeverity(notification.severity),
      publishedDate: notification.timestamp,
      lastModifiedDate: notification.timestamp,
      referenceUrls: const [],
    );
    Get.toNamed(AppRoutes.THREAT_DETAIL, arguments: advisory);
  }

  void filterBySeverity(String severity) {
    selectedSeverityFilter.value =
        severity.toUpperCase() == 'ALL' ? '' : severity.toUpperCase();
  }

  List<AppNotification> get filteredNotifications {
    if (selectedSeverityFilter.value.isEmpty) return notifications;
    return notifications
        .where((notification) =>
            (notification.severity?.toUpperCase() ?? '') ==
            selectedSeverityFilter.value)
        .toList();
  }

  Future<void> markAsRead(String id) async {
    final storageService = Get.find<StorageService>();
    await storageService.markNotificationRead(id);
    refreshFromStorage();
  }

  Future<void> markAllRead() async {
    final updated = notifications
        .map((notification) => notification.copyWith(isRead: true))
        .toList();
    notifications.assignAll(updated);
    unreadCount.value = 0;

    final storageService = Get.find<StorageService>();
    await storageService.markAllNotificationsRead();
  }

  Future<void> clearAll() async {
    final storageService = Get.find<StorageService>();
    await storageService.clearNotificationHistory();
    refreshFromStorage();
  }

  int get currentUnreadCount => unreadCount.value;

  void _updateUnreadCount() {
    unreadCount.value = notifications.where((item) => !item.isRead).length;
  }

  double _scoreFromSeverity(String? severity) {
    switch (severity?.toUpperCase()) {
      case 'CRITICAL':
        return 9.8;
      case 'HIGH':
        return 7.5;
      case 'MEDIUM':
        return 5.0;
      case 'LOW':
        return 2.0;
      default:
        return 0.0;
    }
  }

  String _normalizeSeverity(String? severity) {
    const supported = {'CRITICAL', 'HIGH', 'MEDIUM', 'LOW'};
    final value = (severity ?? '').toUpperCase();
    return supported.contains(value) ? value : 'UNKNOWN';
  }
}
