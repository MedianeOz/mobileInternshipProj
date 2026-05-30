import 'package:cybershield_app/app/controllers/profile_controller.dart';
import 'package:cybershield_app/app/controllers/threat_feed_controller.dart';
import 'package:cybershield_app/app/models/threat_advisory.dart';
import 'package:cybershield_app/app/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';

import '../helpers/mocks.mocks.dart';
import '../helpers/test_helpers.dart';

void main() {
  setupGetX();

  late MockApiService apiService;
  late List<ThreatAdvisory> fixtureThreats;

  ThreatFeedController buildController({ProfileController? profileController}) {
    Get.put<ApiService>(apiService);
    return Get.put(
      ThreatFeedController(
        autoBootstrap: false,
        profileControllerProvider: () => profileController,
      ),
    );
  }

  setUp(() {
    apiService = MockApiService();
    fixtureThreats = [
      makeThreat(
        id: 'CVE-2024-0001',
        severity: 'CRITICAL',
        baseScore: 9.8,
        description: 'Apache RCE vulnerability',
        publishedDate: DateTime(2024, 3, 15),
      ),
      makeThreat(
        id: 'CVE-2024-0002',
        severity: 'HIGH',
        baseScore: 7.5,
        description: 'Flutter heap overflow',
        publishedDate: DateTime(2024, 3, 16),
      ),
      makeThreat(
        id: 'CVE-2024-0003',
        severity: 'MEDIUM',
        baseScore: 5.0,
        description: 'Android auth bypass',
        publishedDate: DateTime(2024, 3, 17),
      ),
      makeThreat(
        id: 'CVE-2024-0004',
        severity: 'LOW',
        baseScore: 2.0,
        description: 'Firebase info leak',
        publishedDate: DateTime(2024, 3, 18),
      ),
      makeThreat(
        id: 'CVE-2024-0005',
        severity: 'CRITICAL',
        baseScore: 9.1,
        description: 'SSL certificate flaw',
        publishedDate: DateTime(2024, 3, 19),
      ),
    ];
    when(apiService.errorMessage).thenReturn('');
    when(apiService.hasMoreThreatPages).thenReturn(false);
    when(apiService.getCachedThreats(any)).thenReturn([]);
    when(apiService.buildThreatCacheKey(page: anyNamed('page')))
        .thenReturn('cache');
    when(
      apiService.buildThreatCacheKey(
        page: anyNamed('page'),
        severity: anyNamed('severity'),
      ),
    ).thenReturn('cache');
    when(
      apiService.fetchThreats(
        page: anyNamed('page'),
        keyword: anyNamed('keyword'),
        cpeName: anyNamed('cpeName'),
        severity: anyNamed('severity'),
      ),
    ).thenAnswer((_) async => fixtureThreats);
    when(apiService.resolveCpeNames(any)).thenAnswer((_) async => <String>[]);
  });

  group('ThreatFeedController - filtering', () {
    test('fetchThreats populates threats list', () async {
      final controller = buildController();

      await controller.fetchThreats(refresh: true);

      expect(controller.threats.length, 5);
    });

    test('filterBySeverity CRITICAL keeps only CRITICAL advisories', () async {
      final controller = buildController();
      await controller.fetchThreats(refresh: true);

      await controller.filterBySeverity('CRITICAL');

      expect(controller.threats.map((threat) => threat.id), [
        'CVE-2024-0005',
        'CVE-2024-0001',
      ]);
    });

    test('filterBySeverity ALL clears severity filter and shows all', () async {
      final controller = buildController();
      await controller.fetchThreats(refresh: true);

      await controller.filterBySeverity('ALL');

      expect(controller.selectedSeverity.value, '');
      expect(controller.threats.length, 5);
    });

    test('filterBySeverity HIGH keeps only HIGH advisories', () async {
      final controller = buildController();
      await controller.fetchThreats(refresh: true);

      await controller.filterBySeverity('HIGH');

      expect(controller.threats.single.id, 'CVE-2024-0002');
    });

    test('search apache returns only CVE-2024-0001', () async {
      final controller = buildController();
      await controller.fetchThreats(refresh: true);

      await controller.search('apache');

      expect(controller.threats.single.id, 'CVE-2024-0001');
    });

    test('search flutter returns only CVE-2024-0002', () async {
      final controller = buildController();
      await controller.fetchThreats(refresh: true);

      await controller.search('flutter');

      expect(controller.threats.single.id, 'CVE-2024-0002');
    });

    test('search empty clears keyword filter and shows all', () async {
      final controller = buildController();
      await controller.fetchThreats(refresh: true);
      await controller.search('apache');

      await controller.search('');

      expect(controller.searchKeyword.value, '');
      expect(controller.threats.length, 5);
    });

    test('clearFilters resets severity and keyword and shows all threats',
        () async {
      final controller = buildController();
      await controller.fetchThreats(refresh: true);
      await controller.search('apache');
      await controller.filterBySeverity('CRITICAL');

      await controller.clearFilters();

      expect(controller.selectedSeverity.value, '');
      expect(controller.searchKeyword.value, '');
      expect(controller.threats.length, 5);
    });

    test('threats are sorted newest-first', () async {
      final controller = buildController();

      await controller.fetchThreats(refresh: true);

      expect(controller.threats.first.id, 'CVE-2024-0005');
      expect(controller.threats.last.id, 'CVE-2024-0001');
    });

    test('isWatchlistModeActive defaults to true', () {
      final controller = buildController();

      expect(controller.isWatchlistModeActive.value, isTrue);
    });

    test('toggleWatchlistMode flips isWatchlistModeActive', () async {
      final controller = buildController();

      await controller.toggleWatchlistMode();

      expect(controller.isWatchlistModeActive.value, isFalse);
    });

    test('watchlist mode filters by watchlist keywords', () async {
      final profile = MockProfileController();
      when(profile.watchlist).thenReturn(['Apache', 'Flutter'].obs);
      when(profile.criticalAlertsEnabled).thenReturn(true.obs);
      final controller = buildController(profileController: profile);

      await controller.fetchThreats(refresh: true);

      expect(controller.threats.map((threat) => threat.id), [
        'CVE-2024-0002',
        'CVE-2024-0001',
      ]);
    });

    test('watchlist mode uses resolved CPE names before keyword search',
        () async {
      final profile = MockProfileController();
      when(profile.watchlist).thenReturn(['Apache Tomcat'].obs);
      when(profile.criticalAlertsEnabled).thenReturn(true.obs);
      when(apiService.resolveCpeNames('Apache Tomcat')).thenAnswer(
        (_) async => ['cpe:2.3:a:apache:tomcat:*:*:*:*:*:*:*:*'],
      );
      when(
        apiService.fetchThreats(
          page: anyNamed('page'),
          keyword: anyNamed('keyword'),
          cpeName: 'cpe:2.3:a:apache:tomcat:*:*:*:*:*:*:*:*',
          severity: anyNamed('severity'),
        ),
      ).thenAnswer(
        (_) async => [
          makeThreat(
            id: 'CVE-2024-0100',
            severity: 'HIGH',
            baseScore: 8.1,
            description: 'Remote code execution in a servlet container.',
            publishedDate: DateTime(2024, 3, 20),
          ),
        ],
      );
      final controller = buildController(profileController: profile);

      await controller.fetchThreats(refresh: true);

      expect(controller.threats.single.id, 'CVE-2024-0100');
      verify(
        apiService.fetchThreats(
          page: 0,
          cpeName: 'cpe:2.3:a:apache:tomcat:*:*:*:*:*:*:*:*',
          severity: null,
        ),
      ).called(1);
      verifyNever(
        apiService.fetchThreats(
          page: anyNamed('page'),
          keyword: 'Apache Tomcat',
          severity: anyNamed('severity'),
        ),
      );
    });

    test('critical alert preference does not hide critical feed items',
        () async {
      final profile = MockProfileController();
      when(profile.watchlist).thenReturn(['Apache', 'Flutter'].obs);
      when(profile.criticalAlertsEnabled).thenReturn(false.obs);
      final controller = buildController(profileController: profile);

      await controller.fetchThreats(refresh: true);

      expect(controller.threats.map((threat) => threat.id), [
        'CVE-2024-0002',
        'CVE-2024-0001',
      ]);
    });

    test('empty watchlist in watchlist mode shows all threats', () async {
      final profile = MockProfileController();
      when(profile.watchlist).thenReturn(<String>[].obs);
      when(profile.criticalAlertsEnabled).thenReturn(true.obs);
      final controller = buildController(profileController: profile);

      await controller.fetchThreats(refresh: true);

      expect(controller.threats.length, 5);
    });
  });
}
