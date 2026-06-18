import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/project/presentation/project_ui_provider_impl.dart';
import 'package:construculator/features/project/presentation/widgets/project_header_app_bar.dart';
import 'package:construculator/features/project/project_module.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/presentation/project_ui_provider.dart';
import 'package:construculator/libraries/project/testing/fake_current_project_notifier.dart';
import 'package:construculator/libraries/project/testing/fake_project_repository.dart';
import 'package:construculator/libraries/time/testing/clock_test_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';

class _TestModule extends Module {
  final AppBootstrap appBootstrap;
  _TestModule(this.appBootstrap);

  @override
  List<Module> get imports => [ClockTestModule(), ProjectModule(appBootstrap)];
}

void main() {
  group('ProjectUIProviderImpl', () {
    late ProjectUIProviderImpl provider;

    late FakeCurrentProjectNotifier fakeProjectNotifier;

    setUpAll(() {
      final appBootstrap = FakeAppBootstrapFactory.create();
      Modular.init(_TestModule(appBootstrap));
      Modular.replaceInstance<ProjectRepository>(FakeProjectRepository());
      Modular.replaceInstance<CurrentProjectNotifier>(
        FakeCurrentProjectNotifier(),
      );
      fakeProjectNotifier =
          Modular.get<CurrentProjectNotifier>() as FakeCurrentProjectNotifier;
    });

    tearDownAll(() {
      Modular.dispose();
    });

    setUp(() {
      fakeProjectNotifier.reset();
      provider = Modular.get<ProjectUIProvider>() as ProjectUIProviderImpl;
    });

    group('buildProjectHeaderAppbar', () {
      test('should return ProjectHeaderAppBar', () {
        final projectAppbarHeader = provider.buildProjectHeaderAppbar();

        expect(projectAppbarHeader, isA<ProjectHeaderAppBar>());
      });

      test('should pass correct callbacks to ProjectHeaderAppBar', () {
        final projectAppbarHeader =
            provider.buildProjectHeaderAppbar(
                  onProjectTap: () {},
                  onSearchTap: () {},
                  onNotificationTap: () {},
                )
                as ProjectHeaderAppBar;

        expect(projectAppbarHeader.onProjectTap, isNotNull);
        expect(projectAppbarHeader.onSearchTap, isNotNull);
        expect(projectAppbarHeader.onNotificationTap, isNotNull);
      });

      testWidgets('renders inside Scaffold and is discoverable', (
        tester,
      ) async {
        fakeProjectNotifier.setCurrentProjectId('test-project-id');

        await tester.pumpWidget(
          MaterialApp(
            theme: CoreTheme.light(),
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              appBar: provider.buildProjectHeaderAppbar(),
              body: const SizedBox.shrink(),
            ),
          ),
        );
        await tester.pump();

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
