import 'package:cybershield_app/app/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiService CPE ranking', () {
    test('returns matching non-deprecated CPE names in best-match order', () {
      final products = [
        {
          'cpe': {
            'deprecated': false,
            'cpeName': 'cpe:2.3:a:apache:http_server:*:*:*:*:*:*:*:*',
            'titles': [
              {'title': 'Apache HTTP Server'},
            ],
          },
        },
        {
          'cpe': {
            'deprecated': true,
            'cpeName': 'cpe:2.3:a:apache:old_http_server:*:*:*:*:*:*:*:*',
            'titles': [
              {'title': 'Apache HTTP Server'},
            ],
          },
        },
        {
          'cpe': {
            'deprecated': false,
            'cpeName': 'cpe:2.3:a:example:other:*:*:*:*:*:*:*:*',
            'titles': [
              {'title': 'Unrelated Product'},
            ],
          },
        },
      ];

      expect(
        ApiService.rankedCpeNamesForKeyword(products, 'Apache HTTP Server'),
        ['cpe:2.3:a:apache:http_server:*:*:*:*:*:*:*:*'],
      );
    });

    test('returns empty list when no CPE product matches the keyword', () {
      final products = [
        {
          'cpe': {
            'deprecated': false,
            'cpeName': 'cpe:2.3:a:example:other:*:*:*:*:*:*:*:*',
            'titles': [
              {'title': 'Unrelated Product'},
            ],
          },
        },
      ];

      expect(
        ApiService.rankedCpeNamesForKeyword(products, 'OpenSSL'),
        isEmpty,
      );
    });
  });
}
