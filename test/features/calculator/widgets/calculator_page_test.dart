import 'package:construculator/features/calculator/presentation/bloc/calculator_bloc/calculator_bloc.dart';
import 'package:construculator/features/calculator/presentation/pages/calculator_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    // Pinning every pair here means a new key without an ARB entry, or a
    // swapped id-to-label mapping, fails.
    final expectedLabelById = <String, String>{
      'Width': l10n.calculatorKeyWidth,
      'Length': l10n.calculatorKeyLength,
      'Height': l10n.calculatorKeyHeight,
      'Pitch': l10n.calculatorKeyPitch,
      'Circle': l10n.calculatorKeyCircle,
      'Rise': l10n.calculatorKeyRise,
      'Run': l10n.calculatorKeyRun,
      'Radius': l10n.calculatorKeyRadius,
      'Lbs': l10n.calculatorKeyLbs,
      'Kg': l10n.calculatorKeyKg,
      'Tons': l10n.calculatorKeyTons,
      'Drywall': l10n.calculatorKeyDrywall,
      'Fence': l10n.calculatorKeyFence,
      'SIN': l10n.calculatorKeySin,
      'COS': l10n.calculatorKeyCos,
      'TAN': l10n.calculatorKeyTan,
    };

    expect(labelsById.keys, containsAll(expectedLabelById.keys));
    for (final entry in expectedLabelById.entries) {
      expect(
        labelsById[entry.key],
        equals(entry.value),
        reason: 'key "${entry.key}" mapped to wrong label',
      );
    }
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

  testWidgets('the result label is translated on its way to the display', (
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

    final context = tester.element(find.byType(CoreDisplayArea));
    final l10n = AppLocalizations.of(context)!;
    BlocProvider.of<CalculatorBloc>(context)
      ..add(const CalculatorKeySelected('Length'))
      ..add(const CalculatorDigitPressed('2'))
      ..add(const CalculatorDigitPressed('4'))
      ..add(const CalculatorKeySelected('Fence'));
    await tester.pump();

    // Fence resolves to the 'Posts' result label, which reaches the display as
    // a result rather than a key and so has no entry on the keyboard.
    final displayArea = tester.widget<CoreDisplayArea>(
      find.byType(CoreDisplayArea),
    );

    expect(displayArea.label, equals(l10n.calculatorResultPosts));
  });
}
