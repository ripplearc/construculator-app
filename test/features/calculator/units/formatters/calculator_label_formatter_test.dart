import 'package:construculator/features/calculator/presentation/bloc/calculator_bloc/calculator_bloc.dart';
import 'package:construculator/features/calculator/presentation/formatters/calculator_label_formatter.dart';
import 'package:construculator/l10n/generated/app_localizations_en.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
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

    test('a removed result is one sentence naming the result by its label', () {
      const toast = CalculatorResultRemovedToast(key: 'Arcsine');
      expect(labels.toastTitle(toast), isNull);
      expect(
        labels.toastBody(toast),
        l10n.calculatorToastResultRemoved(labels.displayLabel('Arcsine')),
      );
      expect(labels.toastBody(toast), contains('removed'));
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
