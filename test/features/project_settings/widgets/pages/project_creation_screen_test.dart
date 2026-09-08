import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/project_settings/presentation/bloc/project_settings_bloc/project_settings_bloc.dart';
import 'package:construculator/features/project_settings/presentation/pages/project_creation_screen.dart';
import 'package:construculator/features/project_settings/presentation/widgets/project_creation_success_sheet.dart';
import 'package:construculator/features/project_settings/presentation/widgets/project_name_text_field.dart';
import 'package:construculator/features/project_settings/project_settings_routes_module.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_setting_repository.dart';
import 'package:construculator/libraries/project/testing/fake_project_setting_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../../utils/screenshot/font_loader.dart';
import '../../testing/stub_auth_manager.dart';

void main() {
  late FakeProjectSettingRepository fakeRepository;
  late ProjectSettingsBloc bloc;

  setUpAll(() async {
    await loadAppFontsAll();
    Modular.init(
      _ProjectCreationScreenTestModule(FakeAppBootstrapFactory.create()),
    );
  });

  tearDownAll(() {
    Modular.dispose();
  });

  setUp(() {
    CoreToast.disableTimers();
    Modular.replaceInstance<ProjectSettingRepository>(
      FakeProjectSettingRepository(),
    );
    fakeRepository =
        Modular.get<ProjectSettingRepository>() as FakeProjectSettingRepository;
    bloc = Modular.get<ProjectSettingsBloc>();
  });

  tearDown(() {
    CoreToast.enableTimers();
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
      testWidgets('submit button is enabled in initial state', (
        tester,
      ) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        final button = tester.widget<CoreButton>(
          find.byKey(const Key('create_project_button')),
        );
        expect(button.isDisabled, isFalse);
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
      testWidgets('tapping submit with empty name shows required field error', (
        tester,
      ) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('create_project_button')));
        await tester.pumpAndSettle();

        expect(find.text('Project name is required'), findsOneWidget);
      });

      testWidgets('tapping submit with empty name emits name validation error', (
        tester,
      ) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('create_project_button')));
        await tester.pump();

        expect(bloc.state, isA<ProjectSettingsNameValidationError>());
      });

      testWidgets('name error clears after valid name entered post-attempt', (
        tester,
      ) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('create_project_button')));
        await tester.pumpAndSettle();
        expect(find.text('Project name is required'), findsOneWidget);

        await tester.enterText(find.byType(ProjectNameTextField), 'My Building');
        await tester.pumpAndSettle();

        expect(find.text('Project name is required'), findsNothing);
      });

      testWidgets('submitting after entering valid name dispatches creation event', (
        tester,
      ) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(ProjectNameTextField), 'My Building');
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('create_project_button')));
        await tester.pump();

        expect(bloc.state, isA<ProjectSettingsCreating>());
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
        'submit button is disabled and shows loading indicator while '
        'ProjectSettingsCreating state is active',
        (tester) async {
          await tester.pumpWidget(buildScreen());
          await tester.pumpAndSettle();

          bloc.emit(const ProjectSettingsCreating());
          await tester.pump();
          await tester.pump();

          final button = tester.widget<CoreButton>(
            find.byKey(const Key('create_project_button')),
          );
          expect(button.isDisabled, isTrue);
          expect(
            find.byKey(const Key('create_project_button_loading')),
            findsOneWidget,
          );
          expect(find.byType(CoreLoadingIndicator), findsOneWidget);
        },
      );

      testWidgets(
        'loading indicator is hidden while creation is not in flight',
        (tester) async {
          await tester.pumpWidget(buildScreen());
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('create_project_button_loading')),
            findsNothing,
          );
        },
      );
    });

    group('Creation success', () {
      testWidgets(
        'ProjectSettingsCreated state shows the success sheet without popping '
        'the screen',
        (tester) async {
          await tester.pumpWidget(buildScreen());
          await tester.pumpAndSettle();

          bloc.emit(ProjectSettingsCreated(_buildCreatedProject()));
          await tester.pumpAndSettle();

          expect(
            find.byType(ProjectCreationSuccessSheetContent),
            findsOneWidget,
          );
          expect(find.byType(ProjectCreationScreen), findsOneWidget);
        },
      );

      testWidgets(
        'continue button dismisses the sheet and pops the screen back to the '
        'previous route',
        (tester) async {
          int popCount = 0;

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
                _PopObserver(onPop: () => popCount++),
              ],
            ),
          );

          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();

          bloc.emit(ProjectSettingsCreated(_buildCreatedProject()));
          await tester.pumpAndSettle();
          expect(
            find.byType(ProjectCreationSuccessSheetContent),
            findsOneWidget,
          );

          await tester.tap(
            find.byKey(const Key('continue_to_dashboard_button')),
          );
          await tester.pumpAndSettle();

          // One pop for the sheet, one for the creation screen.
          expect(popCount, 2);
          expect(find.byType(ProjectCreationSuccessSheetContent), findsNothing);
          expect(find.byType(ProjectCreationScreen), findsNothing);
        },
      );

      testWidgets(
        'full creation flow: enter name, submit, then surface the '
        'success sheet',
        (tester) async {
          await tester.pumpWidget(buildScreen());
          await tester.pumpAndSettle();

          await tester.enterText(
            find.byType(ProjectNameTextField),
            'My Building',
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('create_project_button')));
          // The repository call completes on the real event loop, so yield to
          // it before pumping the resulting state into the widget tree.
          await tester.runAsync(() async {});
          await tester.pumpAndSettle();

          expect(
            find.byType(ProjectCreationSuccessSheetContent),
            findsOneWidget,
          );
          final calls = fakeRepository.getMethodCallsFor('createProject');
          expect(calls, hasLength(1));
          final project = calls.first['project'] as Project;
          expect(project.projectName, 'My Building');
          expect(project.creatorUserId, kStubTestUserId);
        },
      );
    });

    group('Creation failure', () {
      testWidgets(
        'creation failure shows the error toast and keeps the screen open',
        (tester) async {
          fakeRepository.shouldFailOnCreate = true;

          await tester.pumpWidget(buildScreen());
          await tester.pumpAndSettle();

          await tester.enterText(
            find.byType(ProjectNameTextField),
            'My Building',
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('create_project_button')));
          // The repository call completes on the real event loop, so yield to
          // it before pumping the resulting state into the widget tree.
          await tester.runAsync(() async {});
          await tester.pumpAndSettle();

          expect(
            find.text(
              'An unexpected error occurred, try again or contact support.',
            ),
            findsOneWidget,
          );
          expect(find.byType(ProjectCreationSuccessSheetContent), findsNothing);
          expect(find.byType(ProjectCreationScreen), findsOneWidget);
        },
      );

      testWidgets(
        'submit button is re-enabled after a creation failure',
        (tester) async {
          fakeRepository.shouldFailOnCreate = true;

          await tester.pumpWidget(buildScreen());
          await tester.pumpAndSettle();

          await tester.enterText(
            find.byType(ProjectNameTextField),
            'My Building',
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('create_project_button')));
          // The repository call completes on the real event loop, so yield to
          // it before pumping the resulting state into the widget tree.
          await tester.runAsync(() async {});
          await tester.pumpAndSettle();

          final button = tester.widget<CoreButton>(
            find.byKey(const Key('create_project_button')),
          );
          expect(button.isDisabled, isFalse);
          expect(
            find.byKey(const Key('create_project_button_loading')),
            findsNothing,
          );
        },
      );
    });
  });
}

Project _buildCreatedProject() => Project(
      id: 'proj-1',
      projectName: 'Test',
      creatorUserId: kStubTestUserId,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      status: ProjectStatus.active,
    );

class _PopObserver extends NavigatorObserver {
  final VoidCallback onPop;
  _PopObserver({required this.onPop});

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onPop();
  }
}

class _ProjectCreationScreenTestModule extends Module {
  final AppBootstrap appBootstrap;
  _ProjectCreationScreenTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [ProjectSettingsRoutesModule(appBootstrap)];
}
