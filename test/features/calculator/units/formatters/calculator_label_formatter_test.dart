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
