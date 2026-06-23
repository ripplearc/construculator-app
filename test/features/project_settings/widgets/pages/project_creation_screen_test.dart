// ignore_for_file: no_direct_instantiation
import 'package:construculator/features/project_settings/presentation/pages/project_creation_screen.dart';
import 'package:construculator/features/project_settings/presentation/widgets/project_name_text_field.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/models/professional_role.dart';
import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/project/bloc/project_settings_bloc.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/testing/fake_project_setting_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/screenshot/font_loader.dart';

const String _testUserId = 'test-user-id';

class _StubAuthManager implements AuthManager {
  final String? userId;

  const _StubAuthManager({this.userId = _testUserId});

  @override
  AuthResult<UserCredential?> getCurrentCredentials() {
    if (userId == null) return const AuthResult.success(null);
    return AuthResult.success(
      UserCredential(
        id: userId!,
        email: 'test@example.com',
        metadata: const {},
        createdAt: DateTime(2025, 1, 1),
      ),
    );
  }

  @override
  Future<AuthResult<UserCredential>> loginWithEmail(
    String email,
    String password,
  ) => throw UnimplementedError();

  @override
  Future<AuthResult<UserCredential>> registerWithEmail(
    String email,
    String password,
  ) => throw UnimplementedError();

  @override
  Future<AuthResult> sendOtp(String address, OtpReceiver receiver) =>
      throw UnimplementedError();

  @override
  Future<AuthResult<UserCredential>> verifyOtp(
    String address,
    String otp,
    OtpReceiver receiver,
  ) => throw UnimplementedError();

  @override
  Future<AuthResult<bool>> resetPassword(String email) =>
      throw UnimplementedError();

  @override
  Future<AuthResult<bool>> isEmailRegistered(String email) =>
      throw UnimplementedError();

  @override
  Future<AuthResult<void>> logout() => throw UnimplementedError();

  @override
  bool isAuthenticated() => userId != null;

  @override
  Future<AuthResult<User?>> getUserProfile(String credentialId) =>
      throw UnimplementedError();

  @override
  Future<AuthResult<User?>> createUserProfile(User user) =>
      throw UnimplementedError();

  @override
  Future<AuthResult<User?>> updateUserProfile(User user) =>
      throw UnimplementedError();

  @override
  Future<AuthResult<UserCredential?>> updateUserPassword(String password) =>
      throw UnimplementedError();

  @override
  Future<AuthResult<UserCredential?>> updateUserEmail(String email) =>
      throw UnimplementedError();

  @override
  Future<AuthResult<List<ProfessionalRole>>> getProfessionalRoles() =>
      throw UnimplementedError();
}

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
            authManager: authManager ?? const _StubAuthManager(),
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

          expect(bloc.state, isA<ProjectCreating>());
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
          expect(project.creatorUserId, _testUserId);
        },
      );

      testWidgets(
        'submit button is disabled while ProjectCreating state is active',
        (tester) async {
          await tester.pumpWidget(buildScreen());
          await tester.pumpAndSettle();

          bloc.emit(const ProjectCreating());
          await tester.pump();

          final button = tester.widget<CoreButton>(
            find.byKey(const Key('create_project_button')),
          );
          expect(button.isDisabled, isTrue);
        },
      );

      testWidgets('ProjectCreated state pops the screen', (tester) async {
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
                        child: ProjectCreationScreen(
                          authManager: const _StubAuthManager(),
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
          creatorUserId: _testUserId,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
          status: ProjectStatus.active,
        );
        bloc.emit(ProjectCreated(createdProject));
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
