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

    testWidgets('the name row leaves 10 dp between its label and value', (
      tester,
    ) async {
      await pumpFields(tester);

      final label = tester.getRect(find.text('Material'));
      final value = tester.getRect(find.text('Name the material'));
      expect(value.top - label.bottom, 10);
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
}
