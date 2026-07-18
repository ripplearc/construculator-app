import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/calc_method_card.dart';
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

  Widget makeWidget({
    LaborCalculationMethodType calcMethod = LaborCalculationMethodType.perDay,
    bool showRateRow = false,
    ValueChanged<LaborCalculationMethodType>? onMethodChanged,
  }) {
    return MaterialApp(
      theme: CoreTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: CalcMethodCard(
          calcMethod: calcMethod,
          showRateRow: showRateRow,
          onMethodChanged: onMethodChanged ?? (_) {},
        ),
      ),
    );
  }

  group('CalcMethodCard — options', () {
    testWidgets('shows per day and per hours options', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('per_day_option')), findsOneWidget);
      expect(find.byKey(const Key('per_hours_option')), findsOneWidget);
    });

    testWidgets('per day is selected by default', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      final perDay = tester.getSemantics(find.byKey(const Key('per_day_option')));
      expect(perDay.hasFlag(SemanticsFlag.isSelected), isTrue);
    });

    testWidgets('per hours is selected when calcMethod is perHour', (tester) async {
      await tester.pumpWidget(
        makeWidget(calcMethod: LaborCalculationMethodType.perHour),
      );
      await tester.pumpAndSettle();

      final perHours = tester.getSemantics(
        find.byKey(const Key('per_hours_option')),
      );
      expect(perHours.hasFlag(SemanticsFlag.isSelected), isTrue);
    });

    testWidgets('calls onMethodChanged with perHour when per hours tapped', (
      tester,
    ) async {
      LaborCalculationMethodType? selected;
      await tester.pumpWidget(
        makeWidget(onMethodChanged: (m) => selected = m),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('per_hours_option')));
      await tester.pump();

      expect(selected, LaborCalculationMethodType.perHour);
    });

    testWidgets('calls onMethodChanged with perDay when per day tapped', (
      tester,
    ) async {
      LaborCalculationMethodType? selected;
      await tester.pumpWidget(
        makeWidget(
          calcMethod: LaborCalculationMethodType.perHour,
          onMethodChanged: (m) => selected = m,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('per_day_option')));
      await tester.pump();

      expect(selected, LaborCalculationMethodType.perDay);
    });
  });

  group('CalcMethodCard — rate row', () {
    testWidgets('hides rate row when showRateRow is false', (tester) async {
      await tester.pumpWidget(makeWidget(showRateRow: false));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('rate_row')), findsNothing);
    });

    testWidgets('shows rate row when showRateRow is true', (tester) async {
      await tester.pumpWidget(makeWidget(showRateRow: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('rate_row')), findsOneWidget);
    });

    testWidgets('shows Rate/Day label when per day method is selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeWidget(
          calcMethod: LaborCalculationMethodType.perDay,
          showRateRow: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.rateDayLabel), findsOneWidget);
    });

    testWidgets('shows Rate/Hour label when per hours method is selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeWidget(
          calcMethod: LaborCalculationMethodType.perHour,
          showRateRow: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.rateHourLabel), findsOneWidget);
    });
  });
}
