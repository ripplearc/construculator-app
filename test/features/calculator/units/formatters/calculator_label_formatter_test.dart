import 'package:construculator/features/calculator/presentation/bloc/calculator_bloc/calculator_bloc.dart';
import 'package:construculator/features/calculator/presentation/formatters/calculator_label_formatter.dart';
import 'package:construculator/l10n/generated/app_localizations_en.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  group('CalculatorLabelFormatter.valueText', () {
    test('reads Error under an error chip and the state\'s text otherwise', () {
      final l10n = AppLocalizationsEn();
      final labels = CalculatorLabelFormatter(l10n);
      const five = ValueChip(
        entry: EntryBuffer([Token(digits: '5')]),
        isActive: false,
      );
      final failed = CalculatorState.initial().copyWith(
        tape: const Tape(
          chips: [five, ErrorChip(CalculationError.divisionByZero)],
        ),
      );
      expect(failed.valueReadsError, isTrue);
      expect(labels.valueText(failed), l10n.calculatorValueError);
      expect(labels.valueText(failed), 'Error');
      final typed = CalculatorState.initial().copyWith(
        tape: const Tape(chips: [five]),
      );
      expect(typed.valueReadsError, isFalse);
      expect(labels.valueText(typed), '5');
      final reopened = CalculatorState.initial().copyWith(
        tape: const Tape(
          chips: [
            five,
            ErrorChip(CalculationError.divisionByZero),
            ValueChip(operator: Operator.divide),
          ],
        ),
      );
      expect(
        reopened.valueReadsError,
        isTrue,
        reason: 'the divisor ÷ 0 reopened is empty, so the error still reads',
      );
      expect(labels.valueText(reopened), 'Error');
      final retyped = CalculatorState.initial().copyWith(
        tape: const Tape(
          chips: [
            five,
            ErrorChip(CalculationError.divisionByZero),
            ValueChip(
              operator: Operator.divide,
              entry: EntryBuffer([Token(digits: '2')]),
            ),
          ],
        ),
      );
      expect(retyped.valueReadsError, isFalse);
      expect(labels.valueText(retyped), '2');
    });

    test('reads no Error under a chip that is not the divisor ÷ 0 reopened: a '
        'key after an error chip, or a step inside a bracket that took the '
        'divisor\'s place', () {
      const five = ValueChip(
        entry: EntryBuffer([Token(digits: '5')]),
        isActive: false,
      );
      final width = CalculatorState.initial().copyWith(
        tape: const Tape(
          chips: [
            five,
            ErrorChip(CalculationError.dimensionError),
            ValueChip(key: 'Width'),
          ],
        ),
      );
      expect(width.valueReadsError, isFalse);
      final grouped = CalculatorState.initial().copyWith(
        tape: const Tape(
          chips: [
            five,
            ErrorChip(CalculationError.divisionByZero),
            BracketChip(
              operator: Operator.divide,
              inner: [
                ValueChip(
                  entry: EntryBuffer([Token(digits: '3')]),
                  isActive: false,
                ),
                ValueChip(operator: Operator.multiply),
              ],
              isOpen: true,
            ),
          ],
        ),
      );
      expect(grouped.valueReadsError, isFalse);
    });
  });

  group('CalculatorLabelFormatter toasts (Section 5)', () {
    final l10n = AppLocalizationsEn();
    final labels = CalculatorLabelFormatter(l10n);

    test('the editing guard is titled "Finish this value first" and names '
        'the incomplete number, or says the value is empty', () {
      const dangling = CalculatorFinishValueToast(value: '18');
      expect(labels.toastTitle(dangling), l10n.calculatorToastFinishValueTitle);
      expect(
        labels.toastBody(dangling),
        l10n.calculatorToastFinishValueBody('18'),
      );
      expect(labels.toastBody(dangling), contains("18 isn't complete"));

      const empty = CalculatorFinishValueToast(value: '');
      expect(labels.toastTitle(empty), l10n.calculatorToastFinishValueTitle);
      expect(labels.toastBody(empty), l10n.calculatorToastValueEmptyBody);
      expect(labels.toastBody(empty), contains('empty'));
    });

    test('⌫ on the emptied first chip reads as one sentence, the doc\'s', () {
      const toast = CalculatorTypeNewFirstValueToast();
      expect(labels.toastTitle(toast), isNull);
      expect(
        labels.toastBody(toast),
        'Type a new first value, or press C to start again.',
      );
    });

    test('a unit is spelled out by its engine id', () {
      expect(labels.unitName(Unit.yard), 'yards');
      expect(labels.unitName(Unit.pound), 'pounds');
      expect(labels.unitName(Unit.metricTon), 'metric tons');
      expect(labels.unitName(Unit.footInch), 'feet and inches');
    });

    test('every unit the engine knows is spelled out, none by its raw id', () {
      for (final unit in Unit.values) {
        expect(labels.unitName(unit), isNot(unit.name), reason: unit.name);
        expect(labels.unitName(unit), isNotEmpty, reason: unit.name);
      }
    });

    test('a unit key of the Unit group is named by its face, as the doc '
        'points at it ("Press ⌫ to remove Lbs"); a unit column key by its '
        'name', () {
      expect(labels.unitKeyFace(Unit.pound), l10n.calculatorKeyLbs);
      expect(labels.unitKeyFace(Unit.kilogram), l10n.calculatorKeyKg);
      expect(labels.unitKeyFace(Unit.ton), l10n.calculatorKeyTons);
      expect(labels.unitKeyFace(Unit.metricTon), l10n.calculatorKeyMetricTons);
      expect(labels.unitKeyFace(Unit.boardFoot), l10n.calculatorKeyBdFt);
      expect(labels.unitKeyFace(Unit.metre), l10n.calculatorKeyMetre);
      expect(labels.unitKeyFace(Unit.centimetre), l10n.calculatorKeyCentimetre);
      expect(labels.unitKeyFace(Unit.millimetre), l10n.calculatorKeyMillimetre);
      expect(labels.unitKeyFace(Unit.foot), labels.unitName(Unit.foot));
    });

    test('"Can\'t append <unit> here" is titled with the unit spelled out and '
        'says what cannot continue with it', () {
      const toast = CalculatorCannotAppendUnitToast(
        value: '18ft 8in 78',
        unit: Unit.yard,
      );
      expect(
        labels.toastTitle(toast),
        l10n.calculatorToastCannotAppendTitle('yards'),
      );
      expect(
        labels.toastBody(toast),
        l10n.calculatorToastCannotAppendBody('18ft 8in 78', 'yards'),
      );
      expect(labels.toastBody(toast), contains('steps down'));
    });

    test('"<Key> needs a length" names the key, and its body the unit to '
        'remove, or the tail a length unit would finish', () {
      const plain = CalculatorNeedsLengthToast(key: 'Width', unit: Unit.pound);
      expect(
        labels.toastTitle(plain),
        l10n.calculatorToastNeedsLengthTitle(l10n.calculatorKeyWidth),
      );
      expect(
        labels.toastBody(plain),
        l10n.calculatorToastNeedsLengthBody(l10n.calculatorKeyLbs),
      );
      expect(labels.toastBody(plain), contains('remove Lbs'));

      const tail = CalculatorNeedsLengthToast(
        key: 'Width',
        unit: Unit.kilogram,
        tail: '8',
      );
      expect(
        labels.toastBody(tail),
        l10n.calculatorToastTailNeedsLengthBody(
          l10n.calculatorKeyWidth,
          'kilograms',
          '8',
        ),
      );
    });

    test('"<Key> keeps <value>" says what the unit would make the value', () {
      const toast = CalculatorKeepsLengthToast(
        key: 'Width',
        unit: Unit.inch,
        value: '4in',
      );
      expect(
        labels.toastTitle(toast),
        l10n.calculatorToastKeepsLengthTitle(l10n.calculatorKeyWidth, '4in'),
      );
      expect(
        labels.toastBody(toast),
        l10n.calculatorToastKeepsLengthBody(
          'inches',
          '4in',
          l10n.calculatorKeyWidth,
        ),
      );
      expect(labels.toastBody(toast), contains('would make this 4in²'));
    });

    test('"Editing this group" is one sentence saying how to close it', () {
      const toast = CalculatorEditingGroupToast();
      expect(labels.toastTitle(toast), isNull);
      expect(labels.toastBody(toast), l10n.calculatorToastEditingGroup);
      expect(labels.toastBody(toast), contains('Press ( ) to close it'));
    });

    test('a removed result is one sentence naming the result by its label', () {
      const toast = CalculatorResultRemovedToast(keys: ['Arcsine']);
      expect(labels.toastTitle(toast), isNull);
      expect(
        labels.toastBody(toast),
        l10n.calculatorToastResultRemoved(labels.displayLabel('Arcsine')),
      );
      expect(labels.toastBody(toast), contains('removed'));
    });

    test('two removed results are both named, and more than two the first '
        'and how many more (Section 5.5)', () {
      const two = CalculatorResultRemovedToast(keys: ['Diagonal', 'Calc']);
      expect(
        labels.toastBody(two),
        l10n.calculatorToastResultsRemovedBoth(
          labels.displayLabel('Diagonal'),
          labels.displayLabel('Calc'),
        ),
      );
      expect(labels.toastBody(two), contains('Diagonal and Calc removed'));
      const three = CalculatorResultRemovedToast(
        keys: ['Diagonal', 'Calc', 'Calc'],
      );
      expect(
        labels.toastBody(three),
        l10n.calculatorToastResultsRemovedMore(
          labels.displayLabel('Diagonal'),
          2,
        ),
      );
      expect(labels.toastBody(three), contains('and 2 more removed'));
    });
  });

  group('CalculatorLabelFormatter.localizeChips with a chip tap', () {
    final l10n = AppLocalizationsEn();
    final labels = CalculatorLabelFormatter(l10n);
    const chips = [
      CoreCalculatorChip(type: CoreCalculatorChipType.editable, value: '22ft'),
      CoreCalculatorChip(type: CoreCalculatorChipType.active, value: '18'),
      CoreCalculatorChip(type: CoreCalculatorChipType.result, value: '396ft²'),
      CoreCalculatorChip(type: CoreCalculatorChipType.dashed, value: '396ft²'),
    ];

    test('a value chip taps back with its own index; a result chip, dashed '
        'or not, takes no tap', () {
      final tapped = <int>[];
      final localized = labels.localizeChips(chips, onChipTap: tapped.add);

      localized[0].onTap!();
      localized[1].onTap!();
      expect(tapped, [0, 1]);
      expect(localized[2].onTap, isNull);
      expect(localized[3].onTap, isNull);
    });

    test('a finished chip says a tap edits it, the chip being typed or '
        'edited that a tap finishes the edit, and a result says nothing', () {
      final localized = labels.localizeChips(chips, onChipTap: (_) {});

      expect(localized[0].tapSemanticLabel, l10n.calculatorChipTapToEdit);
      expect(localized[1].tapSemanticLabel, l10n.calculatorChipTapToFinish);
      expect(
        localized[1].tapSemanticLabel,
        isNot(equals(localized[0].tapSemanticLabel)),
      );
      expect(localized[2].tapSemanticLabel, isNull);
      expect(localized[3].tapSemanticLabel, isNull);
    });

    test('a bracket chip taps back too: a closed one says a tap edits it, '
        'the open one that a tap closes it (Section 7)', () {
      final tapped = <int>[];
      final localized = labels.localizeChips(const [
        CoreCalculatorChip(
          type: CoreCalculatorChipType.bracketClosed,
          value: '3×4',
        ),
        CoreCalculatorChip(
          type: CoreCalculatorChipType.bracketOpen,
          value: '3×',
        ),
      ], onChipTap: tapped.add);

      localized[0].onTap!();
      localized[1].onTap!();
      expect(tapped, [0, 1]);
      expect(localized[0].tapSemanticLabel, l10n.calculatorChipTapToEdit);
      expect(localized[1].tapSemanticLabel, l10n.calculatorChipTapToClose);
      expect(
        localized[1].tapSemanticLabel,
        isNot(equals(localized[0].tapSemanticLabel)),
      );
    });

    test('without a tap handler the chips keep their own taps and hints', () {
      final localized = labels.localizeChips(chips);

      expect(localized.map((chip) => chip.onTap), everyElement(isNull));
      expect(
        localized.map((chip) => chip.tapSemanticLabel),
        everyElement(isNull),
      );
    });
  });

  group('CalculatorLabelFormatter.localizeChips', () {
    test(
      'translates the label and carries every other field over as it is',
      () {
        final l10n = AppLocalizationsEn();
        final labels = CalculatorLabelFormatter(l10n);
        void onTap() {}
        void onLongPress() {}
        final chip = CoreCalculatorChip(
          key: const ValueKey('chip_width'),
          type: CoreCalculatorChipType.result,
          label: 'Width',
          value: '18ft 8in',
          factor: CoreIcons.cross,
          onTap: onTap,
          tapSemanticLabel: 'Edit the width',
          onLongPress: onLongPress,
          longPressSemanticLabel: 'Remove the width',
          semanticsLabel: 'Width 18 feet 8 inches',
          inert: true,
        );

        final localized = labels.localizeChips([chip]).single;

        expect(localized.label, l10n.calculatorKeyWidth);
        expect(localized.key, chip.key);
        expect(localized.type, chip.type);
        expect(localized.value, chip.value);
        expect(localized.factor, chip.factor);
        expect(localized.onTap, same(onTap));
        expect(localized.tapSemanticLabel, chip.tapSemanticLabel);
        expect(localized.onLongPress, same(onLongPress));
        expect(localized.longPressSemanticLabel, chip.longPressSemanticLabel);
        expect(localized.semanticsLabel, chip.semanticsLabel);
        expect(localized.inert, chip.inert);
      },
    );

    test('gives a bracket chip a worded screen-reader label, the open and '
        'the closed bracket apart, since the chip\'s own would read the same '
        'for both', () {
      final l10n = AppLocalizationsEn();
      final labels = CalculatorLabelFormatter(l10n);
      const open = CoreCalculatorChip(
        type: CoreCalculatorChipType.bracketOpen,
        value: '3×4',
      );
      const closed = CoreCalculatorChip(
        type: CoreCalculatorChipType.bracketClosed,
        value: '3×4',
      );

      final localized = labels.localizeChips([open, closed]);

      expect(
        localized[0].semanticsLabel,
        l10n.calculatorBracketOpenSemantics('3×4'),
      );
      expect(
        localized[1].semanticsLabel,
        l10n.calculatorBracketClosedSemantics('3×4'),
      );
      expect(
        localized[0].semanticsLabel,
        isNot(equals(localized[1].semanticsLabel)),
      );
    });

    test('a bracket led by an operator is read with it, as a value chip is, '
        'whichever of the four operators its factor draws', () {
      final l10n = AppLocalizationsEn();
      final labels = CalculatorLabelFormatter(l10n);
      const leads = {
        CoreIcons.addOperator: '+',
        CoreIcons.subtractOperator: '−',
        CoreIcons.multiplyOperator: '×',
        CoreIcons.divide: '÷',
      };

      for (final MapEntry(key: factor, value: symbol) in leads.entries) {
        final localized = labels.localizeChips([
          CoreCalculatorChip(
            type: CoreCalculatorChipType.bracketOpen,
            value: '3×4',
            factor: factor,
          ),
          CoreCalculatorChip(
            type: CoreCalculatorChipType.bracketClosed,
            value: '3×4',
            factor: factor,
          ),
        ]);

        expect(
          localized[0].semanticsLabel,
          '$symbol${l10n.calculatorBracketOpenSemantics('3×4')}',
          reason: 'open bracket after $symbol',
        );
        expect(
          localized[1].semanticsLabel,
          '$symbol${l10n.calculatorBracketClosedSemantics('3×4')}',
          reason: 'closed bracket after $symbol',
        );
      }
    });

    test('a bracket just opened, with nothing inside yet, is read with an '
        'empty inside rather than the word null', () {
      final l10n = AppLocalizationsEn();
      const open = CoreCalculatorChip(type: CoreCalculatorChipType.bracketOpen);

      final localized = CalculatorLabelFormatter(l10n).localizeChips([open]);

      expect(
        localized.single.semanticsLabel,
        l10n.calculatorBracketOpenSemantics(''),
      );
      expect(localized.single.semanticsLabel, isNot(contains('null')));
    });

    test('leaves a chip with no label unlabelled', () {
      final labels = CalculatorLabelFormatter(AppLocalizationsEn());
      const chip = CoreCalculatorChip(
        type: CoreCalculatorChipType.editable,
        value: '+(3×4)',
      );

      expect(labels.localizeChips([chip]).single.label, isNull);
    });
  });
}
