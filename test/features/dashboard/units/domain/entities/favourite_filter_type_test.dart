import 'package:construculator/features/dashboard/domain/entities/favourite_filter_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FavouriteFilterType', () {
    test('contains exactly three values', () {
      expect(FavouriteFilterType.values, hasLength(3));
    });

    test('all, costEstimations, and calculations are distinct', () {
      expect(FavouriteFilterType.all, isNot(FavouriteFilterType.costEstimations));
      expect(FavouriteFilterType.all, isNot(FavouriteFilterType.calculations));
      expect(
        FavouriteFilterType.costEstimations,
        isNot(FavouriteFilterType.calculations),
      );
    });
  });
}
