import 'package:construculator/features/dashboard/domain/entities/favorite_estimation_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FavoriteEstimation', () {
    final date = DateTime(2025, 4, 22, 14, 30);

    final estimation = FavoriteEstimation(
      id: 'est-1',
      title: 'Kitchen Renovation',
      date: date,
      totalCost: 12500.0,
    );

    group('constructor', () {
      test('creates instance with all required fields', () {
        expect(estimation.id, 'est-1');
        expect(estimation.title, 'Kitchen Renovation');
        expect(estimation.date, date);
        expect(estimation.totalCost, 12500.0);
      });
    });

    group('Equatable', () {
      test('two instances with same values are equal', () {
        final other = FavoriteEstimation(
          id: 'est-1',
          title: 'Kitchen Renovation',
          date: date,
          totalCost: 12500.0,
        );

        expect(estimation, equals(other));
      });

      test('two instances with different id are not equal', () {
        final other = FavoriteEstimation(
          id: 'est-2',
          title: 'Kitchen Renovation',
          date: date,
          totalCost: 12500.0,
        );

        expect(estimation, isNot(equals(other)));
      });

      test('two instances with different totalCost are not equal', () {
        final other = FavoriteEstimation(
          id: 'est-1',
          title: 'Kitchen Renovation',
          date: date,
          totalCost: 999.0,
        );

        expect(estimation, isNot(equals(other)));
      });
    });
  });
}
