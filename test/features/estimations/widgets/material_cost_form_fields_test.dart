import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/last_used_unit_repository.dart';
import 'package:construculator/features/estimation/domain/repositories/your_rates_repository.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/helpers/sample_rate_row.dart';
import 'package:construculator/features/estimation/presentation/widgets/material_cost_form_fields.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_field_row.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/company/domain/current_company_resolver.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/storage/interfaces/storage_service.dart';
import 'package:construculator/libraries/storage/testing/fake_storage_service.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';
import '../../../utils/fake_your_rates_database.dart';
import '../../../utils/your_rates_bloc_without_debounce.dart';

void main() {
  late FakeStorageService storage;
  late FakeAuthRepository auth;
  late LastUsedUnitRepository lastUsedUnits;
  late MaterialCostFormBloc bloc;
  late FakeSupabaseWrapper fakeSupabase;
  late FakeYourRatesDatabase database;

  final nameField = find.byKey(const Key('material_name_field'));
  final quantityField = find.byKey(const Key('material_quantity_field'));
  final rateField = find.byKey(const Key('material_rate_field'));
  final unitPill = find.byKey(const Key('material_unit_pill'));

  setUpAll(() {
    final clock = FakeClockImpl();
    storage = FakeStorageService();
    auth = FakeAuthRepository(clock: clock);
    fakeSupabase = FakeSupabaseWrapper(clock: clock);
    database = FakeYourRatesDatabase();
    Modular.init(
      EstimationModule(
        FakeAppBootstrapFactory.create(supabaseWrapper: fakeSupabase),
      ),
    );
    Modular.replaceInstance<StorageService>(storage);
    Modular.replaceInstance<AuthRepository>(auth);
    Modular.replaceInstance<PowerSyncDatabaseWrapper>(database);
    lastUsedUnits = Modular.get<LastUsedUnitRepository>();
  });

  tearDownAll(Modular.dispose);

  setUp(() {
    storage.reset();
    auth.reset();
    database.reset();
    Modular.get<CurrentCompanyResolver>().clearCache();
    fakeSupabase.setRpcResponse(
      DatabaseConstants.getMyCompanyIdRpcFunction,
      'company-1',
    );
    auth.setCurrentCredentials(
      UserCredential(
        id: 'account-1',
        email: 'a@example.com',
        metadata: const {},
        createdAt: DateTime(2026),
      ),
    );
  });

  Future<void> pumpFields(
    WidgetTester tester, {
    YourRateEntry? initialRateEntry,
    String? initialName,
    List<SampleRateRow> sampleRows = const [],
  }) async {
    bloc = Modular.get<MaterialCostFormBloc>();
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<MaterialCostFormBloc>.value(
            value: bloc,
            child: MaterialCostFormFields(
              initialRateEntry: initialRateEntry,
              initialName: initialName,
              yourRatesBlocFactory: yourRatesBlocWithoutDebounce,
              clock: FakeClockImpl(),
              sampleRatesFor: (_) => sampleRows,
            ),
          ),
        ),
      ),
    );
  }

  String textOf(WidgetTester tester, Finder field) => tester
      .widget<TextField>(
        find.descendant(of: field, matching: find.byType(TextField)),
      )
      .controller!
      .text;

  MaterialCostFormData dataOf() => bloc.state.data;

  group('layout from Figma', () {
    Size rowSize(WidgetTester tester, String label) => tester.getSize(
      find.ancestor(of: find.text(label), matching: find.byType(SheetFieldRow)),
    );

    testWidgets('the name row is 67 dp tall with its divider', (tester) async {
      await pumpFields(tester);

      expect(rowSize(tester, 'Material').height, 66 + 1);
    });

    testWidgets('the quantity row is 74 dp tall as in the storyboard, so the '
        '48 dp tap area of the unit button does not stretch it', (
      tester,
    ) async {
      await pumpFields(tester);

      expect(rowSize(tester, 'Quantity').height, 73 + 1);
    });

    testWidgets('the unit button is drawn 32 dp tall', (tester) async {
      await pumpFields(tester);

      final drawn = find.descendant(
        of: unitPill,
        matching: find.byType(DecoratedBox),
      );
      expect(tester.getSize(drawn.first).height, 32);
    });

    testWidgets('the unit button follows a short quantity at 8 dp', (
      tester,
    ) async {
      await pumpFields(tester);
      await tester.enterText(quantityField, '7');
      await tester.pump();

      final field = tester.getRect(quantityField);
      expect(field.width, lessThan(20));
      expect(tester.getRect(unitPill).left - field.right, 8);
    });

    testWidgets('the unit after the rate follows the typed rate at 4 dp', (
      tester,
    ) async {
      await pumpFields(tester);
      await tester.enterText(rateField, '52');
      bloc.add(const MaterialUnitSelected(Unit.liters));
      await tester.pump();

      final field = tester.getRect(rateField);
      expect(field.width, lessThan(50));
      expect(tester.getRect(find.text('/Liters')).left - field.right, 4);
    });

    testWidgets('the name row leaves 4 dp between its label and value', (
      tester,
    ) async {
      await pumpFields(tester);

      final label = tester.getRect(find.text('Material'));
      final value = tester.getRect(find.text('Name the material'));
      expect(value.top - label.bottom, 4);
    });

    testWidgets('the rate row leaves 8 dp between its label and value', (
      tester,
    ) async {
      await pumpFields(tester);

      final label = tester.getRect(find.text('Rate'));
      final value = tester.getRect(find.text('Set your rate'));
      expect(value.top - label.bottom, 8);
    });
  });

  group('tap areas', () {
    bool hasFocus(WidgetTester tester, Finder field) => tester
        .widget<TextField>(
          find.descendant(of: field, matching: find.byType(TextField)),
        )
        .focusNode!
        .hasFocus;

    for (final entry in {
      'Material': nameField,
      'Quantity': quantityField,
      'Rate': rateField,
    }.entries) {
      testWidgets('tapping the ${entry.key} label focuses its field', (
        tester,
      ) async {
        await pumpFields(tester);

        await tester.tap(find.text(entry.key));
        await tester.pump();

        expect(hasFocus(tester, entry.value), isTrue);
      });

      testWidgets('tapping above the ${entry.key} text, outside the 24 dp '
          'the text takes, focuses its field', (tester) async {
        await pumpFields(tester);
        final text = tester.getRect(entry.value);

        await tester.tapAt(Offset(text.left + 4, text.top - 10));
        await tester.pump();

        expect(hasFocus(tester, entry.value), isTrue);
      });
    }

    testWidgets('the unit button opens its list from its own area', (
      tester,
    ) async {
      await pumpFields(tester);
      final centre = tester.getCenter(unitPill);

      await tester.tapAt(centre + const Offset(0, 14));
      await tester.pumpAndSettle();

      expect(find.text('Select unit'), findsOneWidget);
    });

    testWidgets('the unit button is laid out 32 dp tall and reports a 48 dp '
        'tap area', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpFields(tester);

      expect(tester.getRect(unitPill).height, 32);
      expect(
        tester
            .getSemantics(
              find.descendant(
                of: unitPill,
                matching: find.byType(GestureDetector),
              ),
            )
            .rect
            .height,
        48,
      );
      handle.dispose();
    });
  });

  group('rate unit', () {
    testWidgets('shows the unit after a typed rate', (tester) async {
      await pumpFields(tester);
      await tester.enterText(rateField, '52');
      bloc.add(const MaterialUnitSelected(Unit.liters));
      await tester.pump();

      expect(find.text('/Liters'), findsOneWidget);
    });

    testWidgets('writes the unit with no space after the slash, in smaller '
        'text than the rate', (tester) async {
      await pumpFields(tester);
      await tester.enterText(rateField, '52');
      bloc.add(const MaterialUnitSelected(Unit.liters));
      await tester.pump();

      final unit = tester.widget<Text>(find.text('/Liters'));
      final rate = tester.widget<TextField>(
        find.descendant(of: rateField, matching: find.byType(TextField)),
      );
      expect(unit.style!.fontSize, lessThan(rate.style!.fontSize!));
    });

    testWidgets('shortens a long unit with an ellipsis so the search button '
        'still fits on a 360 dp phone', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpFields(tester);
      bloc.add(const MaterialUnitSelected(Unit.squareMeters));
      await tester.pumpAndSettle();

      final unit = find.text('/Square meters');
      expect(tester.takeException(), isNull);
      expect(
        tester.renderObject<RenderParagraph>(unit).didExceedMaxLines,
        isTrue,
      );
      expect(
        tester.getRect(find.byKey(const Key('lookup_rate_button'))).right,
        lessThanOrEqualTo(360),
      );
    });

    testWidgets('shows the unit even before a rate is typed', (tester) async {
      await pumpFields(tester);
      bloc.add(const MaterialUnitSelected(Unit.liters));
      await tester.pump();

      expect(find.text('/Liters'), findsOneWidget);
    });

    testWidgets('shows no unit after the rate while none is picked', (
      tester,
    ) async {
      await pumpFields(tester);
      await tester.enterText(rateField, '52');
      await tester.pump();

      expect(find.textContaining('/ '), findsNothing);
    });
  });

  group('empty form', () {
    testWidgets('shows the three labels and their placeholders', (
      tester,
    ) async {
      await pumpFields(tester);

      for (final text in [
        'Material',
        'Quantity',
        'Rate',
        'Name the material',
        '0',
        'Set your rate',
        'Unit',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
    });
  });

  group('material name', () {
    testWidgets('sends what is typed to the form', (tester) async {
      await pumpFields(tester);

      await tester.enterText(nameField, 'Interior paint');
      await tester.pump();

      expect(dataOf().itemName, 'Interior paint');
    });

    testWidgets('stops typing at 80 characters, with no message', (
      tester,
    ) async {
      await pumpFields(tester);

      await tester.enterText(nameField, 'a' * 100);
      await tester.pump();

      expect(textOf(tester, nameField).length, 80);
      expect(dataOf().itemName.length, 80);
      expect(find.textContaining('80'), findsNothing);
    });
  });

  group('quantity', () {
    testWidgets('sends a typed quantity to the form', (tester) async {
      await pumpFields(tester);

      await tester.enterText(quantityField, '2.5');
      await tester.pump();

      expect(dataOf().quantity, 2.5);
    });

    testWidgets('ignores a second decimal point', (tester) async {
      await pumpFields(tester);

      await tester.enterText(quantityField, '1.2');
      await tester.enterText(quantityField, '1.2.3');
      await tester.pump();

      expect(textOf(tester, quantityField), '1.2');
    });

    testWidgets('stops at nine whole digits, so the row cannot outgrow the '
        'screen', (tester) async {
      await pumpFields(tester);

      await tester.enterText(quantityField, '123456789');
      await tester.enterText(quantityField, '1234567890');
      await tester.pump();

      expect(textOf(tester, quantityField), '123456789');
      expect(tester.takeException(), isNull);
    });

    testWidgets('ignores a fifth decimal digit', (tester) async {
      await pumpFields(tester);

      await tester.enterText(quantityField, '1.2345');
      await tester.enterText(quantityField, '1.23456');
      await tester.pump();

      expect(textOf(tester, quantityField), '1.2345');
    });

    testWidgets('reads a comma as the decimal point', (tester) async {
      await pumpFields(tester);

      await tester.enterText(quantityField, '2,5');
      await tester.pump();

      expect(textOf(tester, quantityField), '2.5');
      expect(dataOf().quantity, 2.5);
    });

    testWidgets('ignores a second decimal separator, comma or point', (
      tester,
    ) async {
      await pumpFields(tester);

      await tester.enterText(quantityField, '2,5');
      await tester.enterText(quantityField, '2,5,1');
      await tester.enterText(quantityField, '2,5.1');
      await tester.pump();

      expect(textOf(tester, quantityField), '2.5');
    });

    testWidgets('ignores letters and signs', (tester) async {
      await pumpFields(tester);

      await tester.enterText(quantityField, '3');
      await tester.enterText(quantityField, '3x');
      await tester.enterText(quantityField, '-3');
      await tester.pump();

      expect(textOf(tester, quantityField), '3');
    });

    testWidgets('keeps a typed zero so the form can flag it', (tester) async {
      await pumpFields(tester);

      await tester.enterText(quantityField, '0');
      await tester.pump();

      expect(textOf(tester, quantityField), '0');
      expect(
        dataOf().fieldErrors[MaterialFormField.quantity],
        MaterialFieldError.quantityNotPositive,
      );
    });
  });

  group('rate', () {
    testWidgets('sends a typed rate to the form', (tester) async {
      await pumpFields(tester);

      await tester.enterText(rateField, '52.5');
      await tester.pump();

      expect(dataOf().rate, 52.5);
    });

    testWidgets('reads a comma as the decimal point', (tester) async {
      await pumpFields(tester);

      await tester.enterText(rateField, '52,5');
      await tester.pump();

      expect(textOf(tester, rateField), '52.5');
      expect(dataOf().rate, 52.5);
    });

    testWidgets('stops at nine whole digits', (tester) async {
      await pumpFields(tester);

      await tester.enterText(rateField, '123456789');
      await tester.enterText(rateField, '1234567890');
      await tester.pump();

      expect(textOf(tester, rateField), '123456789');
    });

    testWidgets('ignores a third decimal digit', (tester) async {
      await pumpFields(tester);

      await tester.enterText(rateField, '52.50');
      await tester.enterText(rateField, '52.505');
      await tester.pump();

      expect(textOf(tester, rateField), '52.50');
    });
  });

  group('unit', () {
    testWidgets('starts empty when no unit was used before', (tester) async {
      await pumpFields(tester);
      bloc.add(const MaterialCostFormStarted());
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: unitPill, matching: find.text('Unit')),
        findsOneWidget,
      );
    });

    testWidgets('starts on the unit this account used last', (tester) async {
      await lastUsedUnits.saveLastUnit(CostItemType.material, Unit.bags);
      await pumpFields(tester);
      bloc.add(const MaterialCostFormStarted());
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: unitPill, matching: find.text('Bags')),
        findsOneWidget,
      );
      expect(dataOf().unit, Unit.bags);
    });

    testWidgets('changes when another unit is picked from the list', (
      tester,
    ) async {
      await pumpFields(tester);

      await tester.tap(unitPill);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('unit_option_liters')));
      await tester.tap(find.byKey(const Key('unit_option_liters')));
      await tester.pumpAndSettle();

      expect(dataOf().unit, Unit.liters);
      expect(
        find.descendant(of: unitPill, matching: find.text('Liters')),
        findsOneWidget,
      );
    });

    testWidgets('does not change the typed quantity when the unit changes', (
      tester,
    ) async {
      await pumpFields(tester);
      await tester.enterText(quantityField, '3');

      await tester.tap(unitPill);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('unit_option_bags')));
      await tester.tap(find.byKey(const Key('unit_option_bags')));
      await tester.pumpAndSettle();

      expect(textOf(tester, quantityField), '3');
      expect(dataOf().quantity, 3);
    });
  });

  group('opened from Your recents', () {
    final savedRate = YourRateEntry(
      id: 'paint-rate',
      companyId: 'company-1',
      itemName: 'Interior paint',
      category: CostItemType.material,
      rate: const Money(amount: 52),
      unit: Unit.liters,
      savedAt: DateTime.utc(2026, 1, 10),
    );

    testWidgets('a picked saved rate fills the name, rate and unit', (
      tester,
    ) async {
      await pumpFields(tester, initialRateEntry: savedRate);
      await tester.pumpAndSettle();

      expect(textOf(tester, nameField), 'Interior paint');
      expect(textOf(tester, rateField), '52');
      expect(textOf(tester, quantityField), isEmpty);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(
        find.descendant(of: unitPill, matching: find.text(l10n.unitLiters)),
        findsOneWidget,
      );
      expect(bloc.state.data.rateStatus, RateStatus.ownRateConfirmed);
      expect(bloc.state.data.hasUnsavedChanges, isFalse);
    });

    testWidgets('a rate with cents is put back as typed, not rounded', (
      tester,
    ) async {
      await pumpFields(
        tester,
        initialRateEntry: savedRate.copyWith(rate: const Money(amount: 9.5)),
      );
      await tester.pumpAndSettle();

      expect(textOf(tester, rateField), '9.5');
    });

    testWidgets('shows a picked rate as currency until the field is tapped', (
      tester,
    ) async {
      await pumpFields(tester, initialRateEntry: savedRate);
      await tester.pumpAndSettle();
      String shownRate() {
        final field = tester.widget<EditableText>(
          find.descendant(of: rateField, matching: find.byType(EditableText)),
        );
        return field.controller
            .buildTextSpan(
              context: tester.element(rateField),
              withComposing: false,
            )
            .toPlainText();
      }

      expect(shownRate(), r'$52.00');
      final currencyWidth = tester.getRect(rateField).width;

      await tester.tap(rateField);
      await tester.pumpAndSettle();

      expect(shownRate(), '52');
      // The field is as wide as what it shows, so the unit after it never
      // overlaps "$52.00".
      expect(tester.getRect(rateField).width, lessThan(currencyWidth));
    });

    testWidgets('a typed name fills the name and leaves the rate empty', (
      tester,
    ) async {
      await pumpFields(tester, initialName: 'primer');
      await tester.pumpAndSettle();

      expect(textOf(tester, nameField), 'primer');
      expect(textOf(tester, rateField), isEmpty);
      expect(bloc.state.data.itemName, 'primer');
    });
  });

  group('looking up a rate', () {
    final lookupButton = find.byKey(const Key('lookup_rate_button'));
    final hint = find.byKey(const Key('material_rate_lookup_hint'));

    setUp(() {
      database.seedRow({
        'id': 'paint-rate',
        'company_id': 'company-1',
        'category': 'material',
        'item_name': 'Interior paint ProClassic',
        'rate_amount': 52.0,
        'rate_currency': 'USD',
        'unit': 'liters',
        'saved_at': '2026-01-10T00:00:00.000Z',
      });
    });

    Future<void> pickFromLookup(WidgetTester tester) async {
      await tester.tap(lookupButton);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('your_rate_row_paint-rate')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('material_lookup_use_button')));
      await tester.pumpAndSettle();
    }

    testWidgets('an empty rate shows the search button and the hint under it', (
      tester,
    ) async {
      await pumpFields(tester);
      await tester.pumpAndSettle();

      expect(lookupButton, findsOneWidget);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(
        find.descendant(
          of: hint,
          matching: find.text(l10n.materialRateLookupHint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a typed rate removes the search button and the hint', (
      tester,
    ) async {
      await pumpFields(tester);
      await tester.enterText(rateField, '12');
      await tester.pumpAndSettle();

      expect(lookupButton, findsNothing);
      expect(hint, findsNothing);
    });

    testWidgets('the search button opens Look up a rate searched on the typed '
        'name', (tester) async {
      await pumpFields(tester);
      await tester.enterText(nameField, 'interior paint');

      await tester.tap(lookupButton);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('your_rates_search_field')),
          matching: find.text('interior paint'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('your_rate_row_paint-rate')), findsOneWidget);
    });

    testWidgets('a picked saved rate has no tag and no offer to save it', (
      tester,
    ) async {
      await pumpFields(tester);
      await tester.enterText(nameField, 'interior paint');

      await pickFromLookup(tester);

      expect(find.byKey(const Key('rate_status_badge')), findsNothing);
      expect(
        find.byKey(const Key('save_as_default_helper_text')),
        findsNothing,
      );
    });

    testWidgets('a picked rate fills the rate and unit, keeps the typed name '
        'and removes the search button', (tester) async {
      await pumpFields(tester);
      await tester.enterText(nameField, 'interior paint');

      await pickFromLookup(tester);

      expect(textOf(tester, nameField), 'interior paint');
      expect(textOf(tester, rateField), '52');
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(
        find.descendant(of: unitPill, matching: find.text(l10n.unitLiters)),
        findsOneWidget,
      );
      expect(lookupButton, findsNothing);
      expect(bloc.state.data.rateStatus, RateStatus.ownRateConfirmed);
    });

    testWidgets('a picked rate fills the name too while it is empty', (
      tester,
    ) async {
      await pumpFields(tester);

      await pickFromLookup(tester);

      expect(textOf(tester, nameField), 'Interior paint ProClassic');
    });

    testWidgets('closing Look up a rate without a pick changes nothing', (
      tester,
    ) async {
      await pumpFields(tester);
      await tester.tap(lookupButton);
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(textOf(tester, rateField), isEmpty);
      expect(lookupButton, findsOneWidget);
    });
  });

  group('picking a sample cost file rate', () {
    const proClassic = SampleRateRow(
      id: 'proclassic',
      productName: 'ProClassic',
      rate: Money(amount: 52),
      unit: Unit.liters,
    );

    Future<void> pickSample(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('lookup_rate_button')));
      await tester.pumpAndSettle();
      final row = find.byKey(const Key('sample_rate_row_proclassic'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('material_lookup_use_button')));
      await tester.pumpAndSettle();
    }

    testWidgets('appends the product to the typed name and fills the rate '
        'tagged Sample rate', (tester) async {
      await pumpFields(tester, sampleRows: const [proClassic]);
      await tester.enterText(nameField, 'Interior paint');

      await pickSample(tester);

      expect(textOf(tester, nameField), 'Interior paint · ProClassic');
      expect(textOf(tester, rateField), '52');
      expect(bloc.state.data.itemName, 'Interior paint · ProClassic');
      expect(bloc.state.data.rateStatus, RateStatus.sampleRateUnverified);
    });

    testWidgets('tags the rate Sample rate beside the Rate label, and says '
        'what saving it as the default does', (tester) async {
      await pumpFields(tester, sampleRows: const [proClassic]);
      await tester.enterText(nameField, 'Interior paint');
      await tester.enterText(quantityField, '2');
      await tester.tap(unitPill);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('unit_option_liters')));
      await tester.tap(find.byKey(const Key('unit_option_liters')));
      await tester.pumpAndSettle();

      await pickSample(tester);

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(
        find.descendant(
          of: find.byKey(const Key('rate_status_badge')),
          matching: find.text(l10n.materialSampleRateBadge),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('save_as_default_helper_text')),
          matching: find.text(
            l10n.materialSaveAsDefaultHelperText(
              r'$52.00 /Liters',
              l10n.yourRatesName,
              'interior paint',
            ),
            findRichText: true,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('draws "Your rates" in the save line in semibold', (
      tester,
    ) async {
      await pumpFields(tester, sampleRows: const [proClassic]);
      await tester.enterText(nameField, 'Interior paint');

      await pickSample(tester);

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final line = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('save_as_default_helper_text')),
          matching: find.byWidgetPredicate(
            (widget) => widget is Text && widget.textSpan != null,
          ),
        ),
      );
      final yourRates = (line.textSpan! as TextSpan).children!
          .whereType<TextSpan>()
          .singleWhere((span) => span.text == l10n.yourRatesName);
      expect(yourRates.style!.fontWeight, FontWeight.w600);
    });

    testWidgets('names the product in the save line when no name was typed', (
      tester,
    ) async {
      await pumpFields(tester, sampleRows: const [proClassic]);

      await pickSample(tester);

      expect(
        find.descendant(
          of: find.byKey(const Key('save_as_default_helper_text')),
          matching: find.textContaining(
            'next time you add proclassic.',
            findRichText: true,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('typing over the sample price removes the tag and keeps the '
        'offer to save the typed price', (tester) async {
      await pumpFields(tester, sampleRows: const [proClassic]);
      await pickSample(tester);

      await tester.enterText(rateField, '60');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('rate_status_badge')), findsNothing);
      expect(
        find.byKey(const Key('save_as_default_helper_text')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('save_as_default_helper_text')),
          matching: find.textContaining(r'$60.00', findRichText: true),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the save line follows every edit of the price and name', (
      tester,
    ) async {
      await pumpFields(tester, sampleRows: const [proClassic]);
      await pickSample(tester);

      await tester.enterText(rateField, '60');
      await tester.pumpAndSettle();
      await tester.enterText(rateField, '65');
      await tester.enterText(nameField, 'Primer');
      await tester.pumpAndSettle();

      final helper = find.byKey(const Key('save_as_default_helper_text'));
      expect(
        find.descendant(
          of: helper,
          matching: find.textContaining(r'$65.00', findRichText: true),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: helper,
          matching: find.textContaining('primer', findRichText: true),
        ),
        findsOneWidget,
      );
    });

    testWidgets('uses the product alone as the name while none is typed', (
      tester,
    ) async {
      await pumpFields(tester, sampleRows: const [proClassic]);

      await pickSample(tester);

      expect(textOf(tester, nameField), 'ProClassic');
    });
  });

  group('Save as my default', () {
    const proClassic = SampleRateRow(
      id: 'proclassic',
      productName: 'ProClassic',
      rate: Money(amount: 52),
      unit: Unit.liters,
    );
    final link = find.byKey(const Key('save_as_default_link'));
    final badge = find.byKey(const Key('rate_status_badge'));

    Future<void> openVerify(WidgetTester tester) async {
      await pumpFields(tester, sampleRows: const [proClassic]);
      await tester.enterText(nameField, 'Interior paint');
      await tester.tap(find.byKey(const Key('lookup_rate_button')));
      await tester.pumpAndSettle();
      final row = find.byKey(const Key('sample_rate_row_proclassic'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('material_lookup_use_button')));
      await tester.pumpAndSettle();
    }

    Future<List<YourRateEntry>> savedMaterials() async {
      final result = await Modular.get<YourRatesRepository>().search(
        '',
        category: CostItemType.material,
        companyId: 'company-1',
      );
      return result.getRightOrNull()!;
    }

    testWidgets('saves the sample rate to Your rates under the material name, '
        'with its unit as the entry label', (tester) async {
      await openVerify(tester);

      await tester.tap(link);
      await tester.pumpAndSettle();

      final saved = (await savedMaterials()).single;
      expect(saved.itemName, 'Interior paint · ProClassic');
      expect(saved.rate.amount, 52);
      expect(saved.unit, Unit.liters);
      expect(saved.entryLabel, 'liters');
    });

    testWidgets('once saved, the tag and the link go and the line says it '
        'is saved', (tester) async {
      await openVerify(tester);

      await tester.tap(link);
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(badge, findsNothing);
      expect(link, findsNothing);
      expect(
        find.byKey(const Key('save_as_default_helper_text')),
        findsNothing,
      );
      expect(
        find.text(
          l10n.materialSavedToYourRatesHint(
            l10n.yourRatesName,
            'interior paint',
          ),
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(bloc.state.data.rateStatus, RateStatus.ownRateConfirmed);
    });

    testWidgets('the saved line goes once the name is changed', (tester) async {
      await openVerify(tester);
      await tester.tap(link);
      await tester.pumpAndSettle();

      await tester.enterText(nameField, 'Primer');
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('saved_as_default_helper_text')),
        findsNothing,
      );
    });

    testWidgets('a failed save keeps the tag and the link and says the rate '
        'was not saved', (tester) async {
      await openVerify(tester);
      database.executeError = StateError('disk full');

      await tester.tap(link);
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(badge, findsOneWidget);
      expect(link, findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('save_as_default_error')),
          matching: find.text(l10n.yourRatesSaveFailedError),
        ),
        findsOneWidget,
      );
      expect(bloc.state.data.rateStatus, RateStatus.sampleRateUnverified);
    });

    testWidgets('a second try after a failure saves the rate', (tester) async {
      await openVerify(tester);
      database.executeError = StateError('disk full');
      await tester.tap(link);
      await tester.pumpAndSettle();

      database.executeError = null;
      await tester.tap(link);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('save_as_default_error')), findsNothing);
      expect(badge, findsNothing);
      expect(await savedMaterials(), hasLength(1));
    });

    testWidgets('a name and unit already in Your rates asks for a label and '
        'saves the rate under it', (tester) async {
      database.seedRow({
        'id': 'old-paint',
        'company_id': 'company-1',
        'category': 'material',
        'item_name': 'Interior paint · ProClassic',
        'rate_amount': 48.0,
        'rate_currency': 'USD',
        'unit': 'liters',
        'entry_label': 'liters',
        'saved_at': '2026-01-01T00:00:00.000Z',
      });
      await openVerify(tester);

      await tester.tap(link);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('entry_label_dialog_title')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('entry_label_field')),
        'Supplier A',
      );
      await tester.tap(find.byKey(const Key('entry_label_dialog_save_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('entry_label_dialog_title')), findsNothing);
      expect(badge, findsNothing);
      final labels = (await savedMaterials()).map((e) => e.entryLabel);
      expect(labels, containsAll(['liters', 'Supplier A']));
    });

    testWidgets('the link is not offered for a rate picked from Your rates', (
      tester,
    ) async {
      database.seedRow({
        'id': 'paint-rate',
        'company_id': 'company-1',
        'category': 'material',
        'item_name': 'Interior paint',
        'rate_amount': 52.0,
        'rate_currency': 'USD',
        'unit': 'liters',
        'saved_at': '2026-01-10T00:00:00.000Z',
      });
      await pumpFields(tester);
      await tester.enterText(nameField, 'interior paint');
      await tester.tap(find.byKey(const Key('lookup_rate_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('your_rate_row_paint-rate')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('material_lookup_use_button')));
      await tester.pumpAndSettle();

      expect(link, findsNothing);
    });
  });
}
