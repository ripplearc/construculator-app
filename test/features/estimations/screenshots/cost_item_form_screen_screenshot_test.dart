import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/equipment_cost_form_bloc/equipment_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/labour_cost_form_bloc/labour_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_item_form_screen.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';
import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 844);
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseWrapper fakeSupabase;

  setUpAll(() {
    fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
    final bootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: fakeSupabase,
    );
    Modular.init(EstimationModule(bootstrap));
  });

  tearDownAll(() {
    Modular.dispose();
  });

  setUp(() async {
    fakeSupabase.reset();
    await loadAppFontsAll();
  });

  Future<void> pumpScreen({
    required WidgetTester tester,
    required CostItemType type,
    bool fromCostFile = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<MaterialCostFormBloc>(
              create: (_) => Modular.get<MaterialCostFormBloc>(),
            ),
            BlocProvider<LabourCostFormBloc>(
              create: (_) => Modular.get<LabourCostFormBloc>(),
            ),
            BlocProvider<EquipmentCostFormBloc>(
              create: (_) => Modular.get<EquipmentCostFormBloc>(),
            ),
          ],
          child: CostItemFormScreen(
            type: type,
            estimationId: 'test-estimation-id',
            router: FakeAppRouter(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    if (fromCostFile) {
      await tester.tap(find.byKey(const Key('from_cost_file_pill')));
      await tester.pumpAndSettle();
    }
  }

  group('CostItemFormScreen Screenshot Tests', () {
    testWidgets('renders labour cost screen in manually mode', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await pumpScreen(tester: tester, type: CostItemType.labor);

      await expectLater(
        find.byType(CostItemFormScreen),
        matchesGoldenFile(
          'goldens/cost_item_form_screen/${size.width}x${size.height}/labour_manually.png',
        ),
      );
    });

    testWidgets('renders material cost screen in manually mode', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await pumpScreen(tester: tester, type: CostItemType.material);

      await expectLater(
        find.byType(CostItemFormScreen),
        matchesGoldenFile(
          'goldens/cost_item_form_screen/${size.width}x${size.height}/material_manually.png',
        ),
      );
    });

    testWidgets('renders material cost screen in from cost file mode', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await pumpScreen(
        tester: tester,
        type: CostItemType.material,
        fromCostFile: true,
      );

      await expectLater(
        find.byType(CostItemFormScreen),
        matchesGoldenFile(
          'goldens/cost_item_form_screen/${size.width}x${size.height}/material_from_cost_file.png',
        ),
      );
    });

    testWidgets('renders material cost screen with item type error', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await pumpScreen(tester: tester, type: CostItemType.material);
      await tester.enterText(
        find.byKey(const Key('material_type_field')),
        'x',
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('material_type_field')),
        '',
      );
      await tester.pump();

      await expectLater(
        find.byType(CostItemFormScreen),
        matchesGoldenFile(
          'goldens/cost_item_form_screen/${size.width}x${size.height}/material_manually_error.png',
        ),
      );
    });
  });
}
