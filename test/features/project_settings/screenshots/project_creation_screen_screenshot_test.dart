// ignore_for_file: no_direct_instantiation
import 'package:construculator/libraries/project/bloc/project_settings_bloc.dart';
import 'package:construculator/features/project_settings/presentation/pages/project_creation_screen.dart';
import 'package:construculator/features/project_settings/presentation/widgets/project_name_text_field.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/models/professional_role.dart';
import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/project/testing/fake_project_setting_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

const String _testUserId = 'test-user-id';
const Size _screenSize = Size(390, 844);
const double _pixelRatio = 1.0;

class _StubAuthManager implements AuthManager {
  const _StubAuthManager();

  @override
  AuthResult<UserCredential?> getCurrentCredentials() =>
      AuthResult.success(
        UserCredential(
          id: _testUserId,
          email: 'test@example.com',
          metadata: const {},
          createdAt: DateTime(2025, 1, 1),
        ),
      );

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
  bool isAuthenticated() => true;

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
  TestWidgetsFlutterBinding.ensureInitialized();

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
        debugShowCheckedModeBanner: false,
        home: BlocProvider.value(
          value: bloc,
          child: const ProjectCreationScreen(authManager: _StubAuthManager()),
        ),
      );

  String goldenPath(String name) =>
      'goldens/project_creation_screen/${_screenSize.width.toInt()}x${_screenSize.height.toInt()}/$name.png';

  group('ProjectCreationScreen Screenshot Tests', () {
    testWidgets('initial state — empty form, submit disabled', (tester) async {
      tester.view.physicalSize = _screenSize;
      tester.view.devicePixelRatio = _pixelRatio;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(milliseconds: 100));

      await expectLater(
        find.byType(ProjectCreationScreen),
        matchesGoldenFile(goldenPath('project_creation_initial_light')),
      );
    });

    testWidgets('with valid name — submit enabled', (tester) async {
      tester.view.physicalSize = _screenSize;
      tester.view.devicePixelRatio = _pixelRatio;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(ProjectNameTextField), 'My Project');
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ProjectCreationScreen),
        matchesGoldenFile(goldenPath('project_creation_with_name_light')),
      );
    });

    testWidgets('initial state — dark theme', (tester) async {
      tester.view.physicalSize = _screenSize;
      tester.view.devicePixelRatio = _pixelRatio;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildScreen(theme: createTestThemeDark()));
      await tester.pump(const Duration(milliseconds: 100));

      await expectLater(
        find.byType(ProjectCreationScreen),
        matchesGoldenFile(goldenPath('project_creation_initial_dark')),
      );
    });
  });
}
