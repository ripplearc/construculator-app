import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Token', () {
    group('isComplete', () {
      test('is true once digits have a unit and no open fraction', () {
        const token = Token(digits: '22', unit: Unit.foot);
        expect(token.isComplete, isTrue);
        expect(token.power, 1);
      });

      test('is false while the number is still open', () {
        expect(const Token(digits: '22').isComplete, isFalse);
      });

      test('is false with a unit but no digits', () {
        expect(const Token(digits: '', unit: Unit.foot).isComplete, isFalse);
      });

      test('is false while [/] waits for its denominator', () {
        const token = Token(digits: '7', denominator: '', unit: Unit.inch);
        expect(token.isComplete, isFalse);
      });

      test('is true for a finished fraction', () {
        const token = Token(digits: '7', denominator: '16', unit: Unit.inch);
        expect(token.isComplete, isTrue);
      });
    });

    group('value', () {
      test('reads the digits as a number', () {
        expect(const Token(digits: '0.1184', unit: Unit.metre).value, 0.1184);
      });

      test('divides by the denominator of a fraction', () {
        const token = Token(digits: '7', denominator: '16', unit: Unit.inch);
        expect(token.value, 7 / 16);
      });

      test('is zero while nothing has been typed', () {
        expect(const Token(digits: '').value, 0);
      });

      test('ignores a denominator that is still empty', () {
        expect(const Token(digits: '7', denominator: '').value, 7);
      });

      test('has no finite value for a zero denominator', () {
        const token = Token(digits: '7', denominator: '0', unit: Unit.inch);
        expect(token.isComplete, isTrue);
        expect(token.value, double.infinity);
        expect(token.value.isFinite, isFalse);
      });
    });

    group('copyWith', () {
      const token = Token(
        digits: '4',
        denominator: '16',
        unit: Unit.inch,
        power: 2,
      );

      test('replaces the given fields and keeps the rest', () {
        final raised = token.copyWith(digits: '5', power: 3);
        expect(
          raised,
          const Token(
            digits: '5',
            denominator: '16',
            unit: Unit.inch,
            power: 3,
          ),
        );
      });

      test('can clear the unit and the denominator to null', () {
        final reopened = token.copyWith(
          unit: () => null,
          denominator: () => null,
        );
        expect(reopened, const Token(digits: '4', power: 2));
        expect(reopened.isComplete, isFalse);
      });

      test('can set a new unit', () {
        expect(token.copyWith(unit: () => Unit.foot).unit, Unit.foot);
      });
    });

    test('refuses a power above cubic', () {
      expect(
        () => Token(digits: '1', unit: Unit.foot, power: 4),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
