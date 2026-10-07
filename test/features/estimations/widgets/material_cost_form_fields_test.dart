import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/last_used_unit_repository.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/material_cost_form_fields.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_field_row.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/storage/interfaces/storage_service.dart';
import 'package:construculator/libraries/storage/testing/fake_storage_service.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  late FakeStorageService storage;
  late FakeAuthRepository auth;
  late LastUsedUnitRepository lastUsedUnits;
  late MaterialCostFormBloc bloc;

  final nameField = find.byKey(const Key('material_name_field'));
  final quantityField = find.byKey(const Key('material_quantity_field'));
  final rateField = find.byKey(const Key('material_rate_field'));
  final unitPill = find.byKey(const Key('material_unit_pill'));

  setUpAll(() {
    final clock = FakeClockImpl();
    storage = FakeStorageService();
    auth = FakeAuthRepository(clock: clock);
    Modular.init(
      EstimationModule(
        FakeAppBootstrapFactory.create(
          supabaseWrapper: FakeSupabaseWrapper(clock: clock),
        ),
      ),
    );
    Modular.replaceInstance<StorageService>(storage);
    Modular.replaceInstance<AuthRepository>(auth);
    lastUsedUnits = Modular.get<LastUsedUnitRepository>();
  });

  tearDownAll(Modular.dispose);

  setUp(() {
    storage.reset();
    auth.reset();
    auth.setCurrentCredentials(
      UserCredential(
        id: 'account-1',
        email: 'a@example.com',
        metadata: const {},
        createdAt: DateTime(2026),
      ),
    );
  });

  Future<void> pumpFields(WidgetTester tester) async {
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
            child: const MaterialCostFormFields(),
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

    testWidgets('the name row is 73 dp tall with its divider', (tester) async {
      await pumpFields(tester);

      expect(rowSize(tester, 'Material').height, 72 + 1);
    });

    testWidgets('the quantity row is 90 dp tall, so the 48 dp tap area of the '
        'unit button does not stretch it', (tester) async {
      await pumpFields(tester);

      expect(rowSize(tester, 'Quantity').height, 90 + 1);
    });

    testWidgets('the unit button is drawn 38 dp tall', (tester) async {
      await pumpFields(tester);

      final drawn = find.descendant(
        of: unitPill,
        matching: find.byType(DecoratedBox),
      );
      expect(tester.getSize(drawn.first).height, 38);
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

    testWidgets('the unit button opens its list from 20 dp below its centre', (
      tester,
    ) async {
      await pumpFields(tester);
      final centre = tester.getCenter(unitPill);

      await tester.tapAt(centre + const Offset(0, 22));
      await tester.pumpAndSettle();

      expect(find.text('Select unit'), findsOneWidget);
    });

    testWidgets('the unit button area does not reach the next row', (
      tester,
    ) async {
      await pumpFields(tester);
      final box = tester.getRect(unitPill);

      expect(box.height, 48);
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
}
