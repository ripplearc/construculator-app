import 'dart:async';

import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_item_form_screen.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_header.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_surface.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';
import '../../../utils/fake_cost_items_database.dart';
import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(412, 917);
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseWrapper fakeSupabase;
  late FakeCostItemsDatabase database;

  setUpAll(() {
    fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
    database = FakeCostItemsDatabase();
    Modular.init(
      EstimationModule(
        FakeAppBootstrapFactory.create(supabaseWrapper: fakeSupabase),
      ),
    );
    Modular.replaceInstance<PowerSyncDatabaseWrapper>(database);
  });

  tearDownAll(Modular.dispose);

  setUp(() async {
    fakeSupabase.reset();
    database.reset();
    await loadAppFontsAll();
  });

  Future<void> openSheet(
    WidgetTester tester,
    ThemeData theme, {
    Size size = size,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final bloc = Modular.get<MaterialCostFormBloc>();
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                key: const Key('open_sheet'),
                onPressed: () => CoreQuickSheet.show<void>(
                  context: context,
                  enableDrag: false,
                  backgroundColor: sheetSurface(context),
                  child: BlocProvider<MaterialCostFormBloc>.value(
                    value: bloc,
                    child: CostItemFormScreen(
                      type: CostItemType.material,
                      estimationId: 'test-estimation-id',
                      router: FakeAppRouter(),
                      yourRatesBlocFactory: () => Modular.get<YourRatesBloc>(),
                      clock: FakeClockImpl(),
                      presentAsSheet: true,
                      estimate: CostEstimate.defaultEstimate(
                        estimateName: 'Bedroom 2',
                        totalCost: 1238.02,
                      ),
                    ),
                  ),
                ),
                child: const Text('Add material cost'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open_sheet')));
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, String key, String text) async {
    await tester.enterText(find.byKey(Key(key)), text);
    await tester.pumpAndSettle();
  }

  Future<void> pickUnit(WidgetTester tester, Unit unit) async {
    await tester.tap(find.byKey(const Key('material_unit_pill')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(Key('unit_option_${unit.name}')));
    await tester.tap(find.byKey(Key('unit_option_${unit.name}')));
    await tester.pumpAndSettle();
  }

  Future<void> expectSheetGolden(
    WidgetTester tester,
    String name,
    String suffix,
  ) async {
    // A focused field draws a blinking caret that changes between runs.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/material_cost_sheet/$name$suffix.png'),
    );
  }

  screenshotThemeGroups('Material cost sheet Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('empty, name missing', (tester) async {
      await openSheet(tester, theme);
      await expectSheetGolden(tester, 'empty_name_missing', suffix);
    });

    testWidgets('quantity missing', (tester) async {
      await openSheet(tester, theme);
      await enter(tester, 'material_name_field', 'Interior paint');
      await expectSheetGolden(tester, 'quantity_missing', suffix);
    });

    testWidgets('quantity is zero', (tester) async {
      await openSheet(tester, theme);
      await enter(tester, 'material_name_field', 'Interior paint');
      await enter(tester, 'material_quantity_field', '0');
      await expectSheetGolden(tester, 'quantity_zero', suffix);
    });

    testWidgets('unit missing', (tester) async {
      await openSheet(tester, theme);
      await enter(tester, 'material_name_field', 'Interior paint');
      await enter(tester, 'material_quantity_field', '3');
      await expectSheetGolden(tester, 'unit_missing', suffix);
    });

    testWidgets('rate missing, as in the Figma New material screen', (
      tester,
    ) async {
      await openSheet(tester, theme);
      await enter(tester, 'material_name_field', 'Interior paint');
      await enter(tester, 'material_quantity_field', '3');
      await pickUnit(tester, Unit.gallons);
      await expectSheetGolden(tester, 'rate_missing', suffix);
    });

    testWidgets('rate out of range', (tester) async {
      await openSheet(tester, theme);
      await enter(tester, 'material_name_field', 'Interior paint');
      await enter(tester, 'material_quantity_field', '3');
      await pickUnit(tester, Unit.gallons);
      await enter(tester, 'material_rate_field', '1000000');
      await expectSheetGolden(tester, 'rate_out_of_range', suffix);
    });

    testWidgets('ready to add', (tester) async {
      await openSheet(tester, theme);
      await enter(tester, 'material_name_field', 'Interior paint');
      await enter(tester, 'material_quantity_field', '3');
      await pickUnit(tester, Unit.gallons);
      await enter(tester, 'material_rate_field', '52');
      await expectSheetGolden(tester, 'ready_to_add', suffix);
    });

    Future<void> fillAndTapAdd(WidgetTester tester, String name) async {
      await enter(tester, 'material_name_field', name);
      await enter(tester, 'material_quantity_field', '3');
      await pickUnit(tester, Unit.gallons);
      await enter(tester, 'material_rate_field', '52');
      // A tap on the title closes the number pad, which hides the button.
      await tester.tap(find.text('New material cost'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add_to_estimate_button')));
    }

    final eightyCharacterName = ('Type-X fire-rated gypsum board ' * 3)
        .substring(0, 80);

    testWidgets('save failed, with the error above the button', (tester) async {
      database.executeError = StateError('disk full');
      await openSheet(tester, theme);
      await fillAndTapAdd(tester, 'Interior paint');
      await tester.pumpAndSettle();
      await expectSheetGolden(tester, 'save_failed', suffix);
    });

    testWidgets('save failed with an 80 character name: the name stays on one '
        'line ending in "…"', (tester) async {
      database.executeError = StateError('disk full');
      await openSheet(tester, theme);
      await fillAndTapAdd(tester, eightyCharacterName);
      await tester.pumpAndSettle();
      await expectSheetGolden(tester, 'save_failed_long_name', suffix);
    });

    testWidgets('while an 80 character name saves, it stays on one line '
        'ending in "…"', (tester) async {
      final held = Completer<void>();
      database.writeGate = held;
      await openSheet(tester, theme);
      await fillAndTapAdd(tester, eightyCharacterName);
      await tester.pump();
      try {
        await expectSheetGolden(tester, 'saving_long_name', suffix);
      } finally {
        held.complete();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('an 80 character name stays on one line ending in "…"', (
      tester,
    ) async {
      await openSheet(tester, theme);
      await enter(tester, 'material_name_field', 'a' * 80);
      await expectSheetGolden(tester, 'long_name', suffix);
    });

    testWidgets('unit list open on the picked unit, as in the storyboard', (
      tester,
    ) async {
      await openSheet(tester, theme);
      await pickUnit(tester, Unit.gallons);
      await tester.tap(find.byKey(const Key('material_unit_pill')));
      await tester.pumpAndSettle();
      await expectSheetGolden(tester, 'unit_list', suffix);
    });

    testWidgets('discard question', (tester) async {
      await openSheet(tester, theme);
      await enter(tester, 'material_name_field', 'Interior paint');
      await tester.tap(find.byKey(SheetHeader.backButtonKey));
      await tester.pumpAndSettle();
      await expectSheetGolden(tester, 'discard_question', suffix);
    });

    // Keeps focus, so the pad stays up, with a caret that does not blink.
    Future<void> expectPadGolden(WidgetTester tester, String name) async {
      EditableText.debugDeterministicCursor = true;
      addTearDown(() => EditableText.debugDeterministicCursor = false);
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/material_cost_sheet/$name$suffix.png'),
      );
    }

    Future<void> padUpOnQuantity(WidgetTester tester, Size size) async {
      await openSheet(tester, theme, size: size);
      await enter(tester, 'material_name_field', 'Interior paint');
      await enter(tester, 'material_quantity_field', '25');
      await pickUnit(tester, Unit.gallons);
      await enter(tester, 'material_rate_field', '14.75');
      await tester.tap(find.text('New material cost'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('material_quantity_field')));
    }

    testWidgets('number pad up on the quantity', (tester) async {
      await padUpOnQuantity(tester, size);
      await expectPadGolden(tester, 'pad_up_quantity');
    });

    testWidgets('number pad up on an empty rate', (tester) async {
      await openSheet(tester, theme);
      await tester.tap(find.byKey(const Key('material_rate_field')));
      await expectPadGolden(tester, 'pad_up_empty_rate');
    });

    testWidgets('number pad up on the rate, scrolled 12 clear of the card, '
        'with a line under the title', (tester) async {
      await padUpOnQuantity(tester, size);
      await tester.pumpAndSettle();
      await tester.showKeyboard(find.byKey(const Key('material_rate_field')));
      await expectPadGolden(tester, 'pad_up_rate_scrolled');
    });

    testWidgets('phone keyboard up on the name: the form button is back above '
        'it', (tester) async {
      await openSheet(tester, theme);
      await tester.showKeyboard(find.byKey(const Key('material_name_field')));
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await expectPadGolden(tester, 'text_keyboard_up');
    });

    testWidgets('number pad up on a 667 dp phone, card scrolled with the '
        'form', (tester) async {
      await padUpOnQuantity(tester, const Size(375, 667));
      await expectPadGolden(tester, 'pad_up_short_phone');
    });
  });
}
