import 'package:construculator/features/global_search/domain/entities/search_results.dart';
import 'package:construculator/libraries/auth/domain/entities/user_profile_entity.dart';
import 'package:construculator/libraries/estimation/data/models/cost_estimate_dto.dart';
import 'package:construculator/libraries/project/data/models/project_dto.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../libraries/estimation/helpers/estimation_test_data_map_factory.dart';

void main() {
  final testProject = ProjectDto(
    id: 'project-1',
    projectName: 'Bridge Project',
    creatorUserId: 'user-1',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 2),
    status: ProjectStatus.active,
  ).toDomain();

  final testEstimation = CostEstimateDto.fromJson(
    EstimationTestDataMapFactory.createFakeEstimationData(
      id: 'estimate-1',
      projectId: 'project-1',
    ),
  ).toDomain();

  const testMember = UserProfile(
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
        final results = SearchResults(projects: [testProject]);

        final copy = results.copyWith(projects: []);

        expect(copy.projects, isEmpty);
      });

      test('replaces estimations when provided', () {
        final results = SearchResults(estimations: [testEstimation]);

        final copy = results.copyWith(estimations: []);

        expect(copy.estimations, isEmpty);
      });

      test('replaces members when provided', () {
        const results = SearchResults(members: [testMember]);

        final copy = results.copyWith(members: []);

        expect(copy.members, isEmpty);
      });

      test('preserves unchanged fields when updating one field', () {
        final results = SearchResults(
          projects: [testProject],
          members: [testMember],
        );

        final copy = results.copyWith(estimations: [testEstimation]);

        expect(copy.projects, [testProject]);
        expect(copy.members, [testMember]);
        expect(copy.estimations, [testEstimation]);
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
          projects: [testProject],
          members: [testMember],
        );
        final results2 = SearchResults(
          projects: [testProject],
          members: [testMember],
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

        final results1 = SearchResults(projects: [testProject]);
        final results2 = SearchResults(projects: [projectB]);

        expect(results1, isNot(equals(results2)));
      });

      test('populated instance is not equal to empty instance', () {
        final results = SearchResults(projects: [testProject]);

        expect(results, isNot(equals(const SearchResults())));
      });
    });
  });
}
