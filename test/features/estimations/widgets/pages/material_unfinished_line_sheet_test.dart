import 'package:construculator/features/estimation/data/repositories/unfinished_cost_line_repository_impl.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/unfinished_cost_line_repository.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_item_form_screen.dart';
import 'package:construculator/features/estimation/presentation/widgets/confirmation_dialog.dart';
import 'package:construculator/features/estimation/presentation/widgets/guarded_quick_sheet.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_header.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/storage/interfaces/storage_service.dart';
import 'package:construculator/libraries/storage/testing/fake_storage_service.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  late FakeStorageService storage;
  late FakeAuthRepository auth;
  late UnfinishedCostLineRepository unfinishedLines;
  final l10n = lookupAppLocalizations(const Locale('en'));

  setUp(() {
    final clock = FakeClockImpl();
    storage = FakeStorageService();
    auth = FakeAuthRepository(clock: clock)
      ..setCurrentCredentials(
        UserCredential(
          id: 'account-1',
          email: 'a@example.com',
          metadata: const {},
          createdAt: DateTime(2026),
        ),
      );
    Modular.init(
      EstimationModule(
        FakeAppBootstrapFactory.create(
          supabaseWrapper: FakeSupabaseWrapper(clock: clock),
        ),
      ),
    );
    addTearDown(Modular.destroy);
    Modular.replaceInstance<StorageService>(storage);
    Modular.replaceInstance<AuthRepository>(auth);
  });

  Future<void> openSheetAndType(WidgetTester tester) async {
    unfinishedLines = UnfinishedCostLineRepositoryImpl(
      storage: storage,
      authRepository: auth,
      clock: FakeClockImpl(DateTime(2026, 11, 19)),
    );
    Modular.replaceInstance<UnfinishedCostLineRepository>(unfinishedLines);
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final bloc = Modular.get<MaterialCostFormBloc>()
      ..add(const MaterialCostFormStarted(estimateId: 'estimate-1'));
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key('open_sheet'),
              onPressed: () => GuardedQuickSheet.show<void>(
                context: context,
                backgroundColor: CoreTheme.light().coreColors.pageBackground,
                child: BlocProvider<MaterialCostFormBloc>.value(
                  value: bloc,
                  child: CostItemFormScreen(
                    type: CostItemType.material,
                    estimationId: 'estimate-1',
                    router: FakeAppRouter(),
                    yourRatesBlocFactory: () => Modular.get<YourRatesBloc>(),
                    clock: FakeClockImpl(),
                    presentAsSheet: true,
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
    await tester.enterText(
      find.byKey(const Key('material_name_field')),
      'Interior paint',
    );
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SheetHeader.backButtonKey));
    await tester.pumpAndSettle();
  }

  Future<String?> unfinishedName(WidgetTester tester) async =>
      (await unfinishedLines.read())?.itemName;

  group('the unfinished line behind "Discard this line?"', () {
    testWidgets('is kept while the question is open', (tester) async {
      await openSheetAndType(tester);

      expect(find.text(l10n.discardLineDialogTitle), findsOneWidget);
      expect(await unfinishedName(tester), 'Interior paint');
    });

    testWidgets('is removed by Discard', (tester) async {
      await openSheetAndType(tester);

      await tester.tap(find.byKey(ConfirmationDialog.secondaryButtonKey));
      await tester.pumpAndSettle();

      expect(find.text(l10n.newMaterialCostSheetTitle), findsNothing);
      expect(await unfinishedName(tester), isNull);
    });

    testWidgets('is kept by Keep editing', (tester) async {
      await openSheetAndType(tester);

      await tester.tap(find.byKey(ConfirmationDialog.primaryButtonKey));
      await tester.pumpAndSettle();

      expect(find.text(l10n.discardLineDialogTitle), findsNothing);
      expect(await unfinishedName(tester), 'Interior paint');
    });

    testWidgets('is kept by a tap outside the question', (tester) async {
      await openSheetAndType(tester);

      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();

      expect(find.text(l10n.discardLineDialogTitle), findsNothing);
      expect(find.text(l10n.newMaterialCostSheetTitle), findsOneWidget);
      expect(await unfinishedName(tester), 'Interior paint');
    });

    testWidgets('is kept by the back gesture', (tester) async {
      await openSheetAndType(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text(l10n.discardLineDialogTitle), findsNothing);
      expect(find.text(l10n.newMaterialCostSheetTitle), findsOneWidget);
      expect(await unfinishedName(tester), 'Interior paint');
    });
  });
}
