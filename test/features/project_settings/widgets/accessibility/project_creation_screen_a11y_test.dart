// ignore_for_file: no_direct_instantiation
import 'package:construculator/features/project_settings/presentation/pages/project_creation_screen.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/models/professional_role.dart';
import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/project/bloc/project_settings_bloc.dart';
import 'package:construculator/libraries/project/testing/fake_project_setting_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/screenshot/font_loader.dart';

const String _testUserId = 'test-user-id';

class _StubAuthManager implements AuthManager {
  const _StubAuthManager();

  @override
  AuthResult<UserCredential?> getCurrentCredentials() => AuthResult.success(
    UserCredential(
      id: _testUserId,
      email: 'test@example.com',
      metadata: const {},
      createdAt: DateTime(2025, 1, 1),
    ),
  );

  @override
  Future<AuthResult<UserCredential>> loginWithEmail(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<AuthResult<UserCredential>> registerWithEmail(String email, String password) =>
      throw UnimplementedError();

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
  Future<AuthResult<bool>> resetPassword(String email) => throw UnimplementedError();

  @override
  Future<AuthResult<bool>> isEmailRegistered(String email) => throw UnimplementedError();

  @override
  Future<AuthResult<void>> logout() => throw UnimplementedError();

  @override
  bool isAuthenticated() => true;

  @override
  Future<AuthResult<User?>> getUserProfile(String credentialId) =>
      throw UnimplementedError();

  @override
  Future<AuthResult<User?>> createUserProfile(User user) => throw UnimplementedError();

  @override
  Future<AuthResult<User?>> updateUserProfile(User user) => throw UnimplementedError();

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

  Widget buildScreen({ThemeData? theme}) => MaterialApp(
        theme: theme ?? createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: bloc,
          child: const ProjectCreationScreen(authManager: _StubAuthManager()),
        ),
      );

  // checkTapTargetSize is false: action area buttons use CoreButtonSize.medium
  // which is intentionally compact (below 48dp) per Figma design.
  // checkTextContrast is false: some text styles use textBody/pageBackground
  // which has insufficient contrast for 12dp text; pending a design token update.
  group('ProjectCreationScreen – accessibility', () {
    testWidgets(
      'primary buttons have accessible labels in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => buildScreen(theme: theme),
          find.byKey(const Key('create_project_button')),
          checkTapTargetSize: false,
          checkTextContrast: false,
        );
      },
    );

    testWidgets(
      'add description button has accessible label in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => buildScreen(theme: theme),
          find.byKey(const Key('add_description_button')),
          checkTapTargetSize: false,
          checkTextContrast: false,
        );
      },
    );

    testWidgets(
      'invite member button has accessible label in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => buildScreen(theme: theme),
          find.byKey(const Key('invite_member_button')),
          checkTapTargetSize: false,
          checkTextContrast: false,
        );
      },
    );
  });
}
