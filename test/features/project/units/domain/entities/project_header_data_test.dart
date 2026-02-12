import 'package:construculator/features/project/domain/entities/project_header_data.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProjectHeaderData', () {
    final testProject = Project(
      id: 'project-123',
      projectName: 'Test Project',
      description: 'A test project',
      creatorUserId: 'user-123',
      owningCompanyId: 'company-123',
      exportFolderLink: 'https://example.com/export',
      exportStorageProvider: StorageProvider.googleDrive,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      status: ProjectStatus.active,
    );

    final testUser = User(
      id: 'user-123',
      credentialId: 'credential-123',
      email: 'test@example.com',
      phone: null,
      firstName: 'Test',
      lastName: 'User',
      professionalRole: 'Developer',
      profilePhotoUrl: 'https://example.com/avatar.jpg',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      userStatus: UserProfileStatus.active,
      userPreferences: const {},
    );

    group('userAvatarUrl', () {
      test('returns profile photo URL when user profile exists', () {
        final headerData = ProjectHeaderData(
          project: testProject,
          userProfile: testUser,
        );

        expect(headerData.userAvatarUrl, 'https://example.com/avatar.jpg');
      });

      test('returns null when user profile is null', () {
        final headerData = ProjectHeaderData(
          project: testProject,
          userProfile: null,
        );

        expect(headerData.userAvatarUrl, null);
      });

      test('returns null when profile photo URL is null', () {
        final userWithoutPhoto = testUser.copyWith(profilePhotoUrl: null);
        final headerData = ProjectHeaderData(
          project: testProject,
          userProfile: userWithoutPhoto,
        );

        expect(headerData.userAvatarUrl, null);
      });
    });

    group('userAvatarImage', () {
      test('returns NetworkImage when profile photo URL exists', () {
        final headerData = ProjectHeaderData(
          project: testProject,
          userProfile: testUser,
        );

        final avatarImage = headerData.userAvatarImage;
        expect(avatarImage, isNotNull);
        expect(avatarImage, isA<NetworkImage>());
        expect((avatarImage as NetworkImage).url, 'https://example.com/avatar.jpg');
      });

      test('returns null when user profile is null', () {
        final headerData = ProjectHeaderData(
          project: testProject,
          userProfile: null,
        );

        expect(headerData.userAvatarImage, null);
      });

      test('returns null when profile photo URL is null', () {
        final userWithoutPhoto = testUser.copyWith(profilePhotoUrl: null);
        final headerData = ProjectHeaderData(
          project: testProject,
          userProfile: userWithoutPhoto,
        );

        expect(headerData.userAvatarImage, null);
      });

      test('returns null when profile photo URL is empty string', () {
        final userWithEmptyPhoto = testUser.copyWith(profilePhotoUrl: '');
        final headerData = ProjectHeaderData(
          project: testProject,
          userProfile: userWithEmptyPhoto,
        );

        expect(headerData.userAvatarImage, null);
      });
    });

    group('equality', () {
      test('two instances with same data are equal', () {
        final headerData1 = ProjectHeaderData(
          project: testProject,
          userProfile: testUser,
        );
        final headerData2 = ProjectHeaderData(
          project: testProject,
          userProfile: testUser,
        );

        expect(headerData1, equals(headerData2));
      });

      test('two instances with different user profiles are not equal', () {
        final headerData1 = ProjectHeaderData(
          project: testProject,
          userProfile: testUser,
        );
        final headerData2 = ProjectHeaderData(
          project: testProject,
          userProfile: null,
        );

        expect(headerData1, isNot(equals(headerData2)));
      });
    });
  });
}
