import 'package:construculator/features/global_search/presentation/widgets/date_filter_chip.dart';
import 'package:construculator/features/global_search/presentation/widgets/date_range_bottom_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  Future<void> pumpChip(
    WidgetTester tester, {
    DateRange? selectedDateRange,
    ValueChanged<DateRange>? onApply,
    VoidCallback? onClear,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DateFilterChip(
            selectedDateRange: selectedDateRange,
            onApply: onApply ?? (_) {},
            onClear: onClear ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('shows the inactive chip with the Modified label when no range is selected', (
    tester,
  ) async {
    await pumpChip(tester);

    expect(find.byKey(const Key('global_search_date_filter_chip')), findsOneWidget);
    expect(find.byKey(const Key('active_date_filter_chip')), findsNothing);
    expect(find.text(l10n.globalSearchFilterModified), findsOneWidget);
  });

  testWidgets('opens DateRangeBottomSheet and applies the chosen range on tap', (
    tester,
  ) async {
    DateRange? applied;
    await pumpChip(tester, onApply: (range) => applied = range);

    await tester.tap(find.byKey(const Key('global_search_date_filter_chip')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.dateRangeSheetTitle), findsOneWidget);

    await tester.tap(find.byKey(const Key('date_range_apply_button')));
    await tester.pumpAndSettle();

    expect(applied, isNotNull);
  });

  testWidgets('does not call onApply when the sheet is cancelled', (
    tester,
  ) async {
    var applyCalled = false;
    await pumpChip(tester, onApply: (_) => applyCalled = true);

    await tester.tap(find.byKey(const Key('global_search_date_filter_chip')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('date_range_cancel_button')));
    await tester.pumpAndSettle();

    expect(applyCalled, isFalse);
  });

  testWidgets('shows the active pill with the formatted range when a range is selected', (
    tester,
  ) async {
    await pumpChip(
      tester,
      selectedDateRange: DateRange(
        start: DateTime(2024, 3, 1),
        end: DateTime(2024, 3, 31),
      ),
    );

    expect(find.byKey(const Key('active_date_filter_chip')), findsOneWidget);
    expect(find.byKey(const Key('global_search_date_filter_chip')), findsNothing);
    expect(find.text('Mar 01, 2024 - Mar 31, 2024'), findsOneWidget);
  });

  testWidgets('shows a single formatted date when start equals end', (
    tester,
  ) async {
    final today = DateTime(2024, 3, 1);
    await pumpChip(
      tester,
      selectedDateRange: DateRange(start: today, end: today),
    );

    expect(find.text('Mar 01, 2024'), findsOneWidget);
  });

  testWidgets('calls onClear when the active pill is tapped', (
    tester,
  ) async {
    var clearCalled = false;
    await pumpChip(
      tester,
      selectedDateRange: DateRange(
        start: DateTime(2024, 3, 1),
        end: DateTime(2024, 3, 31),
      ),
      onClear: () => clearCalled = true,
    );

    await tester.tap(find.byKey(const Key('active_date_filter_chip')));
    await tester.pumpAndSettle();

    expect(clearCalled, isTrue);
  });
}
