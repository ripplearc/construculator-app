import 'package:construculator/features/global_search/data/models/search_results_dto.dart';
import 'package:construculator/libraries/auth/data/models/user_profile_dto.dart';
import 'package:construculator/libraries/project/data/models/project_dto.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:flutter_test/flutter_test.dart';

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
        final projectA = ProjectDto(
          id: 'project-1',
          projectName: 'Bridge Project',
          creatorUserId: 'user-1',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 2),
          status: ProjectStatus.active,
        );

        final projectB = ProjectDto(
          id: 'project-2',
          projectName: 'Road Project',
          creatorUserId: 'user-1',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 2),
          status: ProjectStatus.active,
        );

        final dto1 = SearchResultsDto(projects: [projectA]);
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
  });
}
