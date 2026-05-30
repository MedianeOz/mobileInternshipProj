import 'package:cybershield_app/app/models/app_notification.dart';
import 'package:cybershield_app/app/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationService preferences', () {
    AppNotification notification({
      String severity = 'MEDIUM',
      double? baseScore,
    }) {
      return AppNotification(
        id: 'notification-$severity-${baseScore ?? 'none'}',
        title: 'Alert',
        body: 'Body',
        severity: severity,
        baseScore: baseScore,
        timestamp: DateTime(2026, 5, 28, 12),
      );
    }

    test('critical alerts off allows both critical and non-critical alerts',
        () {
      final medium = notification(severity: 'MEDIUM', baseScore: 5.0);
      final critical = notification(severity: 'CRITICAL', baseScore: 9.8);

      expect(
        NotificationService.shouldDisplayForPreferences(
          medium,
          allNotificationsEnabled: true,
          criticalAlertsEnabled: false,
          quietHoursEnabled: false,
        ),
        isTrue,
      );
      expect(
        NotificationService.shouldDisplayForPreferences(
          critical,
          allNotificationsEnabled: true,
          criticalAlertsEnabled: false,
          quietHoursEnabled: false,
        ),
        isTrue,
      );
    });

    test('critical alerts on allows only critical or high alerts', () {
      final medium = notification(severity: 'MEDIUM', baseScore: 5.0);
      final high = notification(severity: 'HIGH', baseScore: 7.5);

      expect(
        NotificationService.shouldDisplayForPreferences(
          medium,
          allNotificationsEnabled: true,
          criticalAlertsEnabled: true,
          quietHoursEnabled: false,
        ),
        isFalse,
      );
      expect(
        NotificationService.shouldDisplayForPreferences(
          high,
          allNotificationsEnabled: true,
          criticalAlertsEnabled: true,
          quietHoursEnabled: false,
        ),
        isTrue,
      );
    });

    test('master notification switch still blocks all alerts', () {
      final critical = notification(severity: 'CRITICAL', baseScore: 9.8);

      expect(
        NotificationService.shouldDisplayForPreferences(
          critical,
          allNotificationsEnabled: false,
          criticalAlertsEnabled: false,
          quietHoursEnabled: false,
        ),
        isFalse,
      );
    });
  });
}
