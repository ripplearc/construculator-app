import 'dart:async';

import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/your_rates_repository.dart';
import 'package:construculator/features/estimation/estimation_routes_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/added_line_highlight_cubit/added_line_highlight_cubit.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_item_form_screen.dart';
import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_footer.dart';
import 'package:construculator/features/estimation/presentation/widgets/confirmation_dialog.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_details_tab_view.dart';
import 'package:construculator/features/estimation/presentation/widgets/guarded_quick_sheet.dart';
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
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:construculator/libraries/time/testing/clock_test_module.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../libraries/estimation/helpers/estimation_test_data_map_factory.dart';
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

  Future<void> pumpAppAtRoute(
    WidgetTester tester,
    String route, {
    void Function()? beforeNavigate,
  }) async {
    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();
    beforeNavigate?.call();
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

  void seedEstimate() {
    fakeSupabase.addTableData(DatabaseConstants.costEstimatesTable, [
      EstimationTestDataMapFactory.createFakeEstimationData(
        id: testEstimationId,
        estimateName: 'Bedroom 2',
        totalCost: 1,
      ),
    ]);
    fakeSupabase.addTableData(DatabaseConstants.costItemsTable, [
      {'estimate_id': testEstimationId, 'item_total_cost': 2000},
      {'estimate_id': testEstimationId, 'item_total_cost': 993.62},
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
      final footerTop = tester
          .getRect(find.byKey(AddToEstimateFooter.panelKey))
          .top;
      expect(tester.takeException(), isNull);
      expect(rateBottom, lessThanOrEqualTo(keyboardTop));
      expect(rateBottom, lessThanOrEqualTo(footerTop));
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

    group('Add to estimate', () {
      Future<void> openEquipmentSheet(WidgetTester tester) async {
        setUpAuthenticatedUser(
          credentialId: 'test-credential-id',
          email: 'test@example.com',
        );
        seedEstimate();
        await pumpAppAtRoute(tester, testEstimationRoute);
        await tester.tap(find.text(l10n.equipmentsTab));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('add_equipment_cost_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('new_equipment_cost_row')));
        await tester.pumpAndSettle();
      }

      Future<void> fillValidDayForm(WidgetTester tester) async {
        await tester.enterText(
          find.byKey(const Key('equipment_name_field')),
          'Scissor lift',
        );
        await tester.enterText(find.byKey(const Key('duration_field')), '4');
        await tester.enterText(find.byKey(const Key('rate_field')), '145');
        await tester.pumpAndSettle();
      }

      Finder addButton() => find.byKey(AddToEstimateFooter.buttonKey);

      testWidgets('starts disabled and names the equipment name as missing', (
        tester,
      ) async {
        await openEquipmentSheet(tester);

        expect(find.text('Adds to this estimate'), findsOneWidget);
        expect(find.text('Needs a name before it can total'), findsOneWidget);
        expect(
          find.text('Enter an equipment name to continue'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('cost_item_total_label')), findsNothing);
      });

      testWidgets('names the next missing field as the form is filled', (
        tester,
      ) async {
        await openEquipmentSheet(tester);

        await tester.enterText(
          find.byKey(const Key('equipment_name_field')),
          'Scissor lift',
        );
        await tester.pumpAndSettle();
        expect(find.text('Enter a duration to continue'), findsOneWidget);

        await tester.enterText(find.byKey(const Key('duration_field')), '4');
        await tester.pumpAndSettle();
        expect(find.text('Enter a rate to continue'), findsOneWidget);

        await tester.enterText(find.byKey(const Key('duration_field')), '0');
        await tester.pumpAndSettle();
        expect(find.text('Fix the duration to continue'), findsOneWidget);
      });

      testWidgets('shows the live line total and the estimate total after', (
        tester,
      ) async {
        await openEquipmentSheet(tester);

        await fillValidDayForm(tester);

        expect(find.text(r'$580.00'), findsOneWidget);
        expect(find.text(r' total  $2,993.62 →'), findsOneWidget);
        expect(find.text(r'$3,573.62'), findsOneWidget);
        expect(find.text('Add to estimate'), findsOneWidget);
      });

      testWidgets('adding saves the line, closes the sheet and shows the '
          'toast', (tester) async {
        await openEquipmentSheet(tester);
        await fillValidDayForm(tester);

        await tester.tap(addButton());
        await tester.pumpAndSettle();

        expect(find.byType(CostItemFormScreen), findsNothing);
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.text('Added to Bedroom 2'), findsOneWidget);
        final inserts = fakeSupabase
            .getMethodCallsFor('insert')
            .where((c) => c['table'] == DatabaseConstants.costItemsTable);
        expect(inserts, hasLength(1));
        final saved = inserts.single['data'] as Map<String, dynamic>;
        expect(saved['estimate_id'], testEstimationId);
        expect(saved['item_total_cost'], 580);
      });

      String? highlightedLine(WidgetTester tester) =>
          BlocProvider.of<AddedLineHighlightCubit>(
            tester.element(find.byType(Scaffold).first),
          ).state;

      testWidgets('marks the equipment line just added and moves the mark to '
          'the next one', (tester) async {
        await openEquipmentSheet(tester);
        expect(highlightedLine(tester), isNull);
        await fillValidDayForm(tester);
        await tester.tap(addButton());
        await tester.pumpAndSettle();
        final first = highlightedLine(tester);
        expect(first, isNotNull);

        await tester.tap(find.byKey(const Key('add_equipment_cost_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('new_equipment_cost_row')));
        await tester.pumpAndSettle();
        await fillValidDayForm(tester);
        await tester.tap(addButton());
        await tester.pumpAndSettle();

        expect(highlightedLine(tester), isNotNull);
        expect(highlightedLine(tester), isNot(first));
      });

      testWidgets('reloads the estimate total after an add', (tester) async {
        await openEquipmentSheet(tester);
        await fillValidDayForm(tester);
        final loadsBefore = fakeSupabase
            .getMethodCallsFor('selectSingle')
            .length;

        await tester.tap(addButton());
        await tester.pumpAndSettle();

        expect(
          fakeSupabase.getMethodCallsFor('selectSingle'),
          hasLength(loadsBefore + 1),
        );
      });

      testWidgets('keeps the sheet open and shows an error when the save '
          'fails', (tester) async {
        await openEquipmentSheet(tester);
        await fillValidDayForm(tester);
        fakeSupabase.shouldThrowOnInsert = true;
        fakeSupabase.insertExceptionType = SupabaseExceptionType.socket;
        fakeSupabase.insertErrorMessage = 'Connection failed';

        await tester.tap(addButton());
        await tester.pumpAndSettle();

        expect(find.byType(CostItemFormScreen), findsOneWidget);
        expect(find.text(l10n.addToEstimateFailedError), findsOneWidget);
        expect(find.text('Added to Bedroom 2'), findsNothing);

        fakeSupabase.shouldThrowOnInsert = false;
        await tester.tap(addButton());
        await tester.pumpAndSettle();

        expect(find.byType(CostItemFormScreen), findsNothing);
        expect(find.text('Added to Bedroom 2'), findsOneWidget);
      });

      testWidgets('a fee larger than the base cost asks before adding', (
        tester,
      ) async {
        await openEquipmentSheet(tester);
        await fillValidDayForm(tester);
        await tester.ensureVisible(find.byKey(const Key('delivery_fee_row')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('delivery_fee_row')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('delivery_fee_field')),
          '8500',
        );
        await tester.pumpAndSettle();

        await tester.tap(addButton());
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('outsized_fee_dialog_title')),
          findsOneWidget,
        );
        expect(find.byType(CostItemFormScreen), findsOneWidget);
        expect(
          fakeSupabase
              .getMethodCallsFor('insert')
              .where((c) => c['table'] == DatabaseConstants.costItemsTable),
          isEmpty,
        );

        await tester.tap(
          find.byKey(const Key('outsized_fee_dialog_add_it_button')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CostItemFormScreen), findsNothing);
        expect(find.text('Added to Bedroom 2'), findsOneWidget);
      });

      testWidgets('a fee within the base cost adds without asking', (
        tester,
      ) async {
        await openEquipmentSheet(tester);
        await fillValidDayForm(tester);
        await tester.ensureVisible(find.byKey(const Key('delivery_fee_row')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('delivery_fee_row')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('delivery_fee_field')),
          '85',
        );
        await tester.pumpAndSettle();

        await tester.tap(addButton());
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('outsized_fee_dialog_title')),
          findsNothing,
        );
        expect(find.text('Added to Bedroom 2'), findsOneWidget);
      });

      testWidgets('shows the delivery fee inside the line total', (
        tester,
      ) async {
        await openEquipmentSheet(tester);
        await fillValidDayForm(tester);
        await tester.ensureVisible(find.byKey(const Key('delivery_fee_row')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('delivery_fee_row')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('delivery_fee_field')),
          '85',
        );
        await tester.pumpAndSettle();

        expect(find.text(r'$665.00'), findsOneWidget);
        expect(find.text('incl. delivery'), findsOneWidget);
        expect(find.text(r'+$85.00'), findsOneWidget);
        expect(find.text(r'$3,658.62'), findsOneWidget);
      });

      testWidgets('a Job line shows the amount as the total', (tester) async {
        await openEquipmentSheet(tester);
        await tester.enterText(
          find.byKey(const Key('equipment_name_field')),
          'Dumpster',
        );
        await tester.tap(find.byKey(const Key('job_method_chip')));
        await tester.pumpAndSettle();
        expect(find.text('Enter an amount to continue'), findsOneWidget);

        await tester.enterText(find.byKey(const Key('amount_field')), '400');
        await tester.pumpAndSettle();

        expect(find.text(r'$400.00'), findsOneWidget);
        expect(find.text(r'$3,393.62'), findsOneWidget);
      });

      testWidgets('closing the sheet without adding reloads the estimate', (
        tester,
      ) async {
        await openEquipmentSheet(tester);
        final loadsBefore = fakeSupabase
            .getMethodCallsFor('selectSingle')
            .length;

        await tester.tap(find.byKey(SheetHeader.backButtonKey));
        await tester.pumpAndSettle();

        expect(
          fakeSupabase.getMethodCallsFor('selectSingle'),
          hasLength(loadsBefore + 1),
        );
        expect(find.text('Added to Bedroom 2'), findsNothing);
      });

      testWidgets('the next sheet adds the saved line to the estimate total', (
        tester,
      ) async {
        await openEquipmentSheet(tester);
        await fillValidDayForm(tester);

        await tester.tap(addButton());
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('add_equipment_cost_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('new_equipment_cost_row')));
        await tester.pumpAndSettle();
        await fillValidDayForm(tester);

        expect(find.text(r' total  $3,573.62 →'), findsOneWidget);
        expect(find.text(r'$4,153.62'), findsOneWidget);
      });

      testWidgets('dismissing the sheet while saving still confirms the add', (
        tester,
      ) async {
        await openEquipmentSheet(tester);
        await fillValidDayForm(tester);
        fakeSupabase.shouldDelayOperations = true;
        fakeSupabase.completer = Completer();

        await tester.tap(addButton());
        await tester.pump();
        await tester.tapAt(const Offset(200, 20));
        await tester.pumpAndSettle();
        expect(find.byType(CostItemFormScreen), findsNothing);
        expect(find.text('Added to Bedroom 2'), findsNothing);

        fakeSupabase.completer!.complete();
        fakeSupabase.shouldDelayOperations = false;
        await tester.pumpAndSettle();

        expect(find.text('Added to Bedroom 2'), findsOneWidget);
      });

      testWidgets('a second tap on Add while saving does not save twice', (
        tester,
      ) async {
        await openEquipmentSheet(tester);
        await fillValidDayForm(tester);
        fakeSupabase.shouldDelayOperations = true;
        fakeSupabase.completer = Completer();

        await tester.tap(addButton());
        await tester.pump();
        await tester.tap(addButton(), warnIfMissed: false);
        await tester.pump();
        fakeSupabase.completer!.complete();
        fakeSupabase.shouldDelayOperations = false;
        await tester.pumpAndSettle();

        expect(
          fakeSupabase
              .getMethodCallsFor('insert')
              .where((c) => c['table'] == DatabaseConstants.costItemsTable),
          hasLength(1),
        );
      });

      testWidgets('a save that fails after the sheet was dismissed still shows '
          'the error', (tester) async {
        await openEquipmentSheet(tester);
        await fillValidDayForm(tester);
        fakeSupabase.shouldDelayOperations = true;
        fakeSupabase.completer = Completer();
        fakeSupabase.shouldThrowOnInsert = true;
        fakeSupabase.insertExceptionType = SupabaseExceptionType.socket;
        fakeSupabase.insertErrorMessage = 'Connection failed';

        await tester.tap(addButton());
        await tester.pump();
        await tester.tapAt(const Offset(200, 20));
        await tester.pumpAndSettle();
        fakeSupabase.completer!.complete();
        fakeSupabase.shouldDelayOperations = false;
        await tester.pumpAndSettle();

        expect(find.text(l10n.addToEstimateFailedError), findsOneWidget);
        expect(find.text('Added to Bedroom 2'), findsNothing);
      });

      testWidgets('the toast names the estimate the sheet was opened from', (
        tester,
      ) async {
        setUpAuthenticatedUser(
          credentialId: 'test-credential-id',
          email: 'test@example.com',
        );
        fakeSupabase.addTableData(DatabaseConstants.costEstimatesTable, [
          EstimationTestDataMapFactory.createFakeEstimationData(
            id: testEstimationId,
            estimateName: 'Kitchen',
            totalCost: 1,
          ),
        ]);
        fakeSupabase.addTableData(DatabaseConstants.costItemsTable, [
          {'estimate_id': testEstimationId, 'item_total_cost': 100},
        ]);
        await pumpAppAtRoute(tester, testEstimationRoute);
        await tester.tap(find.text(l10n.equipmentsTab));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('add_equipment_cost_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('new_equipment_cost_row')));
        await tester.pumpAndSettle();
        await fillValidDayForm(tester);

        expect(find.text('Kitchen'), findsOneWidget);
        expect(find.text(r' total  $100.00 →'), findsOneWidget);

        await tester.tap(addButton());
        await tester.pumpAndSettle();

        expect(find.text('Added to Kitchen'), findsOneWidget);
      });
      testWidgets('a delivery fee above the largest keeps Add on', (
        tester,
      ) async {
        await openEquipmentSheet(tester);
        await fillValidDayForm(tester);
        await tester.ensureVisible(find.byKey(const Key('delivery_fee_row')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('delivery_fee_row')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('delivery_fee_field')),
          '1000000',
        );
        await tester.pumpAndSettle();

        expect(find.text('Fix the delivery fee to continue'), findsNothing);
        expect(find.text('Add to estimate'), findsOneWidget);
      });

      testWidgets('dismissing the sheet after a failed save does not repeat '
          'the error', (tester) async {
        await openEquipmentSheet(tester);
        await fillValidDayForm(tester);
        fakeSupabase.shouldThrowOnInsert = true;
        fakeSupabase.insertExceptionType = SupabaseExceptionType.socket;
        fakeSupabase.insertErrorMessage = 'Connection failed';
        await tester.tap(addButton());
        await tester.pumpAndSettle();
        expect(find.text(l10n.addToEstimateFailedError), findsOneWidget);
        await tester.tap(find.text(l10n.closeLabel));
        await tester.pumpAndSettle();
        expect(find.text(l10n.addToEstimateFailedError), findsNothing);

        await tester.tap(find.byKey(SheetHeader.backButtonKey));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ConfirmationDialog.secondaryButtonKey));
        await tester.pumpAndSettle();

        expect(find.byType(CostItemFormScreen), findsNothing);
        expect(find.text(l10n.addToEstimateFailedError), findsNothing);
      });
    });

    group('estimate summary load', () {
      Future<void> openNewEquipmentSheet(WidgetTester tester) async {
        await tester.tap(find.text(l10n.equipmentsTab));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('add_equipment_cost_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('new_equipment_cost_row')));
        await tester.pumpAndSettle();
      }

      testWidgets('opens the sheet when the estimate load failed', (
        tester,
      ) async {
        setUpAuthenticatedUser(
          credentialId: 'test-credential-id',
          email: 'test@example.com',
        );
        await pumpAppAtRoute(
          tester,
          testEstimationRoute,
          beforeNavigate: () {
            fakeSupabase.shouldThrowOnSelect = true;
            fakeSupabase.selectExceptionType = SupabaseExceptionType.socket;
          },
        );
        fakeSupabase.shouldThrowOnSelect = false;

        await openNewEquipmentSheet(tester);

        expect(find.byType(CostItemFormScreen), findsOneWidget);
      });

      testWidgets('opens the sheet while the estimate load never answers', (
        tester,
      ) async {
        setUpAuthenticatedUser(
          credentialId: 'test-credential-id',
          email: 'test@example.com',
        );
        await pumpAppAtRoute(
          tester,
          testEstimationRoute,
          beforeNavigate: () {
            fakeSupabase.shouldDelayOperations = true;
            fakeSupabase.completer = Completer();
          },
        );
        fakeSupabase.shouldDelayOperations = false;

        await openNewEquipmentSheet(tester);

        expect(find.byType(CostItemFormScreen), findsOneWidget);
      });
    });

    group('New material cost sheet', () {
      Future<void> openMaterialSheet(WidgetTester tester) async {
        setUpAuthenticatedUser(
          credentialId: 'test-credential-id',
          email: 'test@example.com',
        );
        seedEstimate();
        await pumpAppAtRoute(tester, testEstimationRoute);
        await tester.tap(find.byKey(const Key('add_material_cost_button')));
        await tester.pumpAndSettle();
      }

      Future<void> fillValidMaterialForm(WidgetTester tester) async {
        await tester.enterText(
          find.byKey(const Key('material_name_field')),
          'Interior paint',
        );
        await tester.enterText(
          find.byKey(const Key('material_quantity_field')),
          '3',
        );
        await tester.tap(find.byKey(const Key('material_unit_pill')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('unit_option_liters')));
        await tester.tap(find.byKey(const Key('unit_option_liters')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('material_rate_field')),
          '52',
        );
        await tester.pumpAndSettle();
      }

      Finder addButton() => find.byKey(AddToEstimateFooter.buttonKey);

      testWidgets('tapping Add material cost opens the sheet over the page', (
        tester,
      ) async {
        await openMaterialSheet(tester);

        expect(find.byType(CostItemFormScreen), findsOneWidget);
        expect(find.text('New material cost'), findsOneWidget);
        expect(find.text('Enter a material name to continue'), findsOneWidget);
      });

      testWidgets('opens the sheet even when the estimate cannot be loaded', (
        tester,
      ) async {
        setUpAuthenticatedUser(
          credentialId: 'test-credential-id',
          email: 'test@example.com',
        );
        await pumpAppAtRoute(tester, testEstimationRoute);

        await tester.tap(find.byKey(const Key('add_material_cost_button')));
        await tester.pumpAndSettle();

        expect(find.byType(CostItemFormScreen), findsOneWidget);
      });

      testWidgets('shows the estimate total before and after the line', (
        tester,
      ) async {
        await openMaterialSheet(tester);

        await fillValidMaterialForm(tester);

        expect(find.text(r'$156.00'), findsOneWidget);
        expect(find.text(r'$3,149.62'), findsOneWidget);
      });

      testWidgets('adding saves the line, closes the sheet and shows the '
          'toast', (tester) async {
        await openMaterialSheet(tester);
        await fillValidMaterialForm(tester);

        await tester.tap(addButton());
        await tester.pumpAndSettle();

        expect(find.byType(CostItemFormScreen), findsNothing);
        expect(find.text('Added to Bedroom 2'), findsOneWidget);
        final saved =
            fakeSupabase
                    .getMethodCallsFor('insert')
                    .where(
                      (c) => c['table'] == DatabaseConstants.costItemsTable,
                    )
                    .single['data']
                as Map<String, dynamic>;
        expect(saved['estimate_id'], testEstimationId);
        expect(saved['item_name'], 'Interior paint');
        expect(saved['item_total_cost'], 156);
      });

      testWidgets('dismissing the sheet while saving still confirms the add', (
        tester,
      ) async {
        await openMaterialSheet(tester);
        await fillValidMaterialForm(tester);
        fakeSupabase.shouldDelayOperations = true;
        fakeSupabase.completer = Completer();

        await tester.tap(addButton());
        await tester.pump();
        await tester.tapAt(const Offset(200, 20));
        await tester.pumpAndSettle();
        expect(find.byType(CostItemFormScreen), findsNothing);
        expect(find.text('Added to Bedroom 2'), findsNothing);

        fakeSupabase.completer!.complete();
        fakeSupabase.shouldDelayOperations = false;
        await tester.pumpAndSettle();

        expect(find.text('Added to Bedroom 2'), findsOneWidget);
      });

      testWidgets('a save that fails after the sheet was dismissed still shows '
          'the error', (tester) async {
        await openMaterialSheet(tester);
        await fillValidMaterialForm(tester);
        fakeSupabase.shouldDelayOperations = true;
        fakeSupabase.completer = Completer();
        fakeSupabase.shouldThrowOnInsert = true;
        fakeSupabase.insertExceptionType = SupabaseExceptionType.socket;
        fakeSupabase.insertErrorMessage = 'Connection failed';

        await tester.tap(addButton());
        await tester.pump();
        await tester.tapAt(const Offset(200, 20));
        await tester.pumpAndSettle();
        fakeSupabase.completer!.complete();
        fakeSupabase.shouldDelayOperations = false;
        await tester.pumpAndSettle();

        expect(find.text(l10n.addToEstimateFailedError), findsOneWidget);
        expect(find.text('Added to Bedroom 2'), findsNothing);
      });

      testWidgets('a swipe down on the form with a name typed asks to discard '
          'the line', (tester) async {
        await openMaterialSheet(tester);
        await tester.enterText(
          find.byKey(const Key('material_name_field')),
          'Interior paint',
        );

        await tester.fling(
          find.byKey(const Key('material_name_field')),
          const Offset(0, 300),
          1500,
        );
        await tester.pumpAndSettle();

        expect(find.text(l10n.discardLineDialogTitle), findsOneWidget);
        expect(find.byType(CostItemFormScreen), findsOneWidget);
      });

      testWidgets('a swipe down on the handle with a name typed asks to '
          'discard the line', (tester) async {
        await openMaterialSheet(tester);
        await tester.enterText(
          find.byKey(const Key('material_name_field')),
          'Interior paint',
        );

        await tester.fling(
          find.byKey(GuardedQuickSheet.handleKey),
          const Offset(0, 300),
          1500,
        );
        await tester.pumpAndSettle();

        expect(find.text(l10n.discardLineDialogTitle), findsOneWidget);
        expect(find.byType(CostItemFormScreen), findsOneWidget);
      });

      testWidgets('a swipe down on the handle closes the sheet when nothing '
          'was typed', (tester) async {
        await openMaterialSheet(tester);

        await tester.fling(
          find.byKey(GuardedQuickSheet.handleKey),
          const Offset(0, 300),
          1500,
        );
        await tester.pumpAndSettle();

        expect(find.byType(CostItemFormScreen), findsNothing);
      });

      testWidgets('closing the sheet without adding shows no toast', (
        tester,
      ) async {
        await openMaterialSheet(tester);
        await tester.tap(find.byKey(SheetHeader.backButtonKey));
        await tester.pumpAndSettle();

        expect(find.byType(CostItemFormScreen), findsNothing);
        expect(find.textContaining('Added to'), findsNothing);
        expect(fakeSupabase.getMethodCallsFor('insert'), isEmpty);
      });

      testWidgets('keeps the sheet open with its values and shows an error '
          'when the save fails, then adds on a second try', (tester) async {
        await openMaterialSheet(tester);
        await fillValidMaterialForm(tester);
        fakeSupabase.shouldThrowOnInsert = true;
        fakeSupabase.insertExceptionType = SupabaseExceptionType.socket;
        fakeSupabase.insertErrorMessage = 'Connection failed';

        await tester.tap(addButton());
        await tester.pumpAndSettle();

        expect(find.byType(CostItemFormScreen), findsOneWidget);
        expect(find.text('Interior paint'), findsOneWidget);
        expect(find.text(l10n.addToEstimateFailedError), findsOneWidget);
        expect(find.text('Added to Bedroom 2'), findsNothing);

        fakeSupabase.shouldThrowOnInsert = false;
        await tester.tap(addButton());
        await tester.pumpAndSettle();

        expect(find.byType(CostItemFormScreen), findsNothing);
        expect(find.text('Added to Bedroom 2'), findsOneWidget);
      });

      String? highlightedLine(WidgetTester tester) =>
          BlocProvider.of<AddedLineHighlightCubit>(
            tester.element(find.byType(Scaffold).first),
          ).state;

      testWidgets('marks the line just added', (tester) async {
        await openMaterialSheet(tester);
        expect(highlightedLine(tester), isNull);
        await fillValidMaterialForm(tester);

        await tester.tap(addButton());
        await tester.pumpAndSettle();

        expect(highlightedLine(tester), isNotNull);
      });

      testWidgets('moves the mark to the next line added, even for the same '
          'material', (tester) async {
        await openMaterialSheet(tester);
        await fillValidMaterialForm(tester);
        await tester.tap(addButton());
        await tester.pumpAndSettle();
        final first = highlightedLine(tester);

        await tester.tap(find.byKey(const Key('add_material_cost_button')));
        await tester.pumpAndSettle();
        await fillValidMaterialForm(tester);
        await tester.tap(addButton());
        await tester.pumpAndSettle();

        expect(highlightedLine(tester), isNotNull);
        expect(highlightedLine(tester), isNot(first));
        expect(
          fakeSupabase
              .getMethodCallsFor('insert')
              .where((c) => c['table'] == DatabaseConstants.costItemsTable),
          hasLength(2),
        );
      });

      testWidgets('marks nothing when the save fails or the sheet is just '
          'closed', (tester) async {
        await openMaterialSheet(tester);
        await fillValidMaterialForm(tester);
        fakeSupabase.shouldThrowOnInsert = true;
        fakeSupabase.insertExceptionType = SupabaseExceptionType.socket;
        fakeSupabase.insertErrorMessage = 'Connection failed';
        await tester.tap(addButton());
        await tester.pumpAndSettle();
        expect(highlightedLine(tester), isNull);

        fakeSupabase.shouldThrowOnInsert = false;
        await tester.tap(find.byKey(SheetHeader.backButtonKey));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ConfirmationDialog.secondaryButtonKey));
        await tester.pumpAndSettle();

        expect(highlightedLine(tester), isNull);
      });

      testWidgets('is not brought back when the screen is opened again', (
        tester,
      ) async {
        await openMaterialSheet(tester);
        await fillValidMaterialForm(tester);
        await tester.tap(addButton());
        await tester.pumpAndSettle();
        expect(highlightedLine(tester), isNotNull);

        await tester.pumpWidget(const SizedBox());
        await pumpAppAtRoute(tester, testEstimationRoute);

        expect(highlightedLine(tester), isNull);
      });

      testWidgets('discarding after a failed save leaves no error behind'
          ' on the page', (tester) async {
        await openMaterialSheet(tester);
        await fillValidMaterialForm(tester);
        fakeSupabase.shouldThrowOnInsert = true;
        fakeSupabase.insertExceptionType = SupabaseExceptionType.socket;
        fakeSupabase.insertErrorMessage = 'Connection failed';
        await tester.tap(addButton());
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byKey(AddToEstimateFooter.errorKey),
            matching: find.text(l10n.addToEstimateFailedError),
          ),
          findsOneWidget,
        );

        await tester.tap(find.byKey(SheetHeader.backButtonKey));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ConfirmationDialog.secondaryButtonKey));
        await tester.pumpAndSettle();

        expect(find.byType(CostItemFormScreen), findsNothing);
        expect(find.text(l10n.addToEstimateFailedError), findsNothing);
      });

      testWidgets('a second tap on Add while saving does not save twice', (
        tester,
      ) async {
        await openMaterialSheet(tester);
        await fillValidMaterialForm(tester);
        fakeSupabase.shouldDelayOperations = true;
        fakeSupabase.completer = Completer();

        await tester.tap(addButton());
        await tester.pump();
        await tester.tap(addButton(), warnIfMissed: false);
        await tester.pump();
        fakeSupabase.completer!.complete();
        fakeSupabase.shouldDelayOperations = false;
        await tester.pumpAndSettle();

        expect(
          fakeSupabase
              .getMethodCallsFor('insert')
              .where((c) => c['table'] == DatabaseConstants.costItemsTable),
          hasLength(1),
        );
      });
    });
  });
}
