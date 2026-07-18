import 'package:construculator/features/estimation/presentation/widgets/labour_cost_form_fields.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() {
    l10n = lookupAppLocalizations(const Locale('en'));
  });

  Widget makeWidget({bool fromCostFile = false}) {
    return MaterialApp(
      theme: CoreTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: LabourCostFormFields(fromCostFile: fromCostFile),
      ),
    );
  }

  group('LabourCostFormFields — manually mode', () {
    testWidgets('shows labour type text field', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('labour_type_field')), findsOneWidget);
    });

    testWidgets('shows calc method card', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('calc_method_card')), findsOneWidget);
    });

    testWidgets('shows crew rate field with dollar suffix', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('crew_rate_field')), findsOneWidget);
    });

    testWidgets('hides cost file field', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cost_file_field')), findsNothing);
    });

    testWidgets('hides rate row inside calc method card', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('rate_row')), findsNothing);
    });

    testWidgets('shows conditional field with "No. of days" label by default', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('conditional_value_field')), findsOneWidget);
      expect(find.text(l10n.noOfDaysLabel), findsOneWidget);
    });

    testWidgets('shows crew size field', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('crew_size_field')), findsOneWidget);
    });
  });

  group('LabourCostFormFields — from cost file mode', () {
    testWidgets('shows cost file dropdown placeholder', (tester) async {
      await tester.pumpWidget(makeWidget(fromCostFile: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cost_file_field')), findsOneWidget);
    });

    testWidgets('shows labour type dropdown placeholder', (tester) async {
      await tester.pumpWidget(makeWidget(fromCostFile: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('labour_type_field')), findsOneWidget);
    });

    testWidgets('hides crew rate field', (tester) async {
      await tester.pumpWidget(makeWidget(fromCostFile: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('crew_rate_field')), findsNothing);
    });

    // TODO: [CA-298] Assert rate row is visible once cost file is selected and rate is wired
    testWidgets('hides rate row inside calc method card until cost file selected', (tester) async {
      await tester.pumpWidget(makeWidget(fromCostFile: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('rate_row')), findsNothing);
    });
  });

  group('LabourCostFormFields — calc method switching', () {
    testWidgets('per day is selected by default', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      final perDay = tester.getSemantics(find.byKey(const Key('per_day_option')));
      expect(perDay.hasFlag(SemanticsFlag.isSelected), isTrue);
    });

    testWidgets('tapping per hours changes conditional field label', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('per_hours_option')));
      await tester.pumpAndSettle();

      expect(find.text(l10n.noOfHoursLabel), findsOneWidget);
      expect(find.text(l10n.noOfDaysLabel), findsNothing);
    });

    testWidgets('per hours option selected after tap', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('per_hours_option')));
      await tester.pumpAndSettle();

      final perHours = tester.getSemantics(
        find.byKey(const Key('per_hours_option')),
      );
      final perDay = tester.getSemantics(find.byKey(const Key('per_day_option')));
      expect(perHours.hasFlag(SemanticsFlag.isSelected), isTrue);
      expect(perDay.hasFlag(SemanticsFlag.isSelected), isFalse);
    });
  });
}
