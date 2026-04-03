import 'package:construculator/features/global_search/data/models/pagination_params_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaginationParamsDto', () {
    group('default constructor', () {
      test('offset defaults to 0', () {
        const params = PaginationParamsDto();

        expect(params.offset, 0);
      });

      test('limit defaults to 20', () {
        const params = PaginationParamsDto();

        expect(params.limit, 20);
      });
    });

    group('copyWith', () {
      test('returns equivalent object when no arguments are passed', () {
        const params = PaginationParamsDto(offset: 40, limit: 20);

        final copy = params.copyWith();

        expect(copy, params);
      });

      test('updates offset when provided', () {
        const params = PaginationParamsDto(offset: 0, limit: 20);

        final copy = params.copyWith(offset: 20);

        expect(copy.offset, 20);
        expect(copy.limit, 20);
      });

      test('updates limit when provided', () {
        const params = PaginationParamsDto(offset: 0, limit: 20);

        final copy = params.copyWith(limit: 50);

        expect(copy.offset, 0);
        expect(copy.limit, 50);
      });

      test('updates both fields when provided', () {
        const params = PaginationParamsDto(offset: 0, limit: 20);

        final copy = params.copyWith(offset: 40, limit: 10);

        expect(copy.offset, 40);
        expect(copy.limit, 10);
      });
    });

    group('Equatable', () {
      test('two instances with same values are equal', () {
        const params1 = PaginationParamsDto(offset: 0, limit: 20);
        const params2 = PaginationParamsDto(offset: 0, limit: 20);

        expect(params1, equals(params2));
      });

      test('two instances with different offset are not equal', () {
        const params1 = PaginationParamsDto(offset: 0, limit: 20);
        const params2 = PaginationParamsDto(offset: 20, limit: 20);

        expect(params1, isNot(equals(params2)));
      });

      test('two instances with different limit are not equal', () {
        const params1 = PaginationParamsDto(offset: 0, limit: 20);
        const params2 = PaginationParamsDto(offset: 0, limit: 50);

        expect(params1, isNot(equals(params2)));
      });
    });
  });
}
