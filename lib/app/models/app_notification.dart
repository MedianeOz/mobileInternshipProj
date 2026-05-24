// lib/app/models/app_notification.dart
//
// Represents a single FCM push notification stored in the in-app history.

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String? severity;
  final String? cveId;
  final DateTime timestamp;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.severity,
    this.cveId,
    required this.timestamp,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final cveId = _firstJsonValue(json, const [
      'cveId',
      'cveID',
      'cve_id',
      'cve',
    ]);

    return AppNotification(
      id: json['id']?.toString() ?? '',
      title: _firstJsonValue(json, const [
            'title',
            'notificationTitle',
            'notification_title',
            'alertTitle',
            'alert_title',
          ]) ??
          'CyberShield Alert',
      body: _firstJsonValue(json, const [
            'body',
            'message',
            'description',
            'summary',
            'notificationBody',
            'notification_body',
            'alertBody',
            'alert_body',
          ]) ??
          '',
      severity: _firstJsonValue(json, const [
        'severity',
        'level',
        'priority',
      ]),
      cveId: cveId,
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'severity': severity,
      'cveId': cveId,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      severity: severity,
      cveId: cveId,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  static String? _firstJsonValue(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }
}
