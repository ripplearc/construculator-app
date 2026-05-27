import 'dart:async';

import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/permission_data_source.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/project_setting_data_source.dart';
import 'package:construculator/libraries/project/data/models/project_dto.dart';
import 'package:construculator/libraries/project/data/repositories/project_setting_repository_impl.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/project_error_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stack_trace/stack_trace.dart';

void main() {
  group('ProjectSettingRepositoryImpl', () {
    late _FakeProjectSettingDataSource dataSource;
    late _FakeProjectPermissionDataSource permissionDataSource;
    late ProjectSettingRepositoryImpl repository;

    setUp(() {
      dataSource = _FakeProjectSettingDataSource();
      permissionDataSource = _FakeProjectPermissionDataSource();
      repository = ProjectSettingRepositoryImpl(
        dataSource: dataSource,
        permissionDataSource: permissionDataSource,
      );
    });

    tearDown(() {
      repository.dispose();
      dataSource.dispose();
    });

    group('getProjectSetting', () {
      test('returns Right(project) when data source succeeds', () async {
        dataSource.projectToReturn = _fakeDto(
          id: 'p-1',
          projectName: 'Test Project',
        );

        final result = await repository.getProjectSetting('p-1');

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (project) {
            expect(project.id, equals('p-1'));
            expect(project.projectName, equals('Test Project'));
          },
        );
      });

      test('returns Left(notFoundError) on ServerException', () async {
        dataSource.shouldThrowOnGet = true;

        final result = await repository.getProjectSetting('p-1');

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<ProjectFailure>());
            expect(
              (failure as ProjectFailure).errorType,
              equals(ProjectErrorType.notFoundError),
            );
          },
          (_) => fail('Expected Left'),
        );
      });

      test('returns Left(timeoutError) on TimeoutException', () async {
        dataSource.exceptionToThrow = TimeoutException('timeout');

        final result = await repository.getProjectSetting('p-1');

        expect(result.isLeft(), isTrue);
        expect(
          (result as Left).value,
          equals(
            const ProjectFailure(errorType: ProjectErrorType.timeoutError),
          ),
        );
      });

      test('returns Left(UnexpectedFailure) on unknown error', () async {
        dataSource.exceptionToThrow = Exception('unknown');

        final result = await repository.getProjectSetting('p-1');

        expect(result.isLeft(), isTrue);
        expect((result as Left).value, isA<UnexpectedFailure>());
      });
    });
  });
}

ProjectDto _fakeDto({required String id, String? projectName}) {
  return ProjectDto(
    id: id,
    projectName: projectName ?? 'Test Project',
    creatorUserId: 'user-1',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 2),
    status: ProjectStatus.active,
  );
}

class _FakeProjectSettingDataSource implements ProjectSettingDataSource {
  ProjectDto? projectToReturn;
  bool shouldThrowOnGet = false;
  Object? exceptionToThrow;

  final StreamController<void> _changesController =
      StreamController<void>.broadcast();

  @override
  Future<ProjectDto> getProjectSetting(String projectId) async {
    final ex = exceptionToThrow;
    if (ex != null) {
      exceptionToThrow = null;
      throw ex;
    }

    if (shouldThrowOnGet) {
      throw ServerException(
        Trace.current(),
        Exception('Data source get failed'),
      );
    }

    final dto = projectToReturn;
    if (dto == null) {
      throw ServerException(Trace.current(), Exception('Not found'));
    }
    return dto;
  }

  @override
  Future<ProjectDto> updateProject(ProjectDto projectDto) async => projectDto;

  @override
  Future<void> deleteProject(String projectId) async {}

  @override
  Stream<void> watchProjectChanges(String projectId) =>
      _changesController.stream;

  void dispose() => _changesController.close();
}

class _FakeProjectPermissionDataSource implements ProjectPermissionDataSource {
  final Map<String, List<String>> _permissions = {};

  @override
  List<String> getProjectPermissions(String projectId) {
    return List.from(_permissions[projectId] ?? []);
  }

  @override
  bool hasProjectPermission(String projectId, String permissionKey) {
    return _permissions[projectId]?.contains(permissionKey) ?? false;
  }
}
