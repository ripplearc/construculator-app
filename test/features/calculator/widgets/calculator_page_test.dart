import 'package:construculator/features/calculator/presentation/bloc/calculator_bloc/calculator_bloc.dart';
import 'package:construculator/features/calculator/presentation/pages/calculator_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/l10n/generated/app_localizations_en.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
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

      // The engine's rules read named values by these exact ids
      // (DeterministicRules); renaming one here silently breaks its rule.
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
      'Run': l10n.calculatorKeyRun,
      'Rise': l10n.calculatorKeyRise,
      'Diag': l10n.calculatorKeyDiag,
      'Slope': l10n.calculatorKeySlope,
      'Diameter': l10n.calculatorKeyDiameter,
      'Radius': l10n.calculatorKeyRadius,
      'Sides': l10n.calculatorKeySides,
      'Chord': l10n.calculatorKeyChord,
      'Arc': l10n.calculatorKeyArc,
      'ColCon': l10n.calculatorKeyColCone,
      'Msnry': l10n.calculatorKeyMsnry,
      'Drywal': l10n.calculatorKeyDrywal,
      'Footng': l10n.calculatorKeyFootng,
      'Fence': l10n.calculatorKeyFence,
      'Qty@OC': l10n.calculatorKeyQtyAtOc,
      'Cost': l10n.calculatorKeyCost,
      'Weight': l10n.calculatorKeyWeight,
      'bf': l10n.calculatorKeyBdFt,
      'm': l10n.calculatorKeyMetre,
      'cm': l10n.calculatorKeyCentimetre,
      'mm': l10n.calculatorKeyMillimetre,
      'lbs': l10n.calculatorKeyLbs,
      'kg': l10n.calculatorKeyKg,
      'ton': l10n.calculatorKeyTons,
      'mton': l10n.calculatorKeyMetricTons,
      'SIN': l10n.calculatorKeySin,
      'COS': l10n.calculatorKeyCos,
      'TAN': l10n.calculatorKeyTan,
      'ASIN': l10n.calculatorKeyAsin,
      'ACOS': l10n.calculatorKeyAcos,
      'ATAN': l10n.calculatorKeyAtan,
      'DMS': l10n.calculatorKeyDms,
    };

    expect(labelsById.keys.toSet(), equals(expectedLabelById.keys.toSet()));
    for (final entry in expectedLabelById.entries) {
      expect(
        labelsById[entry.key],
        equals(entry.value),
        reason: 'key "${entry.key}" mapped to wrong label',
      );
    }
  });

  testWidgets(
    'the keyboard carries the prototype\'s five groups in its order',
    (tester) async {
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

      expect(
        [for (final group in keyboard.allGroups) group.name.label],
        equals([
          l10n.calculatorGroupBasicGeometry,
          l10n.calculatorGroupShapes,
          l10n.calculatorGroupMaterials,
          l10n.calculatorGroupUnit,
          l10n.calculatorGroupTrigonometry,
        ]),
      );
      expect([
        for (final group in keyboard.allGroups) group.keys.length,
      ], equals([8, 8, 7, 8, 7]));
      expect(keyboard.groupAccentColors, hasLength(5));
      expect(
        keyboard.groupAccentColors.keys.toSet(),
        equals({for (final group in keyboard.allGroups) group.name}),
      );
    },
  );

  testWidgets('a group is coloured by its id, not by its position', (
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

    final colors = theme.coreColors;
    final keyboard = tester.widget<CoreKeyboard>(find.byType(CoreKeyboard));
    final accentsById = {
      for (final entry in keyboard.groupAccentColors.entries)
        entry.key.id: entry.value,
    };

    expect(
      accentsById,
      equals({
        'Basic Geometry': colors.keyboardFunctions,
        'Shapes': colors.indigo,
        'Materials': colors.iconOrange,
        'Unit': colors.keyboardUnits,
        'Trigonometry': colors.textSuccess,
      }),
    );
  });

  testWidgets('an abbreviated key hands its full name to the keyboard', (
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
    final semanticsById = {
      for (final group in keyboard.allGroups)
        for (final key in group.keys) key.id: key.semanticLabel,
    };
    final facesById = {
      for (final group in keyboard.allGroups)
        for (final key in group.keys) key.id: key.label,
    };

    expect(semanticsById['Msnry'], equals(l10n.calculatorKeyMsnryFullName));
    expect(semanticsById['Drywal'], equals(l10n.calculatorKeyDrywalFullName));
    expect(semanticsById['Qty@OC'], equals(l10n.calculatorKeyQtyAtOcFullName));
    expect(semanticsById['bf'], equals(l10n.calculatorKeyBdFtFullName));
    expect(semanticsById['DMS'], equals(l10n.calculatorKeyDmsFullName));
    expect(semanticsById['Width'], isNull);
    expect(semanticsById['Fence'], isNull);
    expect(semanticsById['ton'], isNull);
    final abbreviated = semanticsById.entries.where((e) => e.value != null);
    expect(abbreviated, hasLength(20));
    for (final entry in abbreviated) {
      expect(
        entry.value,
        isNot(equals(facesById[entry.key])),
        reason: entry.key,
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
      ..add(const CalculatorDigitPressed('2'))
      ..add(const CalculatorUnitSelected(Unit.foot))
      ..add(const CalculatorOperatorPressed(Operator.multiply))
      ..add(const CalculatorDigitPressed('3'))
      ..add(const CalculatorEqualsPressed());
    await tester.pump();

    // The running total lands as a Calc chip, which reaches the display as a
    // result rather than a key and so has no entry on the keyboard.
    final displayArea = tester.widget<CoreDisplayArea>(
      find.byType(CoreDisplayArea),
    );

    expect(displayArea.label, equals(l10n.calculatorResultCalc));
    expect(displayArea.value, equals('6ft 0in'));
    expect(displayArea.dependentKeys, isEmpty);
  });

  testWidgets('an error chip is titled from the localization layer', (
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
      ..add(const CalculatorDigitPressed('7'))
      ..add(const CalculatorDigitPressed('8'))
      ..add(const CalculatorKeySelected('lbs'))
      ..add(const CalculatorOperatorPressed(Operator.divide))
      ..add(const CalculatorDigitPressed('1'))
      ..add(const CalculatorDigitPressed('2'))
      ..add(const CalculatorUnitSelected(Unit.foot))
      ..add(const CalculatorEqualsPressed());
    await tester.pump();

    final displayArea = tester.widget<CoreDisplayArea>(
      find.byType(CoreDisplayArea),
    );
    expect(displayArea.label, equals(l10n.calculatorErrorDimension));
    expect(displayArea.chipsList.last.label, l10n.calculatorErrorDimension);
  });

  testWidgets('a division by zero is titled from the localization layer', (
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
      ..add(const CalculatorDigitPressed('5'))
      ..add(const CalculatorOperatorPressed(Operator.divide))
      ..add(const CalculatorDigitPressed('0'))
      ..add(const CalculatorEqualsPressed());
    await tester.pump();

    final displayArea = tester.widget<CoreDisplayArea>(
      find.byType(CoreDisplayArea),
    );
    final labels = displayArea.chipsList.map((chip) => chip.label);
    expect(labels, contains(l10n.calculatorErrorDivisionByZero));
    expect(labels, isNot(contains(CalculationError.divisionByZero.name)));
  });

  testWidgets('a result past the limit is titled Too large from the '
      'localization layer', (tester) async {
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
    final bloc = BlocProvider.of<CalculatorBloc>(context);
    for (final digit in '9999999'.split('')) {
      bloc.add(CalculatorDigitPressed(digit));
    }
    bloc.add(const CalculatorUnitSelected(Unit.foot));
    for (final factor in const ['9999999', '9999999']) {
      bloc.add(const CalculatorOperatorPressed(Operator.multiply));
      for (final digit in factor.split('')) {
        bloc.add(CalculatorDigitPressed(digit));
      }
    }
    bloc.add(const CalculatorEqualsPressed());
    await tester.pump();

    final displayArea = tester.widget<CoreDisplayArea>(
      find.byType(CoreDisplayArea),
    );
    expect(displayArea.label, equals(l10n.calculatorErrorTooLarge));
    expect(displayArea.chipsList.last.label, l10n.calculatorErrorTooLarge);
  });

  test('a pill is drawn as the kind its id names', () {
    final l10n = AppLocalizationsEn();

    final toggle = CalculatorPage.pillFor(
      l10n,
      DependentKeyId.shownAs,
      'in/12in',
    );
    final editable = CalculatorPage.pillFor(l10n, DependentKeyId.rate, '4.5');

    expect(toggle.kind, equals(CoreDependentKeyKind.toggle));
    expect(toggle.label, equals(l10n.calculatorPillShownAs));
    expect(toggle.value, equals('in/12in'));
    expect(editable.kind, equals(CoreDependentKeyKind.editable));
  });

  testWidgets(
    'every dependent-key pill has a name from the localization layer',
    (tester) async {
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
      final expectedLabelById = <DependentKeyId, String>{
        DependentKeyId.onCentre: l10n.calculatorPillOnCentre,
        DependentKeyId.sheetSize: l10n.calculatorPillSheetSize,
        DependentKeyId.pieceSize: l10n.calculatorPillPieceSize,
        DependentKeyId.crossSection: l10n.calculatorPillCrossSection,
        DependentKeyId.railsPerSection: l10n.calculatorPillRailsPerSection,
        DependentKeyId.rate: l10n.calculatorPillRate,
        DependentKeyId.waste: l10n.calculatorPillWaste,
        DependentKeyId.density: l10n.calculatorPillDensity,
        DependentKeyId.shownAs: l10n.calculatorPillShownAs,
        DependentKeyId.across: l10n.calculatorPillAcross,
      };

      expect(
        expectedLabelById.keys.toSet(),
        equals(DependentKeyId.values.toSet()),
      );
      for (final entry in expectedLabelById.entries) {
        expect(
          CalculatorPage.pillLabelFor(l10n, entry.key),
          equals(entry.value),
          reason: 'pill ${entry.key.name} mapped to wrong label',
        );
        expect(entry.value, isNotEmpty);
      }
      expect(
        expectedLabelById.values.toSet(),
        hasLength(DependentKeyId.values.length),
      );
    },
  );
}
