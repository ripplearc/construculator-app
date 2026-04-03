import 'package:construculator/features/global_search/data/models/pagination_params_dto.dart';
import 'package:construculator/features/global_search/data/models/search_params_dto.dart';
import 'package:construculator/features/global_search/data/models/search_scope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SearchParamsDto', () {
    group('default constructor', () {
      test('pagination defaults to PaginationParamsDto()', () {
        const params = SearchParamsDto(query: 'bridge');

        expect(params.pagination, const PaginationParamsDto());
      });

      test('all nullable fields default to null', () {
        const params = SearchParamsDto(query: 'bridge');

        expect(params.filterByTag, isNull);
        expect(params.filterByDate, isNull);
        expect(params.filterByOwner, isNull);
        expect(params.scope, isNull);
      });
    });

    group('copyWith', () {
      test('returns equivalent object when no arguments are passed', () {
        final params = SearchParamsDto(
          query: 'bridge',
          filterByTag: 'residential',
          filterByDate: DateTime(2025, 3, 1),
          filterByOwner: 'user-123',
          scope: SearchScopeDto.estimation,
          pagination: const PaginationParamsDto(offset: 20),
        );

        final copy = params.copyWith();

        expect(copy, params);
      });

      test('updates query when provided', () {
        const params = SearchParamsDto(query: 'bridge');

        final copy = params.copyWith(query: 'road');

        expect(copy.query, 'road');
      });

      test('updates all nullable fields when provided', () {
        const params = SearchParamsDto(query: 'bridge');
        final date = DateTime(2025, 3, 1);

        final copy = params.copyWith(
          filterByTag: 'residential',
          filterByDate: date,
          filterByOwner: 'user-123',
          scope: SearchScopeDto.estimation,
        );

        expect(copy.filterByTag, 'residential');
        expect(copy.filterByDate, date);
        expect(copy.filterByOwner, 'user-123');
        expect(copy.scope, SearchScopeDto.estimation);
      });

      test('updates pagination when provided', () {
        const params = SearchParamsDto(query: 'bridge');

        final copy = params.copyWith(
          pagination: const PaginationParamsDto(offset: 20),
        );

        expect(copy.pagination.offset, 20);
      });

      test('clears nullable fields when null is explicitly passed', () {
        final params = SearchParamsDto(
          query: 'bridge',
          filterByTag: 'residential',
          filterByDate: DateTime(2025, 3, 1),
          filterByOwner: 'user-123',
          scope: SearchScopeDto.estimation,
        );

        final copy = params.copyWith(
          filterByTag: null,
          filterByDate: null,
          filterByOwner: null,
          scope: null,
        );

        expect(copy.filterByTag, isNull);
        expect(copy.filterByDate, isNull);
        expect(copy.filterByOwner, isNull);
        expect(copy.scope, isNull);
      });
    });

    group('Equatable', () {
      test('two instances with same values are equal', () {
        final date = DateTime(2025, 3, 1);

        final params1 = SearchParamsDto(
          query: 'bridge',
          filterByTag: 'residential',
          filterByDate: date,
          filterByOwner: 'user-123',
          scope: SearchScopeDto.estimation,
          pagination: const PaginationParamsDto(offset: 20),
        );

        final params2 = SearchParamsDto(
          query: 'bridge',
          filterByTag: 'residential',
          filterByDate: date,
          filterByOwner: 'user-123',
          scope: SearchScopeDto.estimation,
          pagination: const PaginationParamsDto(offset: 20),
        );

        expect(params1, equals(params2));
      });

      test('two instances with different query are not equal', () {
        const params1 = SearchParamsDto(query: 'bridge');
        const params2 = SearchParamsDto(query: 'road');

        expect(params1, isNot(equals(params2)));
      });

      test('two instances with different scope are not equal', () {
        const params1 = SearchParamsDto(query: 'bridge', scope: SearchScopeDto.estimation);
        const params2 = SearchParamsDto(query: 'bridge', scope: SearchScopeDto.member);

        expect(params1, isNot(equals(params2)));
      });

      test('two instances with different pagination are not equal', () {
        const params1 = SearchParamsDto(
          query: 'bridge',
          pagination: PaginationParamsDto(offset: 0),
        );
        const params2 = SearchParamsDto(
          query: 'bridge',
          pagination: PaginationParamsDto(offset: 20),
        );

        expect(params1, isNot(equals(params2)));
      });
    });
  });
}
