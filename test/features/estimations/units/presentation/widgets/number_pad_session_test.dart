import 'package:construculator/features/estimation/presentation/widgets/number_pad_session.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final _rateFormatter = TextInputFormatter.withFunction((previous, next) {
  final text = next.text.replaceAll(',', '.');
  return RegExp(r'^\d{0,9}(\.\d{0,2})?$').hasMatch(text)
      ? next.copyWith(text: text)
      : previous;
});

void main() {
  late TextEditingController controller;
  late List<String> reported;

  NumberPadSession open(String text, {TextSelection? selection}) {
    controller.value = TextEditingValue(
      text: text,
      selection: selection ?? TextSelection.collapsed(offset: text.length),
    );
    return NumberPadSession(
      controller: controller,
      formatter: _rateFormatter,
      onChanged: reported.add,
    );
  }

  setUp(() {
    controller = TextEditingController();
    reported = [];
  });

  tearDown(() => controller.dispose());

  group('NumberPadSession', () {
    test('types digits after the caret and reports every change', () {
      final session = open('');

      session.typeDigit(2);
      session.typeDigit(5);

      expect(controller.text, '25');
      expect(controller.selection, const TextSelection.collapsed(offset: 2));
      expect(reported, ['2', '25']);
    });

    test('replaces a selected value with the digit typed', () {
      final session = open(
        '3',
        selection: const TextSelection(baseOffset: 0, extentOffset: 1),
      );

      session.typeDigit(2);

      expect(controller.text, '2');
      expect(controller.selection, const TextSelection.collapsed(offset: 1));
      expect(reported, ['2']);
    });

    test('inserts at a caret in the middle of the value', () {
      final session = open(
        '15',
        selection: const TextSelection.collapsed(offset: 1),
      );

      session.typeDigit(2);

      expect(controller.text, '125');
      expect(controller.selection, const TextSelection.collapsed(offset: 2));
    });

    test('types at the end of a field whose selection was never set', () {
      controller.text = '4';
      final session = NumberPadSession(
        controller: controller,
        formatter: _rateFormatter,
        onChanged: reported.add,
      );

      session.typeDigit(0);

      expect(controller.text, '40');
      expect(controller.selection, const TextSelection.collapsed(offset: 2));
    });

    test('adds one decimal point and refuses a second', () {
      final session = open('1');

      session.typeDecimal();
      session.typeDecimal();

      expect(controller.text, '1.');
      expect(reported, ['1.']);
    });

    test(
      'refuses a digit the formatter does not allow and reports nothing',
      () {
        final session = open('1.25');

        session.typeDigit(9);

        expect(controller.text, '1.25');
        expect(controller.selection, const TextSelection.collapsed(offset: 4));
        expect(reported, isEmpty);
      },
    );

    test('refuses a tenth whole digit', () {
      final session = open('123456789');

      session.typeDigit(0);

      expect(controller.text, '123456789');
      expect(reported, isEmpty);
    });

    test('rejects a key outside 0 to 9', () {
      final session = open('');

      expect(() => session.typeDigit(10), throwsAssertionError);
      expect(() => session.typeDigit(-1), throwsAssertionError);
    });

    group('backspace', () {
      test('deletes the selection', () {
        final session = open(
          '125',
          selection: const TextSelection(baseOffset: 0, extentOffset: 2),
        );

        session.backspace();

        expect(controller.text, '5');
        expect(controller.selection, const TextSelection.collapsed(offset: 0));
        expect(reported, ['5']);
      });

      test('deletes the character before the caret', () {
        final session = open(
          '125',
          selection: const TextSelection.collapsed(offset: 2),
        );

        session.backspace();

        expect(controller.text, '15');
        expect(controller.selection, const TextSelection.collapsed(offset: 1));
        expect(reported, ['15']);
      });

      test(
        'deletes the last character of a field whose selection was never set',
        () {
          controller.text = '125';
          final session = NumberPadSession(
            controller: controller,
            formatter: _rateFormatter,
            onChanged: reported.add,
          );

          session.backspace();

          expect(controller.text, '12');
          expect(reported, ['12']);
        },
      );

      test('does nothing with the caret at the start', () {
        final session = open(
          '125',
          selection: const TextSelection.collapsed(offset: 0),
        );

        session.backspace();

        expect(controller.text, '125');
        expect(reported, isEmpty);
      });

      test('does nothing on an empty field', () {
        final session = open('');

        session.backspace();

        expect(controller.text, '');
        expect(reported, isEmpty);
      });
    });

    group('putBack', () {
      test('restores the value held when the pad opened and reports it', () {
        final session = open(
          '10',
          selection: const TextSelection(baseOffset: 0, extentOffset: 2),
        );
        session.typeDigit(2);
        session.typeDigit(5);

        session.putBack();

        expect(session.openedWith, '10');
        expect(controller.text, '10');
        expect(controller.selection, const TextSelection.collapsed(offset: 2));
        expect(reported, ['2', '25', '10']);
      });

      test('clears a field that was empty when the pad opened', () {
        final session = open('');
        session.typeDigit(7);

        session.putBack();

        expect(controller.text, '');
        expect(controller.selection, const TextSelection.collapsed(offset: 0));
        expect(reported, ['7', '']);
      });

      test('reports the opened value even when nothing was typed', () {
        final session = open('10');

        session.putBack();

        expect(controller.text, '10');
        expect(reported, ['10']);
      });
    });
  });
}
