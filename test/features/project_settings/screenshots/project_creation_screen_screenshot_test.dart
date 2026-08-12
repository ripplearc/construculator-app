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

  Widget buildScreen({required ThemeData theme}) => MaterialApp(
        theme: theme,
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

  screenshotThemeGroups('ProjectCreationScreen Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('initial state — empty form, submit disabled', (tester) async {
      tester.view.physicalSize = _screenSize;
      tester.view.devicePixelRatio = _pixelRatio;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildScreen(theme: theme));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ProjectCreationScreen),
        matchesGoldenFile(goldenPath('project_creation_initial$suffix')),
      );
    });

    testWidgets('error state — submit attempted with empty name', (
      tester,
    ) async {
      tester.view.physicalSize = _screenSize;
      tester.view.devicePixelRatio = _pixelRatio;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildScreen(theme: theme));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('create_project_button')));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ProjectCreationScreen),
        matchesGoldenFile(goldenPath('project_creation_error_state$suffix')),
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
      await tester.pumpWidget(buildScreen(theme: theme));
      // A single pump freezes the indicator's deterministic pre-load frame —
      // the Lottie composition loads asynchronously and never resolves inside
      // the fake-async zone, matching the search_results_list loading golden
      // pattern. runAsync + a timed pump would capture a wall-clock-dependent
      // animation frame that renders differently across CPU architectures.
      await tester.pump();

      await expectLater(
        find.byType(ProjectCreationScreen),
        matchesGoldenFile(goldenPath('project_creation_loading$suffix')),
      );
    });
  });

  // This scenario only ever had a light golden; screenshotThemeGroups always
  // produces both light and dark, so it stays outside it rather than gaining
  // a new dark golden as a side effect of this migration.
  group('ProjectCreationScreen Screenshot Tests - Light Only', () {
    testWidgets('with valid name — submit enabled', (tester) async {
      tester.view.physicalSize = _screenSize;
      tester.view.devicePixelRatio = _pixelRatio;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildScreen(theme: createTestTheme()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(ProjectNameTextField), 'My Project');
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ProjectCreationScreen),
        matchesGoldenFile(goldenPath('project_creation_with_name_light')),
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
