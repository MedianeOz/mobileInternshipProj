import 'package:cybershield_app/app/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfile serialization', () {
    test('toJson and fromJson round-trip preserves all fields', () {
      const profile = UserProfile(
        uid: 'u1',
        email: 'user@example.com',
        displayName: 'Cyber User',
        watchlist: ['Flutter', 'Firebase'],
        criticalAlertsEnabled: false,
        quietHoursEnabled: false,
        allNotificationsEnabled: false,
      );

      final roundTrip = UserProfile.fromJson(profile.toJson());

      expect(roundTrip.uid, profile.uid);
      expect(roundTrip.email, profile.email);
      expect(roundTrip.displayName, profile.displayName);
      expect(roundTrip.watchlist, profile.watchlist);
      expect(roundTrip.criticalAlertsEnabled, isFalse);
      expect(roundTrip.quietHoursEnabled, isFalse);
      expect(roundTrip.allNotificationsEnabled, isFalse);
    });

    test('fromJson defaults criticalAlertsEnabled to true when missing', () {
      expect(UserProfile.fromJson(const {}).criticalAlertsEnabled, isTrue);
    });

    test('fromJson defaults quietHoursEnabled to true when missing', () {
      expect(UserProfile.fromJson(const {}).quietHoursEnabled, isTrue);
    });

    test('fromJson defaults allNotificationsEnabled to true when missing', () {
      expect(UserProfile.fromJson(const {}).allNotificationsEnabled, isTrue);
    });

    test('fromJson filters empty strings from watchlist', () {
      final profile = UserProfile.fromJson({
        'watchlist': ['Flutter', '', 'Firebase'],
      });

      expect(profile.watchlist, ['Flutter', 'Firebase']);
    });

    test('fromJson handles null watchlist field as empty list', () {
      expect(
          UserProfile.fromJson(const {'watchlist': null}).watchlist, isEmpty);
    });

    test('fromJson handles entirely empty JSON map without crashing', () {
      final profile = UserProfile.fromJson(const {});

      expect(profile.uid, '');
      expect(profile.email, '');
      expect(profile.displayName, '');
      expect(profile.watchlist, isEmpty);
    });
  });
}
