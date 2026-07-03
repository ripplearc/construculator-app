import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/project_settings/presentation/bloc/project_settings_bloc/project_settings_bloc.dart';
import 'package:construculator/features/project_settings/presentation/pages/project_creation_screen.dart';
import 'package:construculator/features/project_settings/presentation/widgets/project_name_text_field.dart';
import 'package:construculator/features/project_settings/project_settings_routes_module.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/project/domain/repositories/project_setting_repository.dart';
import 'package:construculator/libraries/project/testing/fake_project_setting_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';
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
    Modular.init(
      _ProjectCreationScreenTestModule(FakeAppBootstrapFactory.create()),
    );
  });

  tearDownAll(() {
    Modular.dispose();
  });

  setUp(() {
    Modular.replaceInstance<ProjectSettingRepository>(
      FakeProjectSettingRepository(),
    );
    fakeRepository =
        Modular.get<ProjectSettingRepository>() as FakeProjectSettingRepository;
    bloc = Modular.get<ProjectSettingsBloc>();
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

    testWidgets('error state — submit attempted with empty name, light theme', (
      tester,
    ) async {
      tester.view.physicalSize = _screenSize;
      tester.view.devicePixelRatio = _pixelRatio;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('create_project_button')));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ProjectCreationScreen),
        matchesGoldenFile(goldenPath('project_creation_error_state_light')),
      );
    });

    testWidgets('error state — submit attempted with empty name, dark theme', (
      tester,
    ) async {
      tester.view.physicalSize = _screenSize;
      tester.view.devicePixelRatio = _pixelRatio;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildScreen(theme: createTestThemeDark()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('create_project_button')));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ProjectCreationScreen),
        matchesGoldenFile(goldenPath('project_creation_error_state_dark')),
      );
    });

    testWidgets('creating state — submit button shows loading indicator', (
      tester,
    ) async {
      tester.view.physicalSize = _screenSize;
      tester.view.devicePixelRatio = _pixelRatio;
      addTearDown(tester.view.reset);

      // Seed the in-flight state before the first build so the button
      // renders its loading indicator from the initial frame.
      bloc.emit(const ProjectSettingsCreating());
      await tester.pumpWidget(buildScreen());
      // Let the Lottie composition load on the real event loop, then pump a
      // fixed frame; pumpAndSettle would hang on the looping animation.
      await tester.runAsync(() async {});
      await tester.pump(const Duration(milliseconds: 750));

      await expectLater(
        find.byType(ProjectCreationScreen),
        matchesGoldenFile(goldenPath('project_creation_loading_light')),
      );
    });

    testWidgets('creating state — loading indicator, dark theme', (
      tester,
    ) async {
      tester.view.physicalSize = _screenSize;
      tester.view.devicePixelRatio = _pixelRatio;
      addTearDown(tester.view.reset);

      // Seed the in-flight state before the first build so the button
      // renders its loading indicator from the initial frame.
      bloc.emit(const ProjectSettingsCreating());
      await tester.pumpWidget(buildScreen(theme: createTestThemeDark()));
      // Let the Lottie composition load on the real event loop, then pump a
      // fixed frame; pumpAndSettle would hang on the looping animation.
      await tester.runAsync(() async {});
      await tester.pump(const Duration(milliseconds: 750));

      await expectLater(
        find.byType(ProjectCreationScreen),
        matchesGoldenFile(goldenPath('project_creation_loading_dark')),
      );
    });
  });
}

class _ProjectCreationScreenTestModule extends Module {
  final AppBootstrap appBootstrap;
  _ProjectCreationScreenTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [ProjectSettingsRoutesModule(appBootstrap)];
}
