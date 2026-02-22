import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/project/presentation/project_ui_provider_impl.dart';
import 'package:construculator/features/project/presentation/widgets/project_header_app_bar.dart';
import 'package:construculator/features/project/project_module.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/project/presentation/project_ui_provider.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/clock_test_module.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class _TestModule extends Module {
  final AppBootstrap appBootstrap;
  _TestModule(this.appBootstrap);

  @override
  List<Module> get imports => [ClockTestModule(), ProjectModule(appBootstrap)];
}

void main() {
  group('ProjectUIProviderImpl', () {
    late ProjectUIProviderImpl provider;

    setUpAll(() {
      final appBootstrap = AppBootstrap(
        envLoader: FakeEnvLoader(),
        config: FakeAppConfig(),
        supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
      );
      Modular.init(_TestModule(appBootstrap));
    });

    tearDownAll(() {
      Modular.dispose();
    });

    setUp(() {
      provider = Modular.get<ProjectUIProvider>() as ProjectUIProviderImpl;
    });

    group('buildProjectHeaderAppbar', () {
      test('should return ProjectHeaderAppBar', () {
        final projectAppbarHeader = provider.buildProjectHeaderAppbar(
          projectId: '',
        );

        expect(projectAppbarHeader, isA<ProjectHeaderAppBar>());
      });

      test('should pass correct arguments to ProjectHeaderAppBar', () {
        final projectAppbarHeader =
            provider.buildProjectHeaderAppbar(
                  projectId: 'my-project-123',
                  onProjectTap: () {},
                  onSearchTap: () {},
                  onNotificationTap: () {},
                )
                as ProjectHeaderAppBar;

        expect(projectAppbarHeader.projectId, equals('my-project-123'));
        expect(projectAppbarHeader.onProjectTap, isNotNull);
        expect(projectAppbarHeader.onSearchTap, isNotNull);
        expect(projectAppbarHeader.onNotificationTap, isNotNull);
      });

      testWidgets('renders inside Scaffold and is discoverable', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: CoreTheme.light(),
            home: Scaffold(
              appBar: provider.buildProjectHeaderAppbar(
                projectId: 'my-project-123',
              ),
              body: const SizedBox.shrink(),
            ),
          ),
        );

        expect(find.byType(ProjectHeaderAppBar), findsOneWidget);
        expect(
          find.byKey(const Key('project_header_search_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('project_header_notification_button')),
          findsOneWidget,
        );
      });
    });
  });
}
