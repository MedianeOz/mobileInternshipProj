import 'package:flutter_test/flutter_test.dart';

import 'package:cybershield_app/app/models/threat_advisory.dart';
import 'package:cybershield_app/app/utils/constants.dart';

void main() {
  test('ThreatAdvisory parses the NVD CVE response shape', () {
    final advisory = ThreatAdvisory.fromJson({
      'id': 'CVE-2024-12345',
      'published': '2024-03-15T10:00:00.000',
      'lastModified': '2024-03-16T08:00:00.000',
      'descriptions': [
        {'lang': 'en', 'value': 'A vulnerability in CyberShield dependencies.'},
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
        {'url': 'https://example.com/advisory'},
      ],
    });

    expect(advisory.id, 'CVE-2024-12345');
    expect(advisory.description, contains('CyberShield'));
    expect(advisory.baseScore, 9.8);
    expect(advisory.severity, 'CRITICAL');
    expect(advisory.severityColor, AppColors.danger);
    expect(advisory.referenceUrls, ['https://example.com/advisory']);
  });
}
