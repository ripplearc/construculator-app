import 'package:construculator/libraries/analytics/domain/entities/analytics_user_properties.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalyticsUserProperties', () {
    group('toMap', () {
      test('omits unset named fields', () {
        const properties = AnalyticsUserProperties(email: 'a@example.com');

        expect(properties.toMap(), {'email': 'a@example.com'});
      });

      test('includes all named fields when set', () {
        const properties = AnalyticsUserProperties(
          email: 'a@example.com',
          name: 'Jane Doe',
          role: 'Project Manager',
        );

        expect(properties.toMap(), {
          'email': 'a@example.com',
          'name': 'Jane Doe',
          'role': 'Project Manager',
        });
      });

      test('merges custom properties alongside named fields', () {
        const properties = AnalyticsUserProperties(
          email: 'a@example.com',
          custom: {'company_id': 'company-1'},
        );

        expect(properties.toMap(), {
          'email': 'a@example.com',
          'company_id': 'company-1',
        });
      });

      test('returns an empty map when nothing is set', () {
        const properties = AnalyticsUserProperties();

        expect(properties.toMap(), isEmpty);
      });
    });

    test('two instances with the same fields are equal', () {
      const first = AnalyticsUserProperties(email: 'a@example.com');
      const second = AnalyticsUserProperties(email: 'a@example.com');

      expect(first, second);
    });
  });
}
