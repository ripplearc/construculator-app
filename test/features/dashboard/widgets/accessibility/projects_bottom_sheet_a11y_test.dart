import 'package:construculator/app/shell/shell_module.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_dropdown_bloc/project_dropdown_bloc.dart';
import 'package:construculator/features/dashboard/presentation/widgets/projects_bottom_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/testing/fake_project_repository.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../../utils/screenshot/font_loader.dart';

void main() {
  late FakeClockImpl clock;
  late FakeSupabaseWrapper fakeSupabase;
  late FakeProjectRepository fakeRepository;
  late ProjectDropdownBloc bloc;
  final router = FakeAppRouter();

  const String testUserId = 'user-1';
  final l10n = lookupAppLocalizations(const Locale('en'));

  Widget buildTestApp(ThemeData theme) {
    return MaterialApp(
      theme: theme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: ProjectsBottomSheet(bloc: bloc, router: router)),
    );
  }

  setUpAll(() async {
    await loadAppFontsAll();
    clock = FakeClockImpl(DateTime(2025, 1, 1, 8, 0));
  });

  setUp(() {
    fakeSupabase = FakeSupabaseWrapper(clock: clock);
    fakeRepository = FakeProjectRepository();

    final bootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: fakeSupabase,
    );
    Modular.init(ShellModule(bootstrap));
    Modular.replaceInstance<SupabaseWrapper>(fakeSupabase);
    Modular.replaceInstance<ProjectRepository>(fakeRepository);

    fakeSupabase.setCurrentUser(
      FakeUser(
        id: testUserId,
        email: 'user-1@example.com',
        createdAt: clock.now().toIso8601String(),
        appMetadata: const {},
        userMetadata: const {},
      ),
    );

    bloc = Modular.get<ProjectDropdownBloc>();
    Modular.replaceInstance<ProjectDropdownBloc>(bloc);
  });

  tearDown(() {
    bloc.close();
    fakeRepository.dispose();
    Modular.destroy();
  });

  group('ProjectsBottomSheet - accessibility', () {
    testWidgets('create project button meets a11y guidelines in both themes', (
      tester,
    ) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        buildTestApp,
        find.text(l10n.createProjectButton),
      );
    });

    testWidgets('sheet title meets a11y guidelines in both themes', (
      tester,
    ) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        buildTestApp,
        find.text(l10n.projectsSheetTitle),
        checkTapTargetSize: false,
        checkLabeledTapTarget: false,
      );
    });
  });
}
