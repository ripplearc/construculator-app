// ignore_for_file: no_direct_instantiation

import 'package:construculator/libraries/analytics/data/repositories/no_op_analytics_repository.dart';
import 'package:construculator/libraries/analytics/domain/entities/analytics_event.dart';
import 'package:construculator/libraries/analytics/domain/entities/analytics_user_properties.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

void _expectRight<L, R>(Either<L, R> result, void Function(R value) assertions) {
  result.fold((_) => fail('Expected Right but got Left'), assertions);
}

void main() {
  group('NoOpAnalyticsRepository', () {
    const repository = NoOpAnalyticsRepository();

    test('track returns Right(null)', () async {
      final result = await repository.track(const AnalyticsEvent(name: 'event'));

      _expectRight(result, (_) {});
    });

    test('identify returns Right(null)', () async {
      final result = await repository.identify(
        userId: 'user-1',
        properties: const AnalyticsUserProperties(),
      );

      _expectRight(result, (_) {});
    });

    test('reset returns Right(null)', () async {
      final result = await repository.reset();

      _expectRight(result, (_) {});
    });

    test('setUserProperties returns Right(null)', () async {
      final result = await repository.setUserProperties(
        const AnalyticsUserProperties(),
      );

      _expectRight(result, (_) {});
    });

    test('group returns Right(null)', () async {
      final result = await repository.group(
        groupType: 'project',
        groupKey: 'project-1',
      );

      _expectRight(result, (_) {});
    });
  });
}
