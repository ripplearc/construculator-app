import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_footer.dart';
import 'package:construculator/features/estimation/presentation/widgets/material_add_to_estimate_footer.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../../utils/screenshot/font_loader.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;

  setUpAll(() {
    fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
    Modular.init(
      EstimationModule(
        FakeAppBootstrapFactory.create(supabaseWrapper: fakeSupabase),
      ),
    );
  });

  tearDownAll(Modular.dispose);

  setUp(() => fakeSupabase.reset());

  Widget makeWidget(ThemeData theme, MaterialCostFormBloc bloc) => MaterialApp(
    theme: theme,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: BlocProvider<MaterialCostFormBloc>.value(
        value: bloc,
        child: const MaterialAddToEstimateFooter(
          estimateId: 'estimate-1',
          estimateName: 'Bedroom 2',
          estimateTotal: 2993.62,
        ),
      ),
    ),
  );

  MaterialCostFormBloc newBloc() {
    final bloc = Modular.get<MaterialCostFormBloc>();
    addTearDown(bloc.close);
    return bloc;
  }

  group('MaterialAddToEstimateFooter – accessibility', () {
    testWidgets('a11y: the disabled button meets tap target and label '
        'guidelines in both themes', (tester) async {
      await setupA11yTest(tester);
      final bloc = newBloc();

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeWidget(theme, bloc),
        find.byKey(AddToEstimateFooter.buttonKey),
        // TODO: [CA-1257] re-enable once design fixes the 2.42:1 grey on the summary card. https://ripplearc.youtrack.cloud/issue/CA-1257
        checkTextContrast: false,
      );
    });

    testWidgets('a11y: the card is one live region that reads the reason '
        'the button is disabled', (tester) async {
      await setupA11yTest(tester);
      await tester.pumpWidget(makeWidget(createTestTheme(), newBloc()));
      await tester.pumpAndSettle();

      final semantics = tester.getSemantics(
        find.byKey(AddToEstimateFooter.panelKey),
      );

      expect(semantics.label, contains('Needs a name before it can total'));
    });

    testWidgets('a11y: the save-failed line is read out when it appears', (
      tester,
    ) async {
      await setupA11yTest(tester);
      final handle = tester.ensureSemantics();
      fakeSupabase.shouldThrowOnInsert = true;
      final bloc = newBloc()
        ..add(const MaterialCostItemTypeChanged('Interior paint'))
        ..add(const MaterialQuantityUpdated('7'))
        ..add(const MaterialUnitSelected(Unit.liters))
        ..add(const MaterialRateUpdated('2.55'));
      await tester.pumpWidget(makeWidget(createTestTheme(), bloc));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(AddToEstimateFooter.buttonKey));
      await tester.pump();
      await tester.pump();

      final semantics = tester.getSemantics(
        find.byKey(AddToEstimateFooter.errorKey),
      );
      expect(semantics.label, contains('This cost was not added. Try again.'));
      expect(semantics.flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });
  });
}
