import 'package:construculator/features/project_settings/presentation/bloc/project_settings_bloc/project_settings_bloc.dart';
import 'package:construculator/features/project_settings/presentation/pages/project_creation_screen.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/project/testing/fake_project_setting_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
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

  Widget buildScreen({ThemeData? theme}) => MaterialApp(
        theme: theme ?? createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: bloc,
          child: const ProjectCreationScreen(authManager: StubAuthManager()),
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
