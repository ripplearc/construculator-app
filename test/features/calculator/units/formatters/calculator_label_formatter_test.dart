import 'package:construculator/features/calculator/presentation/formatters/calculator_label_formatter.dart';
import 'package:construculator/l10n/generated/app_localizations_en.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
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
