import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/your_rates_repository.dart';
import 'package:construculator/features/estimation/estimation_routes_module.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_item_form_screen.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_details_tab_view.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_header.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_surface.dart';
import 'package:construculator/features/estimation/presentation/widgets/your_rates_recents_sheet.dart';
import 'package:construculator/features/project/project_module.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/company/domain/current_company_resolver.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/estimation_routes.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/router/testing/router_test_module.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:construculator/libraries/time/testing/clock_test_module.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';

class _CostEstimationDetailsPageTestModule extends Module {
  final AppBootstrap appBootstrap;
  _CostEstimationDetailsPageTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    RouterTestModule(),
    ClockTestModule(),
    ProjectModule(appBootstrap),
    AuthLibraryModule(appBootstrap),
  ];

  @override
  void routes(RouteManager r) {
    r.module(estimationBaseRoute, module: EstimationRoutesModule(appBootstrap));
  }
}

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late Clock clock;
  late AppBootstrap appBootstrap;

  const testEstimationId = 'test-estimation-id';
  const testEstimationRoute = '$fullEstimationDetailsRoute/$testEstimationId';

  setUpAll(() {
    CoreToast.disableTimers();

    clock = FakeClockImpl();
    fakeSupabase = FakeSupabaseWrapper(clock: clock);

    appBootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: fakeSupabase,
    );
    Modular.init(_CostEstimationDetailsPageTestModule(appBootstrap));
    Modular.setInitialRoute(testEstimationRoute);
  });

  tearDownAll(() {
    Modular.destroy();
    CoreToast.enableTimers();
  });

  setUp(() {
    fakeSupabase.reset();
    Modular.get<CurrentCompanyResolver>().clearCache();
    fakeSupabase.setRpcResponse(
      DatabaseConstants.getMyCompanyIdRpcFunction,
      'company-1',
    );
    (Modular.get<AppRouter>() as FakeAppRouter).reset();
  });

  Widget makeApp() {
    return MaterialApp.router(
      routerConfig: Modular.routerConfig,
      theme: CoreTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  Future<void> pumpAppAtRoute(WidgetTester tester, String route) async {
    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();
    Modular.to.navigate(route);
    await tester.pumpAndSettle();
  }

  void setUpAuthenticatedUser({
    required String credentialId,
    required String email,
    String userId = 'user-1',
    String? profilePhotoUrl,
  }) {
    fakeSupabase.setCurrentUser(
      FakeUser(
        id: credentialId,
        email: email,
        createdAt: clock.now().toIso8601String(),
      ),
    );

    fakeSupabase.addTableData('users', [
      {
        'id': userId,
        'credential_id': credentialId,
        'email': email,
        'first_name': 'John',
        'last_name': 'Doe',
        'professional_role': 'Engineer',
        'profile_photo_url': profilePhotoUrl,
        'created_at': clock.now().toIso8601String(),
        'updated_at': clock.now().toIso8601String(),
        'user_status': 'active',
        'user_preferences': {'': ''},
      },
    ]);
  }

  group('CostEstimationDetailsPage', () {
    late AppLocalizations l10n;

    setUpAll(() {
      l10n = lookupAppLocalizations(const Locale('en'));
    });

    testWidgets('renders page successfully', (WidgetTester tester) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      await pumpAppAtRoute(tester, testEstimationRoute);

      expect(find.byType(CostEstimationDetailsTabView), findsOneWidget);
    });

    testWidgets('app bar is a CoreAppBar on the Figma Action Bar geometry', (
      WidgetTester tester,
    ) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      await pumpAppAtRoute(tester, testEstimationRoute);

      expect(find.byType(CoreAppBar), findsOneWidget);
      expect(
        tester.getSize(find.byType(CoreAppBar)).height,
        CoreSpacing.space12 + CoreSpacing.space2 * 2,
      );
    });

    testWidgets('displays back navigation button', (WidgetTester tester) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      await pumpAppAtRoute(tester, testEstimationRoute);

      expect(find.byKey(const Key('back_button')), findsOneWidget);
    });

    testWidgets('displays edit icon in app bar', (WidgetTester tester) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      await pumpAppAtRoute(tester, testEstimationRoute);

      expect(
        find.byKey(const Key('edit_estimation_name_icon')),
        findsOneWidget,
      );
    });

    testWidgets('displays more menu icon', (WidgetTester tester) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      await pumpAppAtRoute(tester, testEstimationRoute);

      expect(find.byKey(const Key('more_options_icon')), findsOneWidget);
    });

    testWidgets('displays add material cost floating action button', (
      WidgetTester tester,
    ) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      await pumpAppAtRoute(tester, testEstimationRoute);

      expect(find.byKey(const Key('add_material_cost_button')), findsOneWidget);
      expect(find.text(l10n.addMaterialCostButton), findsOneWidget);
    });

    testWidgets(
      'tapping add material cost button navigates to cost item form',
      (WidgetTester tester) async {
        setUpAuthenticatedUser(
          credentialId: 'test-credential-id',
          email: 'test@example.com',
        );

        await pumpAppAtRoute(tester, testEstimationRoute);

        await tester.tap(find.byKey(const Key('add_material_cost_button')));
        await tester.pump();

        final fakeRouter = Modular.get<AppRouter>() as FakeAppRouter;
        expect(
          fakeRouter.navigationHistory,
          contains(
            RouteCall('$fullAddMaterialCostRoute/$testEstimationId', null),
          ),
        );
        expect(find.byType(BottomSheet), findsNothing);
      },
    );

    testWidgets('displays preview button in bottom bar', (
      WidgetTester tester,
    ) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      await pumpAppAtRoute(tester, testEstimationRoute);

      expect(find.byKey(const Key('preview_button')), findsOneWidget);
      expect(find.text(l10n.previewButton), findsOneWidget);
    });

    testWidgets('displays lock icon in bottom bar', (
      WidgetTester tester,
    ) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      await pumpAppAtRoute(tester, testEstimationRoute);

      expect(find.byKey(const Key('lock_icon')), findsOneWidget);
    });

    testWidgets('FAB shows add labour cost after switching to labours tab', (
      WidgetTester tester,
    ) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      await pumpAppAtRoute(tester, testEstimationRoute);

      await tester.tap(find.text(l10n.laboursTab));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('add_labour_cost_button')), findsOneWidget);
      expect(find.text(l10n.addLabourCostButton), findsOneWidget);
    });

    testWidgets(
      'FAB shows add equipment cost after switching to equipments tab',
      (WidgetTester tester) async {
        setUpAuthenticatedUser(
          credentialId: 'test-credential-id',
          email: 'test@example.com',
        );

        await pumpAppAtRoute(tester, testEstimationRoute);

        await tester.tap(find.text(l10n.equipmentsTab));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('add_equipment_cost_button')),
          findsOneWidget,
        );
        expect(find.text(l10n.addEquipmentCostButton), findsOneWidget);
      },
    );

    testWidgets(
      'FAB returns to material after switching back to materials tab',
      (WidgetTester tester) async {
        setUpAuthenticatedUser(
          credentialId: 'test-credential-id',
          email: 'test@example.com',
        );

        await pumpAppAtRoute(tester, testEstimationRoute);

        await tester.tap(find.text(l10n.laboursTab));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.materialsTab));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('add_material_cost_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'tapping add labour cost button navigates to labour cost form',
      (WidgetTester tester) async {
        setUpAuthenticatedUser(
          credentialId: 'test-credential-id',
          email: 'test@example.com',
        );

        await pumpAppAtRoute(tester, testEstimationRoute);

        await tester.tap(find.text(l10n.laboursTab));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('add_labour_cost_button')));
        await tester.pump();

        final fakeRouter = Modular.get<AppRouter>() as FakeAppRouter;
        expect(
          fakeRouter.navigationHistory,
          contains(
            RouteCall('$fullAddLabourCostRoute/$testEstimationId', null),
          ),
        );
        expect(find.byType(BottomSheet), findsNothing);
      },
    );

    testWidgets(
      'tapping add equipment cost button opens "Your recents" instead of '
      'navigating to a route',
      (WidgetTester tester) async {
        setUpAuthenticatedUser(
          credentialId: 'test-credential-id',
          email: 'test@example.com',
        );

        await pumpAppAtRoute(tester, testEstimationRoute);

        await tester.tap(find.text(l10n.equipmentsTab));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('add_equipment_cost_button')));
        await tester.pumpAndSettle();

        expect(find.byType(YourRatesRecentsSheet), findsOneWidget);
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(find.byType(CostItemFormScreen), findsNothing);

        final fakeRouter = Modular.get<AppRouter>() as FakeAppRouter;
        expect(
          fakeRouter.navigationHistory,
          isNot(
            contains(
              RouteCall('$fullAddEquipmentCostRoute/$testEstimationId', null),
            ),
          ),
        );
      },
    );

    testWidgets(
      '"Your recents" has no sample-rate notice and offers "New equipment '
      'cost"',
      (WidgetTester tester) async {
        setUpAuthenticatedUser(
          credentialId: 'test-credential-id',
          email: 'test@example.com',
        );

        await pumpAppAtRoute(tester, testEstimationRoute);

        await tester.tap(find.text(l10n.equipmentsTab));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('add_equipment_cost_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('your_rates_disclaimer')), findsNothing);
        expect(find.byKey(const Key('new_equipment_cost_row')), findsOneWidget);
      },
    );

    testWidgets(
      'tapping "New equipment cost" on "Your recents" opens the form blank',
      (WidgetTester tester) async {
        setUpAuthenticatedUser(
          credentialId: 'test-credential-id',
          email: 'test@example.com',
        );

        await pumpAppAtRoute(tester, testEstimationRoute);

        await tester.tap(find.text(l10n.equipmentsTab));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('add_equipment_cost_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('new_equipment_cost_row')));
        await tester.pumpAndSettle();

        expect(find.byType(CostItemFormScreen), findsOneWidget);
        expect(find.byType(BottomSheet), findsOneWidget);
      },
    );

    testWidgets('swiping "Your recents" down opens no form', (
      WidgetTester tester,
    ) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      await pumpAppAtRoute(tester, testEstimationRoute);
      await tester.tap(find.text(l10n.equipmentsTab));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add_equipment_cost_button')));
      await tester.pumpAndSettle();
      await tester.fling(
        find.byKey(const Key('new_equipment_cost_row')),
        const Offset(0, 600),
        2000,
      );
      await tester.pumpAndSettle();

      expect(find.byType(YourRatesRecentsSheet), findsNothing);
      expect(find.byType(CostItemFormScreen), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('tapping outside "Your recents" opens no form', (
      WidgetTester tester,
    ) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      await pumpAppAtRoute(tester, testEstimationRoute);
      await tester.tap(find.text(l10n.equipmentsTab));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add_equipment_cost_button')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.byType(YourRatesRecentsSheet), findsNothing);
      expect(find.byType(CostItemFormScreen), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets(
      'when the saved rates cannot be read, "New equipment cost" still opens '
      'the blank form',
      (WidgetTester tester) async {
        setUpAuthenticatedUser(
          credentialId: 'test-credential-id',
          email: 'test@example.com',
        );
        fakeSupabase.shouldThrowOnSelectMatch = true;

        await pumpAppAtRoute(tester, testEstimationRoute);
        await tester.tap(find.text(l10n.equipmentsTab));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('add_equipment_cost_button')));
        await tester.pumpAndSettle();

        expect(find.byType(YourRatesRecentsSheet), findsOneWidget);
        expect(find.byKey(const Key('new_equipment_cost_row')), findsOneWidget);

        await tester.tap(find.byKey(const Key('new_equipment_cost_row')));
        await tester.pumpAndSettle();

        expect(find.byType(CostItemFormScreen), findsOneWidget);
      },
    );

    testWidgets('the back arrow on "Your recents" opens no form', (
      WidgetTester tester,
    ) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      await pumpAppAtRoute(tester, testEstimationRoute);
      await tester.tap(find.text(l10n.equipmentsTab));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add_equipment_cost_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(SheetHeader.backButtonKey));
      await tester.pumpAndSettle();

      expect(find.byType(YourRatesRecentsSheet), findsNothing);
      expect(find.byType(CostItemFormScreen), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('the back action on "Your recents" opens no form', (
      WidgetTester tester,
    ) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      await pumpAppAtRoute(tester, testEstimationRoute);
      await tester.tap(find.text(l10n.equipmentsTab));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add_equipment_cost_button')));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(YourRatesRecentsSheet), findsNothing);
      expect(find.byType(CostItemFormScreen), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
    });

    Future<void> seedRecent({
      required String itemName,
      required double amount,
      required EquipmentPricingMethod method,
    }) async {
      final saveResult = await Modular.get<YourRatesRepository>().save(
        YourRateEntry(
          id: '',
          companyId: 'company-1',
          itemName: itemName,
          category: CostItemType.equipment,
          rate: Money(amount: amount),
          savedAt: clock.now().subtract(const Duration(days: 10)),
          equipmentMethod: method,
        ),
      );
      saveResult.fold((f) => throw StateError('seed failed: $f'), (_) {});
    }

    Future<void> openRecents(WidgetTester tester) async {
      await pumpAppAtRoute(tester, testEstimationRoute);
      await tester.tap(find.text(l10n.equipmentsTab));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add_equipment_cost_button')));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'tapping a recent Day row opens the compact saved-rate screen: name and '
      'price in the sheet header, Duration as the only field',
      (WidgetTester tester) async {
        setUpAuthenticatedUser(
          credentialId: 'test-credential-id',
          email: 'test@example.com',
        );
        await seedRecent(
          itemName: 'Scissor lift — 19ft',
          amount: 120,
          method: EquipmentPricingMethod.day,
        );
        await openRecents(tester);
        expect(find.text('Used last week'), findsOneWidget);

        await tester.tap(find.text('Scissor lift — 19ft'));
        await tester.pumpAndSettle();

        expect(find.byType(CostItemFormScreen), findsOneWidget);
        expect(find.text('Scissor lift — 19ft'), findsOneWidget);
        expect(find.text(r'$120.00 /day · your default'), findsOneWidget);
        expect(find.byKey(const Key('equipment_name_field')), findsNothing);
        expect(find.byKey(const Key('day_method_chip')), findsNothing);
        expect(find.byKey(const Key('rate_field')), findsNothing);
        expect(find.byKey(const Key('duration_field')), findsOneWidget);
      },
    );

    testWidgets(
      'tapping a recent Job row opens the compact screen with the amount '
      'filled, and editing the amount keeps it compact',
      (WidgetTester tester) async {
        setUpAuthenticatedUser(
          credentialId: 'test-credential-id',
          email: 'test@example.com',
        );
        await seedRecent(
          itemName: 'Dumpster — 30 yd',
          amount: 400,
          method: EquipmentPricingMethod.job,
        );
        await openRecents(tester);

        await tester.tap(find.text('Dumpster — 30 yd'));
        await tester.pumpAndSettle();

        expect(find.text(r'$400.00 job · your default'), findsOneWidget);
        expect(find.text('400'), findsOneWidget);

        await tester.enterText(find.byKey(const Key('amount_field')), '450');
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('equipment_name_field')), findsNothing);
        expect(find.byKey(const Key('job_method_chip')), findsNothing);
        expect(find.byKey(const Key('amount_field')), findsOneWidget);
      },
    );

    testWidgets(
      'equipment sheet shows the New equipment cost title and no cost-file '
      'mode toggle',
      (WidgetTester tester) async {
        setUpAuthenticatedUser(
          credentialId: 'test-credential-id',
          email: 'test@example.com',
        );

        await pumpAppAtRoute(tester, testEstimationRoute);
        await tester.tap(find.text(l10n.equipmentsTab));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('add_equipment_cost_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('new_equipment_cost_row')));
        await tester.pumpAndSettle();

        expect(find.text('New equipment cost'), findsOneWidget);
        final surface = sheetSurface(tester.element(find.byType(BottomSheet)));
        expect(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is Container &&
                  w.decoration is BoxDecoration &&
                  (w.decoration! as BoxDecoration).color == surface,
            ),
          ),
          findsWidgets,
        );
        expect(find.byKey(const Key('how_to_calculate_label')), findsNothing);
        expect(find.byKey(const Key('from_cost_file_pill')), findsNothing);
      },
    );

    testWidgets('equipment sheet is shorter than 90 percent of the screen', (
      WidgetTester tester,
    ) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      await pumpAppAtRoute(tester, testEstimationRoute);
      await tester.tap(find.text(l10n.equipmentsTab));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add_equipment_cost_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('new_equipment_cost_row')));
      await tester.pumpAndSettle();

      final sheetHeight = tester
          .getSize(find.byType(CostItemFormScreen))
          .height;
      final screenHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      expect(sheetHeight, lessThan(screenHeight * 0.9));
    });

    testWidgets('equipment sheet keeps the Rate field above the keyboard', (
      WidgetTester tester,
    ) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);

      await pumpAppAtRoute(tester, testEstimationRoute);
      await tester.tap(find.text(l10n.equipmentsTab));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add_equipment_cost_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('new_equipment_cost_row')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('rate_field')));
      await tester.pumpAndSettle();

      final screenHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final keyboardTop = screenHeight - 300 / tester.view.devicePixelRatio;
      final rateBottom = tester
          .getRect(find.byKey(const Key('rate_field')))
          .bottom;
      final barTop = tester
          .getRect(find.byKey(const Key('cost_item_total_label')))
          .top;
      expect(tester.takeException(), isNull);
      expect(rateBottom, lessThanOrEqualTo(keyboardTop));
      expect(rateBottom, lessThanOrEqualTo(barTop));
    });

    testWidgets('tapping the back arrow on the equipment sheet closes it', (
      WidgetTester tester,
    ) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      await pumpAppAtRoute(tester, testEstimationRoute);
      await tester.tap(find.text(l10n.equipmentsTab));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add_equipment_cost_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('new_equipment_cost_row')));
      await tester.pumpAndSettle();
      expect(find.byType(CostItemFormScreen), findsOneWidget);

      await tester.tap(find.byKey(SheetHeader.backButtonKey));
      await tester.pumpAndSettle();

      expect(find.byType(CostItemFormScreen), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
    });
  });
}
