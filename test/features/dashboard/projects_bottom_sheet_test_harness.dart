import 'package:construculator/app/shell/shell_module.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_dropdown_bloc/project_dropdown_bloc.dart';
import 'package:construculator/features/dashboard/presentation/widgets/projects_bottom_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/testing/fake_project_repository.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../utils/fake_app_bootstrap_factory.dart';
import '../../utils/screenshot/font_loader.dart';

/// Shared test harness for [ProjectsBottomSheet] widget and screenshot tests.
///
/// Manages DI, fakes, and pumping so both test suites stay in sync.
class ProjectsBottomSheetTestHarness {
  static const String testUserId = 'user-1';

  late FakeClockImpl clock;
  late FakeSupabaseWrapper fakeSupabase;
  late FakeProjectRepository fakeRepository;
  late ProjectDropdownBloc bloc;

  Widget buildTestApp() {
    return MaterialApp(
      theme: createTestTheme(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: ProjectsBottomSheet()),
    );
  }

  /// Pumps the sheet and waits for the BLoC to settle into a terminal state.
  ///
  /// Use [extraPump] for screenshot tests that need an additional frame delay
  /// to let the golden render stabilise before capture.
  Future<void> pumpSheet(
    WidgetTester tester, {
    Duration? extraPump,
  }) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump();
    await tester.runAsync(() async {
      await bloc.stream.firstWhere(
        (state) =>
            state is ProjectDropdownLoadSuccess ||
            state is ProjectDropdownLoadFailure,
      );
    });
    if (extraPump != null) {
      await tester.pump(extraPump);
    } else {
      await tester.pump();
    }
  }

  Future<void> setUpAll() async {
    await loadAppFontsAll();
    clock = FakeClockImpl(DateTime(2025, 1, 1, 8, 0));
  }

  void setUp() {
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
  }

  void tearDown() {
    bloc.close();
    fakeRepository.dispose();
    Modular.destroy();
  }
}
