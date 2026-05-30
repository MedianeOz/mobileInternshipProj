// lib/app/controllers/profile_controller.dart

import 'dart:async';

import 'package:get/get.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import 'auth_controller.dart';

class ProfileController extends GetxController {
  final AuthController authController = Get.find<AuthController>();
  final AuthService authService = Get.find<AuthService>();
  final StorageService _storageService = Get.find<StorageService>();
  final NotificationService _notificationService =
      Get.find<NotificationService>();

  Rx<UserProfile> userProfile = const UserProfile(
    uid: '',
    email: '',
    displayName: 'CyberShield User',
    watchlist: <String>[],
  ).obs;
  RxList<String> watchlist = <String>[].obs;
  RxBool criticalAlertsEnabled = true.obs;
  RxBool quietHoursEnabled = true.obs;
  RxBool allNotificationsEnabled = true.obs;
  Rxn<DateTime> lastSyncTime = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    _populateFromCurrentUser();
    _loadPersistedProfile();
    unawaited(
        _notificationService.subscribeToWatchlistTopics(watchlist.toList()));
  }

  void addTechnology(String name) {
    final value = name.trim();
    if (value.isEmpty) return;
    final exists = watchlist.any(
      (item) => item.toLowerCase() == value.toLowerCase(),
    );
    if (exists) return;
    watchlist.add(value);
    _syncProfile();
    _saveProfile();
    unawaited(_notificationService.subscribeToWatchlistTopics([value]));
  }

  void removeTechnology(String name) {
    watchlist.removeWhere(
      (item) => item.toLowerCase() == name.toLowerCase(),
    );
    _syncProfile();
    _saveProfile();
    unawaited(_notificationService.unsubscribeFromWatchlistTopics([name]));
  }

  Future<void> syncNow() async {
    lastSyncTime.value = DateTime.now();
  }

  void setCriticalAlerts(bool value) {
    criticalAlertsEnabled.value = value;
    _syncProfile();
    _saveProfile();
  }

  void setQuietHours(bool value) {
    quietHoursEnabled.value = value;
    _syncProfile();
    _saveProfile();
  }

  void setAllNotifications(bool value) {
    allNotificationsEnabled.value = value;
    _syncProfile();
    _saveProfile();
  }

  String get displayInitials {
    final displayName = userProfile.value.displayName.trim();
    final email = userProfile.value.email.trim();
    final source =
        displayName.isNotEmpty ? displayName : email.split('@').first;
    final parts = source
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'CS';
    if (parts.length == 1) {
      final cleaned = parts.first.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
      if (cleaned.isEmpty) return 'CS';
      return cleaned.substring(0, 1).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String get timeAgo {
    final lastSync = lastSyncTime.value;
    if (lastSync == null) return 'Never';
    final difference = DateTime.now().difference(lastSync);
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }

  void _populateFromCurrentUser() {
    final user = authController.currentUser.value ?? authService.currentUser;
    final email = user?.email ?? '';
    final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : _nameFromEmail(email);
    final initialWatchlist = <String>[
      'Flutter',
      'Firebase',
      'Android',
      'NVD',
    ];

    userProfile.value = UserProfile(
      uid: user?.uid ?? '',
      email: email,
      displayName: displayName,
      watchlist: initialWatchlist,
      criticalAlertsEnabled: criticalAlertsEnabled.value,
      quietHoursEnabled: quietHoursEnabled.value,
      allNotificationsEnabled: allNotificationsEnabled.value,
    );
    watchlist.assignAll(initialWatchlist);
    lastSyncTime.value = DateTime.now();
  }

  void _loadPersistedProfile() {
    final persisted = _storageService.loadProfile();
    if (persisted == null) return;

    late final UserProfile savedProfile;
    try {
      savedProfile = UserProfile.fromJson(persisted);
    } catch (_) {
      return;
    }

    final current = userProfile.value;
    criticalAlertsEnabled.value = savedProfile.criticalAlertsEnabled;
    quietHoursEnabled.value = savedProfile.quietHoursEnabled;
    allNotificationsEnabled.value = savedProfile.allNotificationsEnabled;
    watchlist.assignAll(savedProfile.watchlist);
    userProfile.value = UserProfile(
      uid: current.uid.isNotEmpty ? current.uid : savedProfile.uid,
      email: current.email.isNotEmpty ? current.email : savedProfile.email,
      displayName: current.displayName.isNotEmpty
          ? current.displayName
          : savedProfile.displayName,
      watchlist: savedProfile.watchlist,
      criticalAlertsEnabled: savedProfile.criticalAlertsEnabled,
      quietHoursEnabled: savedProfile.quietHoursEnabled,
      allNotificationsEnabled: savedProfile.allNotificationsEnabled,
    );
  }

  String _nameFromEmail(String email) {
    if (email.isEmpty) return 'CyberShield User';
    final localPart = email.split('@').first;
    final words = localPart
        .split(RegExp(r'[._-]+'))
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}');
    return words.isEmpty ? 'CyberShield User' : words.join(' ');
  }

  void _syncProfile() {
    final current = userProfile.value;
    userProfile.value = UserProfile(
      uid: current.uid,
      email: current.email,
      displayName: current.displayName,
      watchlist: watchlist.toList(),
      criticalAlertsEnabled: criticalAlertsEnabled.value,
      quietHoursEnabled: quietHoursEnabled.value,
      allNotificationsEnabled: allNotificationsEnabled.value,
    );
  }

  void _saveProfile() {
    unawaited(_storageService.saveProfile(userProfile.value.toJson()));
  }
}
