import 'package:construculator/app/shell/app_shell_bloc/app_shell_bloc.dart';
import 'package:construculator/app/shell/app_shell_page.dart';
import 'package:construculator/app/shell/shell_module.dart';
import 'package:construculator/app/shell/widgets/header_row.dart';
import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_dropdown_bloc/project_dropdown_bloc.dart';
import 'package:construculator/features/dashboard/presentation/bloc/recent_estimations_bloc/recent_estimations_bloc.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/presentation/project_ui_provider.dart';
import 'package:construculator/libraries/project/testing/fake_current_project_notifier.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  late FakeCurrentProjectNotifier fakeProjectNotifier;

  setUpAll(() {
    CoreToast.disableTimers();
  });

  tearDownAll(() {
    CoreToast.enableTimers();
  });

  setUp(() {
    fakeProjectNotifier = FakeCurrentProjectNotifier();
    final fakeClock = FakeClockImpl();
    final fakeSupabase = FakeSupabaseWrapper(clock: fakeClock);
    fakeSupabase.setCurrentUser(
      FakeUser(id: 'fake-id', createdAt: fakeClock.now().toIso8601String()),
    );
    fakeSupabase.addTableData('users', [
      User(
        id: '1',
        credentialId: 'fake-id',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        professionalRole: 'Engineer',
        createdAt: fakeClock.now(),
        updatedAt: fakeClock.now(),
        userStatus: UserProfileStatus.active,
        userPreferences: {},
      ).toJson(),
    ]);
    final appBootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: fakeSupabase,
    );
    Modular.init(ShellModule(appBootstrap));
    Modular.bindModule(DashboardModule(appBootstrap));
    Modular.replaceInstance<CurrentProjectNotifier>(fakeProjectNotifier);
    Modular.replaceInstance<ProjectUIProvider>(_FakeProjectUIProvider());
  });

  tearDown(() => Modular.destroy());

  BuildContext? buildContext;

  Widget makeApp() {
    return MaterialApp(
      theme: CoreTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        buildContext = context;
        return child!;
      },
      home: AppShellPage(
        appShellBloc: Modular.get<AppShellBloc>(),
        projectUIProvider: Modular.get<ProjectUIProvider>(),
        projectDropdownBloc: Modular.get<ProjectDropdownBloc>(),
        currentProjectNotifier: Modular.get<CurrentProjectNotifier>(),
        authNotifier: Modular.get<AuthNotifier>(),
        authManager: Modular.get<AuthManager>(),
        router: Modular.get<AppRouter>(),
        recentEstimationsBloc: Modular.get<RecentEstimationsBloc>(),
      ),
    );
  }

  AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

  group('App bar selection', () {
    testWidgets('shows HeaderRow on home tab when no project is selected', (
      tester,
    ) async {
      await tester.pumpWidget(makeApp());
      await tester.pump();

      expect(find.byType(HeaderRow), findsOneWidget);
    });

    testWidgets('hides HeaderRow on non-home tab when no project is selected', (
      tester,
    ) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel(l10n().calculationsTab));
      await tester.pumpAndSettle();

      expect(find.byType(HeaderRow), findsNothing);
    });

    testWidgets('shows project UI provider app bar when a project is selected', (
      tester,
    ) async {
      fakeProjectNotifier.setCurrentProjectId('project-1');

      await tester.pumpWidget(makeApp());
      await tester.pump();

      expect(find.byType(_FakeProjectAppBar), findsOneWidget);
    });
  });
}

// TODO: [CA-724] Migrate to lib/libraries/project/testing/fake_project_ui_provider.dart
class _FakeProjectUIProvider extends ProjectUIProvider {
  @override
  PreferredSizeWidget buildProjectHeaderAppbar({
    VoidCallback? onProjectTap,
    VoidCallback? onSearchTap,
    VoidCallback? onNotificationTap,
  }) {
    return const PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight),
      child: _FakeProjectAppBar(),
    );
  }
}

class _FakeProjectAppBar extends StatelessWidget {
  const _FakeProjectAppBar();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
