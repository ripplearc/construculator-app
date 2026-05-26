import 'package:construculator/features/global_search/domain/entities/search_results.dart';
import 'package:construculator/libraries/auth/domain/entities/user_profile_entity.dart';
import 'package:construculator/libraries/estimation/data/models/cost_estimate_dto.dart';
import 'package:construculator/libraries/project/data/models/project_dto.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../libraries/estimation/helpers/estimation_test_data_map_factory.dart';

void main() {
  final _testProject = ProjectDto(
    id: 'project-1',
    projectName: 'Bridge Project',
    creatorUserId: 'user-1',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 2),
    status: ProjectStatus.active,
  ).toDomain();

  final _testEstimation = CostEstimateDto.fromJson(
    EstimationTestDataMapFactory.createFakeEstimationData(
      id: 'estimate-1',
      projectId: 'project-1',
    ),
  ).toDomain();

  const _testMember = UserProfile(
    id: 'user-1',
    firstName: 'Jane',
    lastName: 'Doe',
    professionalRole: 'Engineer',
  );

  group('SearchResults', () {
    group('default constructor', () {
      test('projects defaults to empty list', () {
        const results = SearchResults();

        expect(results.projects, isEmpty);
      });

      test('estimations defaults to empty list', () {
        const results = SearchResults();

        expect(results.estimations, isEmpty);
      });

      test('members defaults to empty list', () {
        const results = SearchResults();

        expect(results.members, isEmpty);
      });
    });

    group('copyWith', () {
      test('returns equivalent object when no arguments are passed', () {
        const results = SearchResults();

        expect(results.copyWith(), results);
      });

      test('replaces projects when provided', () {
        final results = SearchResults(projects: [_testProject]);

        final copy = results.copyWith(projects: []);

        expect(copy.projects, isEmpty);
      });

      test('replaces estimations when provided', () {
        final results = SearchResults(estimations: [_testEstimation]);

        final copy = results.copyWith(estimations: []);

        expect(copy.estimations, isEmpty);
      });

      test('replaces members when provided', () {
        const results = SearchResults(members: [_testMember]);

        final copy = results.copyWith(members: []);

        expect(copy.members, isEmpty);
      });

      test('preserves unchanged fields when updating one field', () {
        final results = SearchResults(
          projects: [_testProject],
          members: [_testMember],
        );

        final copy = results.copyWith(estimations: [_testEstimation]);

        expect(copy.projects, [_testProject]);
        expect(copy.members, [_testMember]);
        expect(copy.estimations, [_testEstimation]);
      });
    });

    group('Equatable', () {
      test('two empty instances are equal', () {
        const results1 = SearchResults();
        const results2 = SearchResults();

        expect(results1, equals(results2));
      });

      test('two instances with same content are equal', () {
        final results1 = SearchResults(
          projects: [_testProject],
          members: [_testMember],
        );
        final results2 = SearchResults(
          projects: [_testProject],
          members: [_testMember],
        );

        expect(results1, equals(results2));
      });

      test('two instances with different projects are not equal', () {
        final projectB = ProjectDto(
          id: 'project-2',
          projectName: 'Road Project',
          creatorUserId: 'user-1',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 2),
          status: ProjectStatus.active,
        ).toDomain();

        final results1 = SearchResults(projects: [_testProject]);
        final results2 = SearchResults(projects: [projectB]);

        expect(results1, isNot(equals(results2)));
      });

      test('populated instance is not equal to empty instance', () {
        final results = SearchResults(projects: [_testProject]);

        expect(results, isNot(equals(const SearchResults())));
      });
    });
  });
}
