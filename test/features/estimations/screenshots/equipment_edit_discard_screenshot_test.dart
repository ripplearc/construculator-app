import 'package:construculator/features/estimation/data/models/cost_item_dto.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/equipment_cost_form_bloc/equipment_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_item_form_screen.dart';
import 'package:construculator/features/estimation/presentation/widgets/confirmation_dialog.dart';
import 'package:construculator/features/estimation/presentation/widgets/guarded_quick_sheet.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_header.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/company/domain/current_company_resolver.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';
import '../../../utils/fake_your_rates_database.dart';
import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(412, 917);
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseWrapper fakeSupabase;

  setUpAll(() {
    fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
    Modular.init(
      EstimationModule(
        FakeAppBootstrapFactory.create(supabaseWrapper: fakeSupabase),
      ),
    );
    Modular.replaceInstance<PowerSyncDatabaseWrapper>(FakeYourRatesDatabase());
  });

  tearDownAll(Modular.dispose);

  setUp(() async {
    Modular.get<CurrentCompanyResolver>().clearCache();
    fakeSupabase.reset();
    fakeSupabase.setRpcResponse(
      DatabaseConstants.getMyCompanyIdRpcFunction,
      'company-1',
    );
    await loadAppFontsAll();
  });

  final scissorLift = EquipmentCostItem(
    id: 'item-1',
    estimateId: 'estimate-1',
    itemName: 'Scissor lift',
    calculation: const {'daily_rate': 200.0, 'duration': 3.0},
    itemTotalCost: 685.0,
    createdAt: DateTime.utc(2024),
    updatedAt: DateTime.utc(2024),
    currency: 'USD',
    pricingMethod: EquipmentPricingMethod.day,
    rateStatus: RateStatus.ownRateConfirmed,
    duration: 3.0,
    dailyRate: const Money(amount: 200.0),
    deliveryFee: const Money(amount: 85.0),
  );

  Future<void> askToDiscard(WidgetTester tester, ThemeData theme) async {
    fakeSupabase.addTableData(DatabaseConstants.costItemsTable, [
      CostItemDto.fromEntity(scissorLift).toJson(),
    ]);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final sheetBloc = Modular.get<EquipmentCostFormBloc>();
    addTearDown(sheetBloc.close);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key('open_sheet'),
              onPressed: () => GuardedQuickSheet.show<void>(
                context: context,
                backgroundColor: theme.coreColors.pageBackground,
                child: BlocProvider<EquipmentCostFormBloc>.value(
                  value: sheetBloc,
                  child: CostItemFormScreen(
                    type: CostItemType.equipment,
                    estimationId: 'estimate-1',
                    router: FakeAppRouter(),
                    yourRatesBlocFactory: () => Modular.get<YourRatesBloc>(),
                    clock: FakeClockImpl(),
                    presentAsSheet: true,
                    editedEquipmentItem: scissorLift,
                    estimate: CostEstimate.defaultEstimate(
                      estimateName: 'Bedroom 2',
                      totalCost: 2993.62,
                    ),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open_sheet')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('duration_field')), '4');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SheetHeader.backButtonKey));
    await tester.pumpAndSettle();
  }

  screenshotThemeGroups('Equipment edit discard Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('Discard changes? over the edit sheet', (tester) async {
      await askToDiscard(tester, theme);

      expect(find.byKey(ConfirmationDialog.titleKey), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/equipment_edit_discard/discard_changes$suffix.png',
        ),
      );
    });
  });
}
