import 'package:equatable/equatable.dart';

/// Thrown when a rational would need more than [Rational.maxMagnitude] in
/// its numerator or denominator, which is the engine's "too large to keep"
/// (the same refusal as a length beyond the tick limit).
class RationalOverflow implements Exception {
  const RationalOverflow();
}

/// An exact fraction of two integers, the number a typed length is kept
/// as (UX Design Doc Section 6, "Precision and storage": every typed length
/// is stored exactly as typed).
///
/// Two rationals are equal when they name the same number, whatever form
/// they were written in: `Rational(2520, 64)` equals `Rational(315, 8)`,
/// which lets a `const` length built from ticks compare with one built
/// from a typed decimal. Every arithmetic result is reduced; a result whose
/// numerator or denominator would pass [maxMagnitude], the last whole
/// number a double still holds exactly, is a [RationalOverflow] rather than
/// a wrong number.
class Rational extends Equatable implements Comparable<Rational> {
  /// The largest numerator or denominator a rational may carry: 2⁵³.
  static const int maxMagnitude = 1 << 53;

  /// Zero.
  static const Rational zero = Rational(0);

  /// The numerator as written; the sign of the number lives here.
  final int numerator;

  /// The denominator as written, always positive.
  final int denominator;

  const Rational(this.numerator, [this.denominator = 1])
    : assert(denominator > 0, 'a denominator is positive');

  /// The exact value of a decimal written as text, "17.32" or "0.1" or
  /// "-3"; `null` when [text] is not a plain decimal or is too long to
  /// keep. The shortest decimal spelling of a double, which is what a
  /// typed number parses back to, is always exact here.
  static Rational? tryParse(String text) {
    final match = RegExp(r'^(-?)(\d*)(?:\.(\d*))?$').firstMatch(text.trim());
    if (match == null) return null;
    final whole = match.group(2) ?? '';
    final fraction = match.group(3) ?? '';
    if (whole.isEmpty && fraction.isEmpty) return null;
    final digits = int.tryParse('$whole$fraction');
    if (digits == null) return null;
    final scale = _powerOfTen(fraction.length);
    if (scale == null || digits > maxMagnitude) return null;
    final signed = match.group(1) == '-' ? -digits : digits;
    return Rational(signed, scale).reduced;
  }

  /// This number in lowest terms, with the sign on the numerator.
  Rational get reduced {
    final divisor = _gcd(numerator.abs(), denominator);
    if (divisor <= 1) return this;
    return Rational(numerator ~/ divisor, denominator ~/ divisor);
  }

  /// Whether this is a whole number.
  bool get isWhole => numerator % denominator == 0;

  /// Whether this is zero.
  bool get isZero => numerator == 0;

  /// The nearest double.
  double toDouble() => numerator / denominator;

  /// The nearest whole number, a half rounded toward +∞ as the prototype's
  /// `Math.round` does.
  int round() {
    final floor =
        numerator ~/ denominator -
        (numerator % denominator != 0 && numerator < 0 ? 1 : 0);
    final remainder = numerator - floor * denominator;
    return 2 * remainder >= denominator ? floor + 1 : floor;
  }

  /// The largest whole number at or below this one.
  int floor() {
    final quotient = numerator ~/ denominator;
    return numerator < 0 && numerator % denominator != 0
        ? quotient - 1
        : quotient;
  }

  /// This plus [other].
  Rational operator +(Rational other) => _checked(
    numerator * other.denominator + other.numerator * denominator,
    denominator * other.denominator,
  );

  /// This minus [other].
  Rational operator -(Rational other) => _checked(
    numerator * other.denominator - other.numerator * denominator,
    denominator * other.denominator,
  );

  /// This times [other].
  Rational operator *(Rational other) =>
      _checked(numerator * other.numerator, denominator * other.denominator);

  /// This divided by [other]; dividing by zero is an [ArgumentError], the
  /// caller's to refuse before it gets here.
  Rational operator /(Rational other) {
    if (other.isZero) throw ArgumentError.value(other, 'other', 'is zero');
    final sign = other.numerator < 0 ? -1 : 1;
    return _checked(
      numerator * other.denominator * sign,
      denominator * other.numerator.abs(),
    );
  }

  /// This number negated.
  Rational operator -() => Rational(-numerator, denominator);

  @override
  int compareTo(Rational other) =>
      (numerator * other.denominator).compareTo(other.numerator * denominator);

  @override
  List<Object?> get props {
    final lowest = reduced;
    return [lowest.numerator, lowest.denominator];
  }

  @override
  String toString() =>
      denominator == 1 ? '$numerator' : '$numerator/$denominator';

  Rational _checked(int numerator, int denominator) {
    final result = Rational(numerator, denominator).reduced;
    if (result.numerator.abs() > maxMagnitude ||
        result.denominator > maxMagnitude) {
      throw const RationalOverflow();
    }
    return result;
  }

  static int _gcd(int a, int b) {
    var x = a;
    var y = b;
    while (y != 0) {
      final remainder = x % y;
      x = y;
      y = remainder;
    }
    return x;
  }

  static int? _powerOfTen(int exponent) {
    var scale = 1;
    for (var i = 0; i < exponent; i++) {
      scale *= 10;
      if (scale > maxMagnitude) return null;
    }
    return scale;
  }
}
