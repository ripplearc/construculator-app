import 'package:construculator/features/estimation/data/models/cost_estimate_dto.dart';
import 'package:construculator/features/global_search/data/models/search_results_dto.dart';
import 'package:construculator/features/global_search/domain/entities/search_results.dart';
import 'package:construculator/libraries/auth/data/models/user_profile_dto.dart';
import 'package:construculator/libraries/project/data/models/project_dto.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../estimations/helpers/estimation_test_data_map_factory.dart'
    as estimation_factory;

void main() {
  group('SearchResultsDto', () {
    final testProject = ProjectDto(
      id: 'project-1',
      projectName: 'Bridge Project',
      creatorUserId: 'user-1',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 2),
      status: ProjectStatus.active,
    );

    const testMember = UserProfileDto(
      id: 'user-1',
      firstName: 'John',
      lastName: 'Doe',
      professionalRole: 'Engineer',
    );

    group('default constructor', () {
      test('projects defaults to empty list', () {
        const dto = SearchResultsDto();

        expect(dto.projects, isEmpty);
      });

      test('estimations defaults to empty list', () {
        const dto = SearchResultsDto();

        expect(dto.estimations, isEmpty);
      });

      test('members defaults to empty list', () {
        const dto = SearchResultsDto();

        expect(dto.members, isEmpty);
      });
    });

    group('copyWith', () {
      test('returns equivalent object when no arguments are passed', () {
        final dto = SearchResultsDto(
          projects: [testProject],
          members: [testMember],
        );

        expect(dto.copyWith(), dto);
      });

      test('replaces projects when provided', () {
        final dto = SearchResultsDto(projects: [testProject]);
        final updated = dto.copyWith(projects: []);

        expect(updated.projects, isEmpty);
      });

      test('appends to existing list when provided', () {
        final dto = SearchResultsDto(projects: [testProject]);
        final extra = ProjectDto(
          id: 'project-2',
          projectName: 'Road Project',
          creatorUserId: 'user-1',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 2),
          status: ProjectStatus.active,
        );

        final updated = dto.copyWith(projects: [...dto.projects, extra]);

        expect(updated.projects, [testProject, extra]);
      });
    });

    group('Equatable', () {
      test('two empty instances are equal', () {
        const dto1 = SearchResultsDto();
        const dto2 = SearchResultsDto();

        expect(dto1, equals(dto2));
      });

      test('two instances with same populated lists are equal', () {
        final dto1 = SearchResultsDto(
          projects: [testProject],
          members: [testMember],
        );

        final dto2 = SearchResultsDto(
          projects: [testProject],
          members: [testMember],
        );

        expect(dto1, equals(dto2));
      });

      test('two instances with different projects are not equal', () {
        final projectB = ProjectDto(
          id: 'project-2',
          projectName: 'Road Project',
          creatorUserId: 'user-1',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 2),
          status: ProjectStatus.active,
        );

        final dto1 = SearchResultsDto(projects: [testProject]);
        final dto2 = SearchResultsDto(projects: [projectB]);

        expect(dto1, isNot(equals(dto2)));
      });

      test('two instances with different members are not equal', () {
        const member1 = UserProfileDto(
          id: 'user-1',
          firstName: 'John',
          lastName: 'Doe',
          professionalRole: 'Engineer',
        );

        const member2 = UserProfileDto(
          id: 'user-2',
          firstName: 'Jane',
          lastName: 'Smith',
          professionalRole: 'Architect',
        );

        const dto1 = SearchResultsDto(members: [member1]);
        const dto2 = SearchResultsDto(members: [member2]);

        expect(dto1, isNot(equals(dto2)));
      });

      test('populated instance is not equal to empty instance', () {
        final populated = SearchResultsDto(projects: [testProject]);
        const empty = SearchResultsDto();

        expect(populated, isNot(equals(empty)));
      });
    });

    group('toDomain', () {
      test('returns empty SearchResults when all lists are empty', () {
        const dto = SearchResultsDto();

        final result = dto.toDomain();

        expect(result, const SearchResults());
        expect(result.projects, isEmpty);
        expect(result.estimations, isEmpty);
        expect(result.members, isEmpty);
      });

      test('maps projects to Project domain entities', () {
        final dto = SearchResultsDto(projects: [testProject]);

        final result = dto.toDomain();

        expect(result.projects, hasLength(1));
        expect(result.projects.first.id, equals(testProject.id));
        expect(
          result.projects.first.projectName,
          equals(testProject.projectName),
        );
        expect(
          result.projects.first.creatorUserId,
          equals(testProject.creatorUserId),
        );
      });

      test('maps members to UserProfile domain entities', () {
        const dto = SearchResultsDto(members: [testMember]);

        final result = dto.toDomain();

        expect(result.members, hasLength(1));
        expect(result.members.first.id, equals(testMember.id));
        expect(result.members.first.firstName, equals(testMember.firstName));
        expect(result.members.first.lastName, equals(testMember.lastName));
        expect(
          result.members.first.professionalRole,
          equals(testMember.professionalRole),
        );
      });

      test('maps estimations to CostEstimate domain entities', () {
        final estimationDto = CostEstimateDto.fromJson(
          estimation_factory.EstimationTestDataMapFactory
              .createFakeEstimationData(),
        );
        final dto = SearchResultsDto(estimations: [estimationDto]);

        final result = dto.toDomain();

        expect(result.estimations, hasLength(1));
        expect(result.estimations.first.id, equals(estimationDto.id));
        expect(
          result.estimations.first.estimateName,
          equals(estimationDto.estimateName),
        );
        expect(
          result.estimations.first.projectId,
          equals(estimationDto.projectId),
        );
      });

      test('maps all three lists simultaneously', () {
        final estimationDto = CostEstimateDto.fromJson(
          estimation_factory.EstimationTestDataMapFactory
              .createFakeEstimationData(),
        );
        final dto = SearchResultsDto(
          projects: [testProject],
          estimations: [estimationDto],
          members: [testMember],
        );

        final result = dto.toDomain();

        expect(result.projects, hasLength(1));
        expect(result.estimations, hasLength(1));
        expect(result.members, hasLength(1));
      });

      test('preserves order of items within each list', () {
        final projectB = ProjectDto(
          id: 'project-2',
          projectName: 'Road Project',
          creatorUserId: 'user-1',
          createdAt: DateTime(2025, 3, 1),
          updatedAt: DateTime(2025, 3, 2),
          status: ProjectStatus.active,
        );
        final dto = SearchResultsDto(projects: [testProject, projectB]);

        final result = dto.toDomain();

        expect(result.projects[0].id, equals(testProject.id));
        expect(result.projects[1].id, equals(projectB.id));
      });

      test('result equals manually constructed SearchResults', () {
        final dto = SearchResultsDto(
          projects: [testProject],
          members: [testMember],
        );

        final result = dto.toDomain();

        expect(
          result,
          SearchResults(
            projects: [testProject.toDomain()],
            members: [testMember.toDomain()],
          ),
        );
      });
    });
  });
}
