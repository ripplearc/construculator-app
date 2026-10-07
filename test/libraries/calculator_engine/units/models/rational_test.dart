import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Rational', () {
    test('equals another that names the same number', () {
      expect(const Rational(2520, 64), const Rational(315, 8));
      expect(
        const Rational(2520, 64).hashCode,
        const Rational(315, 8).hashCode,
      );
      expect(const Rational(1, 3), isNot(const Rational(1, 2)));
    });

    test('parses a decimal exactly', () {
      expect(Rational.tryParse('17.32'), const Rational(433, 25));
      expect(Rational.tryParse('0.1'), const Rational(1, 10));
      expect(Rational.tryParse('-3'), const Rational(-3));
      expect(Rational.tryParse('.5'), const Rational(1, 2));
      expect(Rational.tryParse('7.'), const Rational(7));
    });

    test('refuses what is not a decimal, or is too long to keep', () {
      expect(Rational.tryParse(''), isNull);
      expect(Rational.tryParse('.'), isNull);
      expect(Rational.tryParse('1e5'), isNull);
      expect(Rational.tryParse('1/2'), isNull);
      expect(Rational.tryParse('10000000000000000'), isNull);
      expect(Rational.tryParse('1.0000000000000000001'), isNull);
    });

    test('adds, subtracts, multiplies and divides exactly', () {
      const tenth = Rational(1, 10);
      var sum = Rational.zero;
      for (var i = 0; i < 1000; i++) {
        sum += tenth;
      }
      expect(sum, const Rational(100));
      expect(const Rational(1, 3) * const Rational(3), const Rational(1));
      expect(const Rational(5, 2) - const Rational(1, 2), const Rational(2));
      expect(const Rational(1) / const Rational(-4), const Rational(-1, 4));
      expect(-const Rational(1, 4), const Rational(-1, 4));
    });

    test('rounds a half toward +∞ and floors toward −∞', () {
      expect(const Rational(5, 2).round(), 3);
      expect(const Rational(-5, 2).round(), -2);
      expect(const Rational(7, 3).round(), 2);
      expect(const Rational(-7, 3).floor(), -3);
      expect(const Rational(7, 3).floor(), 2);
    });

    test('compares, tells a whole number and zero, and converts', () {
      expect(const Rational(1, 3).compareTo(const Rational(1, 2)), lessThan(0));
      expect(const Rational(6, 3).isWhole, isTrue);
      expect(const Rational(7, 3).isWhole, isFalse);
      expect(Rational.zero.isZero, isTrue);
      expect(const Rational(1, 4).toDouble(), 0.25);
      expect('${const Rational(6, 4).reduced}', '3/2');
      expect('${const Rational(6, 3).reduced}', '2');
    });

    test('a result past 2⁵³ is an overflow, not a wrong number', () {
      const huge = Rational(Rational.maxMagnitude);
      expect(() => huge * const Rational(2), throwsA(isA<RationalOverflow>()));
      expect(
        () => const Rational(1, Rational.maxMagnitude) / const Rational(2),
        throwsA(isA<RationalOverflow>()),
      );
    });

    test('dividing by zero is an ArgumentError', () {
      expect(() => const Rational(1) / Rational.zero, throwsArgumentError);
    });
  });
}
