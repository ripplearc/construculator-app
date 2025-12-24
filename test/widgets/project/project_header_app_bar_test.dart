import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/project/presentation/widgets/project_header_app_bar.dart';
import 'package:construculator/features/project/project_module.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/testing/fake_project_repository.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  late FakeProjectRepository fakeProjectRepository;
  late Clock clock;
  BuildContext? buildContext;

  setUpAll(() async {
    final appBootstrap = AppBootstrap(
      config: FakeAppConfig(),
      envLoader: FakeEnvLoader(),
      supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
    );
    Modular.init(ProjectModule(appBootstrap));
    Modular.replaceInstance<ProjectRepository>(FakeProjectRepository());
    fakeProjectRepository =
        Modular.get<ProjectRepository>() as FakeProjectRepository;
    clock = Modular.get<Clock>();
  });

  tearDownAll(() {
    Modular.destroy();
  });

  group('ProjectHeaderAppBar', () {
    Future<void> pumpProjectHeaderAppBar(
      WidgetTester tester, {
      required String projectId,
      required String projectName,
      ImageProvider? avatarImage,
      VoidCallback? onProjectTap,
      VoidCallback? onSearchTap,
      VoidCallback? onNotificationTap,
      bool shouldThrowOnGetProject = false,
    }) async {
      final project = Project(
        id: projectId,
        projectName: projectName,
        creatorUserId: 'user-id',
        createdAt: clock.now(),
        updatedAt: clock.now(),
        status: ProjectStatus.active,
      );

      fakeProjectRepository.addProject(projectId, project);
      fakeProjectRepository.shouldThrowOnGetProject = shouldThrowOnGetProject;

      await tester.pumpWidget(
        MaterialApp(
          theme: CoreTheme.light(),
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Builder(
            builder: (context) {
              buildContext = context;
              return Scaffold(
                appBar: ProjectHeaderAppBar(
                  projectId: projectId,
                  avatarImage: avatarImage,
                  onProjectTap: onProjectTap,
                  onSearchTap: onSearchTap,
                  onNotificationTap: onNotificationTap,
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();
    }

    AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

    testWidgets('renders with required project name', (
      WidgetTester tester,
    ) async {
      const projectId = 'test-project-id';
      const projectName = 'Test Project';

      await pumpProjectHeaderAppBar(
        tester,
        projectId: projectId,
        projectName: projectName,
      );

      await tester.pumpAndSettle();
      expect(find.byType(ProjectHeaderAppBar), findsOneWidget);
      expect(find.text(projectName), findsOneWidget);
    });

    testWidgets('calls onProjectTap when project name is tapped', (
      WidgetTester tester,
    ) async {
      const projectId = 'test-project-id';
      const projectName = 'Test Project';
      bool onProjectTapCalled = false;

      await pumpProjectHeaderAppBar(
        tester,
        projectId: projectId,
        projectName: projectName,
        onProjectTap: () => onProjectTapCalled = true,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(projectName));
      await tester.pumpAndSettle();

      expect(onProjectTapCalled, isTrue);
    });

    testWidgets('calls onSearchTap when search icon is tapped', (
      WidgetTester tester,
    ) async {
      const projectId = 'test-project-id';
      const projectName = 'Test Project';
      bool onSearchTapCalled = false;

      await pumpProjectHeaderAppBar(
        tester,
        projectId: projectId,
        projectName: projectName,
        onSearchTap: () => onSearchTapCalled = true,
      );
      await tester.pumpAndSettle();

      final searchIcon = find.byKey(const Key('project_header_search_button'));
      await tester.tap(searchIcon);
      await tester.pumpAndSettle();

      expect(onSearchTapCalled, isTrue);
    });

    testWidgets('calls onNotificationTap when notification icon is tapped', (
      WidgetTester tester,
    ) async {
      const projectId = 'test-project-id';
      const projectName = 'Test Project';
      bool onNotificationTapCalled = false;

      await pumpProjectHeaderAppBar(
        tester,
        projectId: projectId,
        projectName: projectName,
        onNotificationTap: () => onNotificationTapCalled = true,
      );
      await tester.pumpAndSettle();

      final notificationIcon = find.byKey(
        const Key('project_header_notification_button'),
      );
      await tester.tap(notificationIcon);
      await tester.pumpAndSettle();

      expect(onNotificationTapCalled, isTrue);
    });

    testWidgets('renders search and notification icons', (
      WidgetTester tester,
    ) async {
      const projectId = 'test-project-id';
      const projectName = 'Test Project';

      await pumpProjectHeaderAppBar(
        tester,
        projectId: projectId,
        projectName: projectName,
      );

      expect(
        find.byKey(const Key('project_header_search_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('project_header_notification_button')),
        findsOneWidget,
      );
    });

    testWidgets('search button has correct icon and attributes', (
      WidgetTester tester,
    ) async {
      const projectId = 'test-project-id';
      const projectName = 'Test Project';
      bool onSearchTapCalled = false;

      await pumpProjectHeaderAppBar(
        tester,
        projectId: projectId,
        projectName: projectName,
        onSearchTap: () => onSearchTapCalled = true,
      );
      await tester.pumpAndSettle();

      final searchFinder = find.byKey(
        const Key('project_header_search_button'),
      );
      expect(searchFinder, findsOneWidget);

      final searchIconWidget = tester.widget<CoreIconWidget>(searchFinder);
      expect(searchIconWidget.icon, CoreIcons.search);
      expect(searchIconWidget.onTap, isNotNull);

      await tester.tap(searchFinder);
      await tester.pumpAndSettle();
      expect(onSearchTapCalled, isTrue);
    });

    testWidgets('notification button has correct icon and attributes', (
      WidgetTester tester,
    ) async {
      const projectId = 'test-project-id';
      const projectName = 'Test Project';
      bool onNotificationTapCalled = false;

      await pumpProjectHeaderAppBar(
        tester,
        projectId: projectId,
        projectName: projectName,
        onNotificationTap: () => onNotificationTapCalled = true,
      );
      await tester.pumpAndSettle();

      final notificationFinder = find.byKey(
        const Key('project_header_notification_button'),
      );
      expect(notificationFinder, findsOneWidget);

      final notificationIconWidget = tester.widget<CoreIconWidget>(
        notificationFinder,
      );
      expect(notificationIconWidget.icon, CoreIcons.notification);
      expect(notificationIconWidget.onTap, isNotNull);

      await tester.tap(notificationFinder);
      await tester.pumpAndSettle();
      expect(onNotificationTapCalled, isTrue);
    });

    testWidgets('handles null callbacks gracefully', (
      WidgetTester tester,
    ) async {
      const projectId = 'test-project-id';
      const projectName = 'Test Project';

      await pumpProjectHeaderAppBar(
        tester,
        projectId: projectId,
        projectName: projectName,
        onProjectTap: null,
        onSearchTap: null,
        onNotificationTap: null,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(projectName));
      await tester.pumpAndSettle();

      final searchIcon = find.byKey(const Key('project_header_search_button'));
      await tester.tap(searchIcon);
      await tester.pumpAndSettle();

      final notificationIcon = find.byKey(
        const Key('project_header_notification_button'),
      );
      await tester.tap(notificationIcon);
      await tester.pumpAndSettle();

      expect(find.text(projectName), findsOneWidget);
    });

    testWidgets('renders avatar with provided image', (
      WidgetTester tester,
    ) async {
      const projectId = 'test-project-id';
      const projectName = 'Test Project';
      const avatarUrl = 'https://example.com/avatar.jpg';

      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exception is NetworkImageLoadException) return;
        originalOnError!.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      await pumpProjectHeaderAppBar(
        tester,
        projectId: projectId,
        projectName: projectName,
        avatarImage: const NetworkImage(avatarUrl),
      );

      final coreAvatarFinder = find.byWidgetPredicate(
        (widget) => widget is CoreAvatar && widget.image is NetworkImage,
      );
      expect(coreAvatarFinder, findsOneWidget);

      final coreAvatar = tester.widget<CoreAvatar>(coreAvatarFinder);
      expect((coreAvatar.image! as NetworkImage).url, avatarUrl);
    });

    testWidgets('shows error message when project fails to load', (
      WidgetTester tester,
    ) async {
      const projectId = 'non-existent-project';

      await pumpProjectHeaderAppBar(
        tester,
        projectId: projectId,
        projectName: '',
        shouldThrowOnGetProject: true,
      );

      await tester.pumpAndSettle();

      expect(find.text(l10n().projectLoadError), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
