import 'package:construculator/features/global_search/domain/entities/pagination_params.dart';
import 'package:construculator/features/global_search/domain/entities/search_params_entity.dart';
import 'package:construculator/features/global_search/domain/entities/search_scope_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SearchParams', () {
    group('default constructor', () {
      test('creates instance with required query', () {
        const params = SearchParams(query: 'bridge');

        expect(params.query, 'bridge');
      });

      test('optional fields default to null', () {
        const params = SearchParams(query: 'bridge');

        expect(params.filterByTag, isNull);
        expect(params.filterByDate, isNull);
        expect(params.filterByOwner, isNull);
        expect(params.scope, isNull);
      });

      test('pagination defaults to PaginationParams()', () {
        const params = SearchParams(query: 'bridge');

        expect(params.pagination, const PaginationParams());
      });

      test('creates instance with all fields set', () {
        final date = DateTime(2025, 1, 1);
        final params = SearchParams(
          query: 'bridge',
          filterByTag: 'urgent',
          filterByDate: date,
          filterByOwner: 'user-1',
          scope: SearchScope.estimation,
          pagination: const PaginationParams(offset: 20, limit: 10),
        );

        expect(params.query, 'bridge');
        expect(params.filterByTag, 'urgent');
        expect(params.filterByDate, date);
        expect(params.filterByOwner, 'user-1');
        expect(params.scope, SearchScope.estimation);
        expect(params.pagination, const PaginationParams(offset: 20, limit: 10));
      });
    });

    group('copyWith', () {
      const _base = SearchParams(query: 'bridge');

      test('returns equivalent object when no arguments are passed', () {
        expect(_base.copyWith(), _base);
      });

      test('updates query when provided', () {
        final copy = _base.copyWith(query: 'road');

        expect(copy.query, 'road');
      });

      test('sets filterByTag when provided', () {
        final copy = _base.copyWith(filterByTag: 'urgent');

        expect(copy.filterByTag, 'urgent');
      });

      test('clears filterByTag when explicitly passed null', () {
        final withTag = SearchParams(
          query: 'bridge',
          filterByTag: 'urgent',
        );

        final copy = withTag.copyWith(filterByTag: null);

        expect(copy.filterByTag, isNull);
      });

      test('sets filterByDate when provided', () {
        final date = DateTime(2025, 6, 1);
        final copy = _base.copyWith(filterByDate: date);

        expect(copy.filterByDate, date);
      });

      test('clears filterByDate when explicitly passed null', () {
        final withDate = SearchParams(
          query: 'bridge',
          filterByDate: DateTime(2025, 1, 1),
        );

        final copy = withDate.copyWith(filterByDate: null);

        expect(copy.filterByDate, isNull);
      });

      test('sets filterByOwner when provided', () {
        final copy = _base.copyWith(filterByOwner: 'user-1');

        expect(copy.filterByOwner, 'user-1');
      });

      test('clears filterByOwner when explicitly passed null', () {
        final withOwner = SearchParams(query: 'bridge', filterByOwner: 'user-1');

        final copy = withOwner.copyWith(filterByOwner: null);

        expect(copy.filterByOwner, isNull);
      });

      test('sets scope when provided', () {
        final copy = _base.copyWith(scope: SearchScope.member);

        expect(copy.scope, SearchScope.member);
      });

      test('clears scope when explicitly passed null', () {
        final withScope = SearchParams(query: 'bridge', scope: SearchScope.dashboard);

        final copy = withScope.copyWith(scope: null);

        expect(copy.scope, isNull);
      });

      test('updates pagination when provided', () {
        final copy = _base.copyWith(
          pagination: const PaginationParams(offset: 20, limit: 10),
        );

        expect(copy.pagination, const PaginationParams(offset: 20, limit: 10));
      });
    });

    group('Equatable', () {
      test('two instances with same values are equal', () {
        const params1 = SearchParams(query: 'bridge');
        const params2 = SearchParams(query: 'bridge');

        expect(params1, equals(params2));
      });

      test('two instances with different queries are not equal', () {
        const params1 = SearchParams(query: 'bridge');
        const params2 = SearchParams(query: 'road');

        expect(params1, isNot(equals(params2)));
      });

      test('two instances with different scopes are not equal', () {
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
