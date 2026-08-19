import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/auth/auth_module.dart';
import 'package:construculator/features/auth/presentation/bloc/login_with_email_bloc/login_with_email_bloc.dart';
import 'package:construculator/features/auth/presentation/pages/login_with_email_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/l10n/generated/app_localizations_en.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/router/testing/router_test_module.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/clock_test_module.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../../utils/screenshot/font_loader.dart';

/// Guards the assumptions the pre-login performance journey makes about this
/// page.
///
/// The journey lives in `integration_test/`, which neither `flutter test` nor
/// any per-PR workflow executes, and `flutter drive` needs a physical device.
/// A finder that silently stops matching there would only surface as a failed
/// weekly lab run, so the assumptions are pinned here instead.
class _ScrollContractModule extends Module {
  final AppBootstrap appBootstrap;
  _ScrollContractModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    RouterTestModule(),
    ClockTestModule(),
    AuthModule(appBootstrap),
  ];
}

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late FakeAppRouter router;

  setUpAll(() {
    fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
    CoreToast.disableTimers();
    Modular.init(
      _ScrollContractModule(
        FakeAppBootstrapFactory.create(supabaseWrapper: fakeSupabase),
      ),
    );
    Modular.replaceInstance<SupabaseWrapper>(fakeSupabase);
    router = Modular.get<AppRouter>() as FakeAppRouter;
  });

  tearDownAll(() {
    Modular.destroy();
    CoreToast.enableTimers();
  });

  setUp(() {
    fakeSupabase.reset();
  });

  Future<void> renderPage(WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider<LoginWithEmailBloc>(
        create: (_) => Modular.get<LoginWithEmailBloc>(),
        child: MaterialApp(
          theme: createTestTheme(),
          home: LoginWithEmailPage(email: '', router: router),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('pre-login performance journey contract', () {
    testWidgets('the journey readiness text identifies the login screen', (
      WidgetTester tester,
    ) async {
      await renderPage(tester);

      expect(find.text(AppLocalizationsEn().welcomeBack), findsOneWidget);
    });

    testWidgets('the journey scroll target is unambiguous', (
      WidgetTester tester,
    ) async {
      await renderPage(tester);

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('a bare Scrollable finder would be ambiguous', (
      WidgetTester tester,
    ) async {
      await renderPage(tester);

      // The email field's EditableText builds its own Scrollable, so the page
      // holds two. The journey must target the outer scroll view specifically,
      // because fling throws on an ambiguous finder.
      expect(find.byType(Scrollable), findsNWidgets(2));
    });

    testWidgets('flinging the journey target does not throw', (
      WidgetTester tester,
    ) async {
      await renderPage(tester);

      await tester.fling(
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
        800,
      );
      await tester.pumpAndSettle();
    });
  });
}
