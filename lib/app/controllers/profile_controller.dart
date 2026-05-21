// lib/app/controllers/profile_controller.dart

import 'package:get/get.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import 'auth_controller.dart';

class ProfileController extends GetxController {
  final AuthController authController = Get.find<AuthController>();
  final AuthService authService = Get.find<AuthService>();

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
  }

  void removeTechnology(String name) {
    watchlist.removeWhere(
      (item) => item.toLowerCase() == name.toLowerCase(),
    );
    _syncProfile();
  }

  Future<void> syncNow() async {
    lastSyncTime.value = DateTime.now();
  }

  void setCriticalAlerts(bool value) {
    criticalAlertsEnabled.value = value;
    _syncProfile();
  }

  void setQuietHours(bool value) {
    quietHoursEnabled.value = value;
    _syncProfile();
  }

  void setAllNotifications(bool value) {
    allNotificationsEnabled.value = value;
    _syncProfile();
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
}
