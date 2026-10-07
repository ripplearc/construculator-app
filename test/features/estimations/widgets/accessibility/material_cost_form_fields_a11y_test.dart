import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_footer.dart';
import 'package:construculator/features/estimation/presentation/widgets/material_add_to_estimate_footer.dart';
import 'package:construculator/features/estimation/presentation/widgets/material_cost_form_fields.dart';
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
  setUpAll(() {
    Modular.init(
      EstimationModule(
        FakeAppBootstrapFactory.create(
          supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
        ),
      ),
    );
  });

  tearDownAll(Modular.dispose);

  Widget makeWidget(ThemeData theme) => MaterialApp(
    theme: theme,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: BlocProvider<MaterialCostFormBloc>(
        create: (_) => Modular.get<MaterialCostFormBloc>(),
        child: const Column(
          children: [
            Flexible(child: MaterialCostFormFields()),
            MaterialAddToEstimateFooter(
              estimateId: 'estimate-1',
              estimateName: 'Bedroom 2',
              estimateTotal: 2093.02,
            ),
          ],
        ),
      ),
    ),
  );

  group('Material sheet – accessibility', () {
    testWidgets('a11y: the unit button meets tap target and label guidelines '
        'in both themes', (tester) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        makeWidget,
        find.byKey(const Key('material_unit_pill')),
      );
    });

    testWidgets('a11y: the disabled Add button meets tap target and label '
        'guidelines in both themes', (tester) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        makeWidget,
        find.byKey(AddToEstimateFooter.buttonKey),
        // TODO: [CA-1257] re-enable once design fixes the 2.42:1 grey on the summary card. https://ripplearc.youtrack.cloud/issue/CA-1257
        checkTextContrast: false,
      );
    });

    testWidgets(
      'a11y: the unit button tells a screen reader to choose a unit',
      (tester) async {
        await setupA11yTest(tester);
        await tester.pumpWidget(makeWidget(createTestTheme()));
        await tester.pumpAndSettle();

        expect(
          tester
              .getSemantics(find.byKey(const Key('material_unit_pill')))
              .label,
          'Choose a unit',
        );
      },
    );

    testWidgets('a11y: the card reads the reason the button is disabled', (
      tester,
    ) async {
      await setupA11yTest(tester);
      await tester.pumpWidget(makeWidget(createTestTheme()));
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.byKey(AddToEstimateFooter.panelKey)).label,
        contains('Needs a name before it can total'),
      );
    });
  });
}
