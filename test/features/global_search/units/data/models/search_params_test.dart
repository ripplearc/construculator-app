import 'package:construculator/features/global_search/data/models/pagination_params.dart';
import 'package:construculator/features/global_search/data/models/search_params.dart';
import 'package:construculator/features/global_search/data/models/search_scope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SearchParams', () {
    group('default constructor', () {
      test('pagination defaults to PaginationParams()', () {
        const params = SearchParams(query: 'bridge');

        expect(params.pagination, const PaginationParams());
      });

      test('all nullable fields default to null', () {
        const params = SearchParams(query: 'bridge');

        expect(params.filterByTag, isNull);
        expect(params.filterByDate, isNull);
        expect(params.filterByOwner, isNull);
        expect(params.scope, isNull);
      });
    });

    group('copyWith', () {
      test('returns equivalent object when no arguments are passed', () {
        final params = SearchParams(
          query: 'bridge',
          filterByTag: 'residential',
          filterByDate: DateTime(2025, 3, 1),
          filterByOwner: 'user-123',
          scope: SearchScope.estimation,
          pagination: const PaginationParams(offset: 20),
        );

        final copy = params.copyWith();

        expect(copy, params);
      });

      test('updates query when provided', () {
        const params = SearchParams(query: 'bridge');

        final copy = params.copyWith(query: 'road');

        expect(copy.query, 'road');
      });

      test('updates all nullable fields when provided', () {
        const params = SearchParams(query: 'bridge');
        final date = DateTime(2025, 3, 1);

        final copy = params.copyWith(
          filterByTag: 'residential',
          filterByDate: date,
          filterByOwner: 'user-123',
          scope: SearchScope.estimation,
        );

        expect(copy.filterByTag, 'residential');
        expect(copy.filterByDate, date);
        expect(copy.filterByOwner, 'user-123');
        expect(copy.scope, SearchScope.estimation);
      });

      test('updates pagination when provided', () {
        const params = SearchParams(query: 'bridge');

        final copy = params.copyWith(
          pagination: const PaginationParams(offset: 20),
        );

        expect(copy.pagination.offset, 20);
      });

      // Documents the known nullable-field copyWith limitation:
      // passing null for a nullable field does NOT clear it — it silently
      // keeps the existing value. See PR review issue "Nullable Field Clearing".
      test('cannot clear a nullable field by passing null', () {
        final params = SearchParams(
          query: 'bridge',
          filterByTag: 'residential',
          filterByDate: DateTime(2025, 3, 1),
          filterByOwner: 'user-123',
          scope: SearchScope.estimation,
        );

        final copy = params.copyWith(
          filterByTag: null,
          filterByDate: null,
          filterByOwner: null,
          scope: null,
        );

        expect(copy.filterByTag, 'residential');
        expect(copy.filterByDate, DateTime(2025, 3, 1));
        expect(copy.filterByOwner, 'user-123');
        expect(copy.scope, SearchScope.estimation);
      });
    });

    group('Equatable', () {
      test('two instances with same values are equal', () {
        final date = DateTime(2025, 3, 1);

        final params1 = SearchParams(
          query: 'bridge',
          filterByTag: 'residential',
          filterByDate: date,
          filterByOwner: 'user-123',
          scope: SearchScope.estimation,
          pagination: const PaginationParams(offset: 20),
        );

        final params2 = SearchParams(
          query: 'bridge',
          filterByTag: 'residential',
          filterByDate: date,
          filterByOwner: 'user-123',
          scope: SearchScope.estimation,
          pagination: const PaginationParams(offset: 20),
        );

        expect(params1, equals(params2));
      });

      test('two instances with different query are not equal', () {
        const params1 = SearchParams(query: 'bridge');
        const params2 = SearchParams(query: 'road');

        expect(params1, isNot(equals(params2)));
      });

      test('two instances with different scope are not equal', () {
        const params1 = SearchParams(query: 'bridge', scope: SearchScope.estimation);
        const params2 = SearchParams(query: 'bridge', scope: SearchScope.member);

        expect(params1, isNot(equals(params2)));
      });

      test('two instances with different pagination are not equal', () {
        const params1 = SearchParams(
          query: 'bridge',
          pagination: PaginationParams(offset: 0),
        );
        const params2 = SearchParams(
          query: 'bridge',
          pagination: PaginationParams(offset: 20),
        );

        expect(params1, isNot(equals(params2)));
      });
    });
  });
}
