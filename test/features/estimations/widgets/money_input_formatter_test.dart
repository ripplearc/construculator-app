import 'package:construculator/features/estimation/presentation/bloc/equipment_cost_form_bloc/equipment_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/money_input_formatter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MoneyInputFormatter', () {
    late int limitCalls;
    late int refusedCalls;
    late MoneyInputFormatter formatter;
    Locale? locale;

    setUp(() {
      limitCalls = 0;
      refusedCalls = 0;
      locale = null;
      formatter = MoneyInputFormatter(
        largestAmount: largestMoneyAmount,
        onLimitReached: () => limitCalls++,
        onEditRefused: () => refusedCalls++,
        deviceLocale: () => locale,
      );
    });

    String after(String before, String typed) => formatter
        .formatEditUpdate(
          TextEditingValue(text: before),
          TextEditingValue(text: typed),
        )
        .text;

    test('the largest fee is the storyboard bound', () {
      expect(largestMoneyAmount, 999999.99);
    });

    test('accepts empty text, whole dollars and up to two decimals', () {
      expect(after('8', ''), '');
      expect(after('', '85'), '85');
      expect(after('85', '85.'), '85.');
      expect(after('85.', '85.5'), '85.5');
      expect(after('85.5', '85.55'), '85.55');
      expect(after('', '.5'), '.5');
    });

    test('accepts a lone decimal point, which the form reads as no fee', () {
      expect(after('.5', '.'), '.');
      expect(limitCalls, 0);
    });

    test('accepts exactly the largest fee', () {
      expect(after('999999.9', '999999.99'), '999999.99');
      expect(limitCalls, 0);
    });

    test('refuses amounts above the largest fee and reports each one', () {
      expect(after('99999.99', '1000000'), '99999.99');
      expect(after('999999', '9999999'), '999999');
      expect(after('999999.9', '1000000.9'), '999999.9');
      expect(limitCalls, 3);
    });

    test('refuses a third decimal and reports each one', () {
      expect(after('85.55', '85.555'), '85.55');
      expect(after('999999.99', '999999.991'), '999999.99');
      expect(after('.55', '.555'), '.55');
      expect(limitCalls, 3);
    });

    test('refuses letters, signs and a second decimal point and says so', () {
      expect(after('85', '85a'), '85');
      expect(after('85', '-85'), '85');
      expect(after('8.5', '8.5.'), '8.5');
      expect(after('8.5', '8.5.5'), '8.5');
      expect(after('', 'USD 85'), '');
      expect(after('', '€12,50'), '');
      expect(limitCalls, 0);
      expect(refusedCalls, 6);
    });

    test('removes the dollar sign, spaces and real thousands commas', () {
      expect(after('', r'$1,250.00'), '1250.00');
      expect(after('', '1,250.00'), '1250.00');
      expect(after('', '123,456'), '123456');
      expect(after('', '12,345'), '12345');
      expect(after('', ' 85'), '85');
      expect(after('', r'$ '), '');
      expect(refusedCalls, 0);
    });

    test('refuses a comma that is not a thousands mark and says so', () {
      expect(after('', '12,50'), '');
      expect(after('', '8,5'), '');
      expect(after('', '1 250,00'), '');
      expect(after('', '1,25'), '');
      expect(after('85', '85,'), '85');
      expect(refusedCalls, 5);
      expect(limitCalls, 0);
    });

    test('drops a dollar sign or a space typed alone without a message', () {
      expect(after('85', r'85$'), '85');
      expect(after('85', '85 '), '85');
      expect(refusedCalls, 0);
    });

    test('keeps the caret where the user put it when nothing is cleaned', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: '15'),
        const TextEditingValue(
          text: '185',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );

      expect(result.selection, const TextSelection.collapsed(offset: 2));
    });

    test('puts the caret at the end of a cleaned paste', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        const TextEditingValue(
          text: r'$1,250.00',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );

      expect(result.text, '1250.00');
      expect(result.selection, const TextSelection.collapsed(offset: 7));
    });

    test('reads the comma as the decimal point on a decimal-comma phone', () {
      locale = const Locale('de', 'DE');
      expect(after('8', '8,'), '8.');
      expect(after('8.', '8.5'), '8.5');
      expect(after('', '8,50'), '8.50');
      expect(after('', r'$1.250,00'), '1250.00');
      expect(after('8.5', '8.55'), '8.55');
    });

    test(
      'a comma typed after a decimal point is refused, not read as a paste',
      () {
        locale = const Locale('de', 'DE');
        expect(after('8.5', '8.5,'), '8.5');
        expect(after('8', '8,'), '8.');
        expect(limitCalls, 0);
      },
    );

    test('on a decimal-comma phone, only the pasted part is cleaned', () {
      locale = const Locale('de', 'DE');
      expect(after('8.5', '8.5,5'), '8.5');
      expect(after('12', '123,5'), '123.5');
      expect(after('8', '81.250'), '81250');
      expect(refusedCalls, 1);
    });

    test('on a decimal-comma phone, a point-only thousands group is read', () {
      locale = const Locale('de', 'DE');
      expect(after('', '1.250'), '1250');
      expect(after('', '123.456'), '123456');
      expect(after('', '8.5'), '8.5');
      expect(limitCalls, 0);
    });

    test('on a decimal-comma phone, a US-style amount is read as one', () {
      locale = const Locale('de', 'DE');
      expect(after('', '1,250.00'), '1250.00');
      expect(limitCalls, 0);
      expect(refusedCalls, 0);
    });

    test(
      'on a decimal-point phone, a comma pasted after digits can join a group',
      () {
        expect(after('1', '1,250'), '1250');
        expect(after('1', '1,25'), '1');
        expect(refusedCalls, 1);
      },
    );

    test('refuses a third decimal after the comma is read', () {
      locale = const Locale('de', 'DE');
      expect(after('8.55', '8.555'), '8.55');
      expect(limitCalls, 1);
    });

    test('reads a locale with no number symbols as a decimal point', () {
      locale = const Locale('xx');
      expect(after('', '8,50'), '');
      expect(refusedCalls, 1);
    });

    test('has no ceiling of its own unless it is given one', () {
      final unbounded = MoneyInputFormatter(onLimitReached: () => limitCalls++);
      final result = unbounded.formatEditUpdate(
        const TextEditingValue(text: '999999.99'),
        const TextEditingValue(text: '9999999.99'),
      );
      expect(result.text, '9999999.99');
      expect(limitCalls, 0);
    });
  });
}
