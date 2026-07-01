import 'package:construculator/features/project_settings/presentation/bloc/project_settings_bloc/project_settings_bloc.dart';
import 'package:construculator/features/project_settings/presentation/pages/project_creation_screen.dart';
import 'package:construculator/features/project_settings/presentation/widgets/project_name_text_field.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/project/testing/fake_project_setting_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';
import '../testing/stub_auth_manager.dart';

const Size _screenSize = Size(390, 844);
const double _pixelRatio = 1.0;

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
          child: const ProjectCreationScreen(authManager: StubAuthManager()),
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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ProjectCreationScreen),
        matchesGoldenFile(goldenPath('project_creation_initial_dark')),
      );
    });
  });
}
