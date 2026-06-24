// ignore_for_file: no_direct_instantiation
import 'package:construculator/features/global_search/presentation/widgets/date_range_bottom_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

/// Captures the result resolved by [DateRangeBottomSheet.show], since the
/// sheet is opened and closed across separate `pump` calls in a test body.
class _ResultHolder {
  DateRange? value;
  bool resolved = false;
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  Future<_ResultHolder> pumpAndShow(
    WidgetTester tester, {
    DateRange? initialRange,
  }) async {
    final holder = _ResultHolder();
    await tester.pumpWidget(
      MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                holder.value = await DateRangeBottomSheet.show(
                  context: context,
                  initialRange: initialRange,
                );
                holder.resolved = true;
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return holder;
  }

  testWidgets('shows the title and all predefined range options', (
    tester,
  ) async {
    await pumpAndShow(tester);

    expect(find.text(l10n.dateRangeSheetTitle), findsOneWidget);
    expect(find.text(l10n.dateRangeSheetToday), findsOneWidget);
    expect(find.text(l10n.dateRangeSheetLast7Days), findsOneWidget);
    expect(find.text(l10n.dateRangeSheetLast30Days), findsOneWidget);
    expect(find.text(l10n.dateRangeSheetThisMonth), findsOneWidget);
    expect(find.text(l10n.dateRangeSheetCustomRange), findsOneWidget);
  });

  testWidgets('defaults to Today selected when no initial range is given', (
    tester,
  ) async {
    await pumpAndShow(tester);

    final todayTile = tester.widget<RadioListTile<Object?>>(
      find.byKey(const Key('date_range_option_today')),
    );
    expect(todayTile.groupValue, todayTile.value);
  });

  testWidgets('applying Today resolves with start == end == today', (
    tester,
  ) async {
    final holder = await pumpAndShow(tester);

    await tester.tap(find.byKey(const Key('date_range_apply_button')));
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    expect(holder.resolved, isTrue);
    expect(holder.value!.start, today);
    expect(holder.value!.end, today);
  });

  testWidgets('selecting Last 7 days resolves with a 7-day span', (
    tester,
  ) async {
    final holder = await pumpAndShow(tester);

    await tester.tap(find.byKey(const Key('date_range_option_last7Days')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('date_range_apply_button')));
    await tester.pumpAndSettle();

    expect(holder.resolved, isTrue);
    expect(holder.value!.end.difference(holder.value!.start).inDays, 6);
  });

  testWidgets('selecting Last 30 days resolves with a 30-day span', (
    tester,
  ) async {
    final holder = await pumpAndShow(tester);

    await tester.tap(find.byKey(const Key('date_range_option_last30Days')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('date_range_apply_button')));
    await tester.pumpAndSettle();

    expect(holder.resolved, isTrue);
    expect(holder.value!.end.difference(holder.value!.start).inDays, 29);
  });

  testWidgets('selecting This month resolves with start on the 1st', (
    tester,
  ) async {
    final holder = await pumpAndShow(tester);

    await tester.tap(find.byKey(const Key('date_range_option_thisMonth')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('date_range_apply_button')));
    await tester.pumpAndSettle();

    final now = DateTime.now();
    expect(holder.resolved, isTrue);
    expect(holder.value!.start, DateTime(now.year, now.month, 1));
  });

  testWidgets(
    'selecting Custom range opens the date picker twice and resolves with the chosen span',
    (tester) async {
      final holder = await pumpAndShow(tester);

      await tester.tap(find.byKey(const Key('date_range_option_custom')));
      await tester.pumpAndSettle();

      // Start date picker is open; tap a day then confirm.
      await tester.tap(find.text('12').first);
      await tester.pump();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // End date picker is open; tap a later day then confirm.
      await tester.tap(find.text('15').first);
      await tester.pump();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      final customTile = tester.widget<RadioListTile<Object?>>(
        find.byKey(const Key('date_range_option_custom')),
      );
      expect(customTile.groupValue, customTile.value);

      await tester.tap(find.byKey(const Key('date_range_apply_button')));
      await tester.pumpAndSettle();

      expect(holder.resolved, isTrue);
      expect(holder.value!.end.difference(holder.value!.start).inDays, 3);
    },
  );

  testWidgets(
    'cancelling the start date picker leaves the previous selection unchanged',
    (tester) async {
      await pumpAndShow(tester);

      await tester.tap(find.byKey(const Key('date_range_option_custom')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();

      final todayTile = tester.widget<RadioListTile<Object?>>(
        find.byKey(const Key('date_range_option_today')),
      );
      expect(todayTile.groupValue, todayTile.value);
    },
  );

  testWidgets('Cancel resolves with null and does not apply a selection', (
    tester,
  ) async {
    final holder = await pumpAndShow(tester);

    await tester.tap(find.byKey(const Key('date_range_option_last7Days')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('date_range_cancel_button')));
    await tester.pumpAndSettle();

    expect(holder.resolved, isTrue);
    expect(holder.value, isNull);
  });

  testWidgets('pre-selects Custom range when reopened with an initial range', (
    tester,
  ) async {
    final initial = DateRange(
      start: DateTime(2026, 1, 1),
      end: DateTime(2026, 1, 5),
    );

    await pumpAndShow(tester, initialRange: initial);

    final customTile = tester.widget<RadioListTile<Object?>>(
      find.byKey(const Key('date_range_option_custom')),
    );
    expect(customTile.groupValue, customTile.value);
  });

  testWidgets(
    'reapplying without changing the selection keeps the initial custom range',
    (tester) async {
      final initial = DateRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 5),
      );

      final holder = await pumpAndShow(tester, initialRange: initial);

      await tester.tap(find.byKey(const Key('date_range_apply_button')));
      await tester.pumpAndSettle();

      expect(holder.resolved, isTrue);
      expect(holder.value, initial);
    },
  );
}
