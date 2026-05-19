// lib/app/models/user_profile.dart
//
// Stores CyberShield profile preferences that drive watchlists,
// notification filtering, and profile display.

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final List<String> watchlist;
  final bool criticalAlertsEnabled;
  final bool quietHoursEnabled;
  final bool allNotificationsEnabled;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.watchlist,
    this.criticalAlertsEnabled = true,
    this.quietHoursEnabled = true,
    this.allNotificationsEnabled = true,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      watchlist: (json['watchlist'] as List?)
              ?.map((item) => item.toString())
              .where((item) => item.isNotEmpty)
              .toList() ??
          <String>[],
      criticalAlertsEnabled: json['criticalAlertsEnabled'] as bool? ?? true,
      quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? true,
      allNotificationsEnabled: json['allNotificationsEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'watchlist': watchlist,
      'criticalAlertsEnabled': criticalAlertsEnabled,
      'quietHoursEnabled': quietHoursEnabled,
      'allNotificationsEnabled': allNotificationsEnabled,
    };
  }
}
