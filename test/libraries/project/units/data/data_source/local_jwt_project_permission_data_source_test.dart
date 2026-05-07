import 'package:construculator/libraries/project/data/data_source/interfaces/permission_data_source.dart';
import 'package:construculator/libraries/project/data/data_source/local_jwt_project_permission_data_source.dart';
import 'package:construculator/libraries/project/project_library_module.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../utils/fake_app_bootstrap_factory.dart';

class _TestModule extends Module {
  final FakeSupabaseWrapper supabaseWrapper;

  _TestModule({required this.supabaseWrapper});

  @override
  List<Module> get imports => [
    ProjectLibraryModule(
      FakeAppBootstrapFactory.create(supabaseWrapper: supabaseWrapper),
    ),
  ];
}

void main() {
  group('LocalJwtProjectPermissionDataSource', () {
    late FakeClockImpl clock;
    late FakeSupabaseWrapper supabaseWrapper;
    late LocalJwtProjectPermissionDataSource dataSource;

    setUpAll(() {
      clock = FakeClockImpl(DateTime(2025, 1, 1, 8, 0));
      supabaseWrapper = FakeSupabaseWrapper(clock: clock);
      Modular.init(_TestModule(supabaseWrapper: supabaseWrapper));
      dataSource =
          Modular.get<ProjectPermissionDataSource>()
              as LocalJwtProjectPermissionDataSource;
    });

    setUp(() {
      supabaseWrapper.reset();
    });

    tearDownAll(() {
      Modular.dispose();
    });

    group('getProjectPermissions', () {
      test('returns permissions from supabase wrapper', () {
        supabaseWrapper.setProjectPermissions('project-1', [
          'read',
          'write',
          'delete',
        ]);

        final result = dataSource.getProjectPermissions('project-1');

        expect(result, ['read', 'write', 'delete']);
      });

      test('returns empty list when no permissions set', () {
        final result = dataSource.getProjectPermissions('project-1');

        expect(result, isEmpty);
      });

      test('returns permissions for specific project only', () {
        supabaseWrapper.setProjectPermissions('project-1', ['read', 'write']);
        supabaseWrapper.setProjectPermissions('project-2', ['admin']);

        final result = dataSource.getProjectPermissions('project-1');

        expect(result, ['read', 'write']);
        expect(result, isNot(contains('admin')));
      });
    });

    group('hasProjectPermission', () {
      test('returns true when permission exists', () {
        supabaseWrapper.setProjectPermissions('project-1', ['read', 'write']);

        final result = dataSource.hasProjectPermission('project-1', 'read');

        expect(result, isTrue);
      });

      test('returns false when permission does not exist', () {
        supabaseWrapper.setProjectPermissions('project-1', ['read']);

        final result = dataSource.hasProjectPermission('project-1', 'write');

        expect(result, isFalse);
      });

      test('returns false when no permissions set for project', () {
        final result = dataSource.hasProjectPermission('project-1', 'read');

        expect(result, isFalse);
      });

      test('returns false for permission in different project', () {
        supabaseWrapper.setProjectPermissions('project-1', ['read']);
        supabaseWrapper.setProjectPermissions('project-2', ['write']);

        final result = dataSource.hasProjectPermission('project-1', 'write');

        expect(result, isFalse);
      });
    });
  });
}
