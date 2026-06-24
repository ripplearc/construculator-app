import 'package:construculator/features/project_settings/presentation/bloc/project_settings_bloc/project_settings_bloc.dart';
import 'package:construculator/features/project_settings/presentation/pages/project_creation_screen.dart';
import 'package:construculator/features/project_settings/presentation/widgets/project_name_text_field.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/testing/fake_project_setting_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/screenshot/font_loader.dart';
import '../../testing/stub_auth_manager.dart';

void main() {
  late FakeProjectSettingRepository fakeRepository;
  late ProjectSettingsBloc bloc;

  setUpAll(() async {
    await loadAppFontsAll();
  });

  setUp(() {
    fakeRepository = FakeProjectSettingRepository();
    bloc = ProjectSettingsBloc(repository: fakeRepository);
  });

  tearDown(() {
    bloc.close();
    fakeRepository.reset();
  });

  Widget buildScreen({AuthManager? authManager}) => MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: bloc,
          child: ProjectCreationScreen(
            authManager: authManager ?? const StubAuthManager(),
          ),
        ),
      );

  group('ProjectCreationScreen', () {
    group('Initial state', () {
      testWidgets('submit button is disabled when name is empty', (
        tester,
      ) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        final button = tester.widget<CoreButton>(
          find.byKey(const Key('create_project_button')),
        );
        expect(button.isDisabled, isTrue);
      });

      testWidgets('add description and invite member buttons are present', (
        tester,
      ) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('add_description_button')), findsOneWidget);
        expect(find.byKey(const Key('invite_member_button')), findsOneWidget);
      });
    });

    group('Name validation', () {
      testWidgets('submit enables when a valid name is entered', (
        tester,
      ) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(ProjectNameTextField),
          'My Building',
        );
        await tester.pumpAndSettle();

        final button = tester.widget<CoreButton>(
          find.byKey(const Key('create_project_button')),
        );
        expect(button.isDisabled, isFalse);
      });

      testWidgets('submit disables again after name is cleared', (
        tester,
      ) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(ProjectNameTextField),
          'My Building',
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(ProjectNameTextField), '');
        await tester.pumpAndSettle();

        final button = tester.widget<CoreButton>(
          find.byKey(const Key('create_project_button')),
        );
        expect(button.isDisabled, isTrue);
      });
    });

    group('Form submission', () {
      testWidgets(
        'tapping submit dispatches ProjectSettingsCreationRequested',
        (tester) async {
          await tester.pumpWidget(buildScreen());
          await tester.pumpAndSettle();

          await tester.enterText(
            find.byType(ProjectNameTextField),
            'New Project',
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('create_project_button')));
          await tester.pump();

          expect(bloc.state, isA<ProjectSettingsCreating>());
        },
      );

      testWidgets(
        'submit calls createProject with correct name and creatorUserId',
        (tester) async {
          await tester.pumpWidget(buildScreen());
          await tester.pumpAndSettle();

          await tester.enterText(
            find.byType(ProjectNameTextField),
            'My Building',
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('create_project_button')));
          await tester.pump();
          await tester.pump();

          final calls = fakeRepository.getMethodCallsFor('createProject');
          expect(calls, hasLength(1));
          final project = calls.first['project'] as Project;
          expect(project.projectName, 'My Building');
          expect(project.creatorUserId, kStubTestUserId);
        },
      );

      testWidgets(
        'submit button is disabled while ProjectSettingsCreating state is active',
        (tester) async {
          await tester.pumpWidget(buildScreen());
          await tester.pumpAndSettle();

          bloc.emit(const ProjectSettingsCreating());
          await tester.pump();

          final button = tester.widget<CoreButton>(
            find.byKey(const Key('create_project_button')),
          );
          expect(button.isDisabled, isTrue);
        },
      );

      testWidgets('ProjectSettingsCreated state pops the screen', (tester) async {
        bool popped = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: createTestTheme(),
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider.value(
                        value: bloc,
                        child: const ProjectCreationScreen(
                          authManager: StubAuthManager(),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
            navigatorObservers: [
              _PopObserver(onPop: () => popped = true),
            ],
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.byType(ProjectCreationScreen), findsOneWidget);

        final createdProject = Project(
          id: 'proj-1',
          projectName: 'Test',
          creatorUserId: kStubTestUserId,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
          status: ProjectStatus.active,
        );
        bloc.emit(ProjectSettingsCreated(createdProject));
        await tester.pumpAndSettle();

        expect(popped, isTrue);
      });
    });
  });
}

class _PopObserver extends NavigatorObserver {
  final VoidCallback onPop;
  _PopObserver({required this.onPop});

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onPop();
  }
}
