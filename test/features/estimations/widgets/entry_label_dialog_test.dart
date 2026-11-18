import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/entry_label_dialog.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/company/domain/current_company_resolver.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
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

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late FakeYourRatesDatabase database;
  late FakeClockImpl clock;
  late AppLocalizations l10n;

  final title = find.byKey(const Key('entry_label_dialog_title'));
  final field = find.byKey(const Key('entry_label_field'));
  final save = find.byKey(const Key('entry_label_dialog_save_button'));

  setUpAll(() async {
    clock = FakeClockImpl(DateTime(2026, 1, 15));
    database = FakeYourRatesDatabase();
    fakeSupabase = FakeSupabaseWrapper(clock: clock);
    Modular.init(
      EstimationModule(
        FakeAppBootstrapFactory.create(supabaseWrapper: fakeSupabase),
      ),
    );
    Modular.replaceInstance<PowerSyncDatabaseWrapper>(database);
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  tearDownAll(Modular.dispose);

  setUp(() {
    database.reset();
    Modular.get<CurrentCompanyResolver>().clearCache();
    fakeSupabase.setRpcResponse(
      DatabaseConstants.getMyCompanyIdRpcFunction,
      'company-1',
    );
    database.seedRow({
      'id': 'lift-a',
      'company_id': 'company-1',
      'category': 'equipment',
      'item_name': 'Scissor lift',
      'rate_amount': 120.0,
      'rate_currency': 'USD',
      'equipment_method': 'day',
      'entry_label': 'Supplier A',
      'saved_at': '2026-01-01T00:00:00.000Z',
    });
  });

  tearDown(() {
    fakeSupabase.reset();
    database.reset();
  });

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                key: const Key('open_dialog'),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => BlocProvider<YourRatesBloc>(
                    create: (_) => Modular.get<YourRatesBloc>(),
                    child: EntryLabelDialog(
                      entry: YourRateEntry(
                        id: '',
                        companyId: '',
                        itemName: 'Scissor lift',
                        category: CostItemType.equipment,
                        rate: const Money(amount: 135),
                        savedAt: clock.now(),
                        equipmentMethod: EquipmentPricingMethod.day,
                      ),
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open_dialog')));
    await tester.pumpAndSettle();
  }

  testWidgets('saves the rate under the typed label and closes', (
    tester,
  ) async {
    await openDialog(tester);

    await tester.enterText(field, 'Supplier B');
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(title, findsNothing);
    expect(database.insertedRows.single['entry_label'], 'Supplier B');
  });

  testWidgets('asks for a label when none is typed, and stays open', (
    tester,
  ) async {
    await openDialog(tester);

    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.text(l10n.yourRatesEntryLabelRequiredError), findsOneWidget);
    expect(title, findsOneWidget);
    expect(database.insertedRows, isEmpty);
  });

  testWidgets('says a label already used for the name is taken, and stays '
      'open', (tester) async {
    await openDialog(tester);

    await tester.enterText(field, 'supplier a');
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.text(l10n.yourRatesEntryLabelTakenError), findsOneWidget);
    expect(title, findsOneWidget);
  });

  testWidgets('closes without saving on Cancel', (tester) async {
    await openDialog(tester);

    await tester.enterText(field, 'Supplier B');
    await tester.tap(find.byKey(const Key('entry_label_dialog_cancel_button')));
    await tester.pumpAndSettle();

    expect(title, findsNothing);
    expect(database.insertedRows, isEmpty);
  });

  testWidgets('closes when the save fails, leaving the error to the form', (
    tester,
  ) async {
    await openDialog(tester);
    database.executeError = StateError('disk full');

    await tester.enterText(field, 'Supplier B');
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(title, findsNothing);
  });
}
