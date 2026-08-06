import 'package:construculator/libraries/analytics/domain/entities/analytics_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalyticsEvent', () {
    test('defaults properties to an empty map', () {
      const event = AnalyticsEvent(name: 'user_logged_in');

      expect(event.properties, isEmpty);
    });

    test('two events with the same name and properties are equal', () {
      const first = AnalyticsEvent(
        name: 'estimation_created',
        properties: {'estimation_id': 'est-1'},
      );
      const second = AnalyticsEvent(
        name: 'estimation_created',
        properties: {'estimation_id': 'est-1'},
      );

      expect(first, second);
    });

    test('events with different properties are not equal', () {
      const first = AnalyticsEvent(
        name: 'estimation_created',
        properties: {'estimation_id': 'est-1'},
      );
      const second = AnalyticsEvent(
        name: 'estimation_created',
        properties: {'estimation_id': 'est-2'},
      );

      expect(first, isNot(second));
    });
  });
}
