import 'package:cybershield_app/app/models/threat_advisory.dart';
import 'package:cybershield_app/app/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sampleNvdJson = {
    'id': 'CVE-2024-12345',
    'published': '2024-03-15T10:00:00.000',
    'lastModified': '2024-03-16T08:00:00.000',
    'descriptions': [
      {'lang': 'en', 'value': 'A critical buffer overflow in ExampleLib 1.2.'},
    ],
    'metrics': {
      'cvssMetricV31': [
        {
          'cvssData': {
            'baseScore': 9.8,
            'baseSeverity': 'CRITICAL',
          },
        },
      ],
    },
    'references': [
      {'url': 'https://nvd.nist.gov/vuln/detail/CVE-2024-12345'},
    ],
  };

  group('ThreatAdvisory.fromJson', () {
    test('parses a well-formed NVD CVE JSON blob', () {
      final advisory = ThreatAdvisory.fromJson(sampleNvdJson);

      expect(advisory.id, 'CVE-2024-12345');
      expect(advisory.description, contains('ExampleLib'));
      expect(advisory.baseScore, 9.8);
      expect(advisory.severity, 'CRITICAL');
    });

    test('falls back when descriptions list is empty', () {
      final advisory = ThreatAdvisory.fromJson({
        ...sampleNvdJson,
        'descriptions': <Map<String, dynamic>>[],
      });

      expect(advisory.description, contains('No description'));
    });

    test('extracts severity from cvssMetricV31 first', () {
      expect(ThreatAdvisory.fromJson(sampleNvdJson).severity, 'CRITICAL');
    });

    test('extracts severity from cvssMetricV30 when V31 is absent', () {
      final advisory = ThreatAdvisory.fromJson({
        ...sampleNvdJson,
        'metrics': {
          'cvssMetricV30': [
            {
              'cvssData': {
                'baseScore': 7.5,
                'baseSeverity': 'HIGH',
              },
            },
          ],
        },
      });

      expect(advisory.severity, 'HIGH');
      expect(advisory.baseScore, 7.5);
    });

    test('extracts severity from cvssMetricV2 when V3 is absent', () {
      final advisory = ThreatAdvisory.fromJson({
        ...sampleNvdJson,
        'metrics': {
          'cvssMetricV2': [
            {
              'cvssData': {'baseScore': 5.0},
              'baseSeverity': 'MEDIUM',
            },
          ],
        },
      });

      expect(advisory.severity, 'MEDIUM');
      expect(advisory.baseScore, 5.0);
    });

    test('normalizes unknown severity string to UNKNOWN', () {
      final advisory = ThreatAdvisory.fromJson({
        ...sampleNvdJson,
        'metrics': {
          'cvssMetricV31': [
            {
              'cvssData': {
                'baseScore': 1.0,
                'baseSeverity': 'ODD',
              },
            },
          ],
        },
      });

      expect(advisory.severity, 'UNKNOWN');
    });

    test('parses dates and references, with epoch fallback for invalid dates',
        () {
      final valid = ThreatAdvisory.fromJson(sampleNvdJson);
      final invalid = ThreatAdvisory.fromJson({
        ...sampleNvdJson,
        'published': 'not-a-date',
        'lastModified': null,
      });

      expect(valid.publishedDate, DateTime.parse('2024-03-15T10:00:00.000'));
      expect(invalid.publishedDate, DateTime.fromMillisecondsSinceEpoch(0));
      expect(invalid.lastModifiedDate, DateTime.fromMillisecondsSinceEpoch(0));
      expect(valid.referenceUrls, [
        'https://nvd.nist.gov/vuln/detail/CVE-2024-12345',
      ]);
    });

    test('fromCache round-trips toCacheJson output', () {
      final original = ThreatAdvisory.fromJson(sampleNvdJson);
      final cached = ThreatAdvisory.fromCache(original.toCacheJson());

      expect(cached.id, original.id);
      expect(cached.description, original.description);
      expect(cached.baseScore, original.baseScore);
      expect(cached.severity, original.severity);
      expect(cached.publishedDate, original.publishedDate);
      expect(cached.referenceUrls, original.referenceUrls);
    });
  });

  group('ThreatAdvisory.severityColor', () {
    test('CRITICAL maps to danger', () {
      expect(_threat('CRITICAL').severityColor, AppColors.danger);
    });

    test('HIGH maps to warning', () {
      expect(_threat('HIGH').severityColor, AppColors.warning);
    });

    test('MEDIUM maps to primary', () {
      expect(_threat('MEDIUM').severityColor, AppColors.primary);
    });

    test('LOW maps to textMuted', () {
      expect(_threat('LOW').severityColor, AppColors.textMuted);
    });

    test('UNKNOWN maps to textHint', () {
      expect(_threat('UNKNOWN').severityColor, AppColors.textHint);
    });
  });
}

ThreatAdvisory _threat(String severity) {
  return ThreatAdvisory(
    id: 'CVE-2024-0001',
    description: 'Test',
    baseScore: 0,
    severity: severity,
    publishedDate: DateTime(2024),
    lastModifiedDate: DateTime(2024),
    referenceUrls: const [],
  );
}
