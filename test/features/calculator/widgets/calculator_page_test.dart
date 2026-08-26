import 'package:construculator/features/calculator/presentation/pages/calculator_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  testWidgets('renders a Scaffold using the core page background color', (
    tester,
  ) async {
    final theme = CoreTheme.light();

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CalculatorPage(),
      ),
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));

    expect(scaffold.backgroundColor, equals(theme.coreColors.pageBackground));
  });

  testWidgets(
    'keys carry the domain ids CalculatorMath matches on, not display text',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CoreTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CalculatorPage(),
        ),
      );

      final keyboard = tester.widget<CoreKeyboard>(find.byType(CoreKeyboard));
      final ids = [
        for (final group in keyboard.allGroups)
          for (final key in group.keys) key.id,
      ];

      // calculator_math.dart keys finalizedValues on these exact strings.
      // Renaming an id here silently breaks pitch and fence computation.
      expect(ids, containsAll(<String>['Rise', 'Run', 'Length', 'Fence']));
    },
  );

  testWidgets('every key label comes from the localization layer', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CalculatorPage(),
      ),
    );

    final l10n = AppLocalizations.of(
      tester.element(find.byType(CoreKeyboard)),
    )!;
    final keyboard = tester.widget<CoreKeyboard>(find.byType(CoreKeyboard));
    final labelsById = {
      for (final group in keyboard.allGroups)
        for (final key in group.keys) key.id: key.label,
    };

    // A key whose id is missing from the resolver falls through to the raw id.
    // Pinning the pairs here means a new key without an ARB entry fails.
    expect(labelsById['Rise'], equals(l10n.calculatorKeyRise));
    expect(labelsById['Fence'], equals(l10n.calculatorKeyFence));
    expect(labelsById['SIN'], equals(l10n.calculatorKeySin));
    expect(labelsById['Drywall'], equals(l10n.calculatorKeyDrywall));
  });

  testWidgets('a key belongs to the group whose id it names', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CalculatorPage(),
      ),
    );

    final keyboard = tester.widget<CoreKeyboard>(find.byType(CoreKeyboard));

    for (final group in keyboard.allGroups) {
      for (final key in group.keys) {
        expect(
          key.groupName,
          equals(group.name.id),
          reason: 'key ${key.id} should name its own group by id',
        );
      }
    }
  });

  testWidgets('the history placeholder is supplied from l10n', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CalculatorPage(),
      ),
    );

    final l10n = AppLocalizations.of(
      tester.element(find.byType(CoreDisplayArea)),
    )!;
    final displayArea = tester.widget<CoreDisplayArea>(
      find.byType(CoreDisplayArea),
    );

    expect(
      displayArea.historyPlaceholder,
      equals(l10n.calculatorHistoryPlaceholder),
    );
    expect(displayArea.closeSemanticLabel, equals(l10n.closeButton));
  });
}
