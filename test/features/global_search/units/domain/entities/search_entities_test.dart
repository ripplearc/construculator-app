import 'package:construculator/features/global_search/domain/entities/pagination_params.dart';
import 'package:construculator/features/global_search/domain/entities/search_params_entity.dart';
import 'package:construculator/features/global_search/domain/entities/search_results.dart';
import 'package:construculator/features/global_search/domain/entities/search_scope_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaginationParams', () {
    test('defaults to offset 0 and limit 20', () {
      const params = PaginationParams();
      expect(params.offset, 0);
      expect(params.limit, 20);
    });

    test('copyWith replaces only the given fields', () {
      const original = PaginationParams(offset: 10, limit: 5);

      expect(original.copyWith(offset: 20), const PaginationParams(offset: 20, limit: 5));
      expect(original.copyWith(limit: 50), const PaginationParams(offset: 10, limit: 50));
      expect(original.copyWith(), original);
    });

    test('props includes offset and limit', () {
      const params = PaginationParams(offset: 3, limit: 7);
      expect(params.props, [3, 7]);
    });

    test('equality via Equatable', () {
      expect(const PaginationParams(offset: 0, limit: 20), const PaginationParams());
      expect(const PaginationParams(offset: 1), isNot(equals(const PaginationParams())));
    });
  });

  group('SearchParams', () {
    const base = SearchParams(query: 'hello');

    test('defaults optional fields to null and default pagination', () {
      expect(base.query, 'hello');
      expect(base.filterByTag, isNull);
      expect(base.filterByDate, isNull);
      expect(base.filterByOwner, isNull);
      expect(base.scope, isNull);
      expect(base.pagination, const PaginationParams());
    });

    test('copyWith with no args returns equivalent object', () {
      expect(base.copyWith(), base);
    });

    test('copyWith replaces query', () {
      expect(base.copyWith(query: 'world').query, 'world');
    });

    test('copyWith sets nullable fields when explicitly provided', () {
      final now = DateTime(2024);
      final updated = base.copyWith(
        filterByTag: 'urgent',
        filterByDate: now,
        filterByOwner: 'user-1',
        scope: SearchScope.estimation,
      );
      expect(updated.filterByTag, 'urgent');
      expect(updated.filterByDate, now);
      expect(updated.filterByOwner, 'user-1');
      expect(updated.scope, SearchScope.estimation);
    });

    test('copyWith clears nullable fields when null is passed explicitly', () {
      final withFields = base.copyWith(
        filterByTag: 'tag',
        filterByOwner: 'owner',
        scope: SearchScope.dashboard,
      );
      final cleared = withFields.copyWith(
        filterByTag: null,
        filterByOwner: null,
        scope: null,
      );
      expect(cleared.filterByTag, isNull);
      expect(cleared.filterByOwner, isNull);
      expect(cleared.scope, isNull);
    });

    test('copyWith replaces pagination', () {
      const newPagination = PaginationParams(offset: 20, limit: 10);
      expect(base.copyWith(pagination: newPagination).pagination, newPagination);
    });

    test('props includes all fields', () {
      expect(base.props, [
        'hello',
        null,
        null,
        null,
        null,
        const PaginationParams(),
      ]);
    });
  });

  group('SearchResults', () {
    test('defaults to all empty lists', () {
      const results = SearchResults();
      expect(results.projects, isEmpty);
      expect(results.estimations, isEmpty);
      expect(results.members, isEmpty);
    });

    test('copyWith replaces only the given fields', () {
      const original = SearchResults();

      final withProjects = original.copyWith(projects: []);
      expect(withProjects.projects, isEmpty);
      expect(withProjects.estimations, isEmpty);

      final withEstimations = original.copyWith(estimations: []);
      expect(withEstimations.estimations, isEmpty);

      final withMembers = original.copyWith(members: []);
      expect(withMembers.members, isEmpty);

      expect(original.copyWith(), original);
    });

    test('props includes all three lists', () {
      const results = SearchResults();
      expect(results.props, [<dynamic>[], <dynamic>[], <dynamic>[]]);
    });

    test('equality via Equatable', () {
      expect(const SearchResults(), const SearchResults());
    });
  });
}
