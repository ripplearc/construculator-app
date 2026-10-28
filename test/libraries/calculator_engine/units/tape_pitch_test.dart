import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const formatter = QuantityFormatter();
  const rules = DeterministicRules();

  Tape changed(TapeOutcome outcome) {
    if (outcome case TapeChanged(:final tape)) return tape;
    throw StateError('expected the tape to change, got $outcome');
  }

  TapeOutcome pressKey(Tape tape, String key) => switch (key) {
    'SIN' => tape.pressTrigKey(TrigFunction.sine),
    'ATAN' => tape.pressTrigKey(TrigFunction.arctangent),
    '÷' => tape.pressOperator(Operator.divide),
    'pill' => tape.cyclePitchSpelling(),
    'ft' => tape.pressUnit(Unit.foot, holdsLengthOnly: true),
    'in' => tape.pressUnit(Unit.inch, holdsLengthOnly: true),
    '×' => tape.pressOperator(Operator.multiply),
    '=' => tape.pressEquals(),
    _ when key.startsWith('[') => tape.pressFunctionKey(
      key.substring(1, key.length - 1),
      keyWantsUnit: !PlainNumberKeys.all.contains(
        key.substring(1, key.length - 1),
      ),
      readsDegrees: key == '[${PlainNumberKeys.pitch}]',
    ),
    _ => tape.typeDigit(key),
  };

  Tape press(Tape tape, String keys) {
    var current = tape;
    for (final key in keys.split(' ')) {
      current = changed(pressKey(current, key));
    }
    return current;
  }

  List<String> texts(Tape tape) => [
    for (final chip in tape.chips)
      switch (chip) {
        ValueChip(:final key, :final entry) => '${key ?? ''}${entry.text}',
        ResultChip(:final key, :final value) =>
          '$key ${formatter.format(value)}',
        ErrorChip(:final error) => error.name,
        BracketChip(:final expression) => expression,
      },
  ];

  String lastResult(Tape tape) => texts(tape).last;

  List<String> strip(Tape tape) => [
    for (final answer in rules.answersFor(tape.namedValues))
      '${answer.key}: ${formatter.format(answer.value)}',
  ];

  group('Pitch and slope grammar (F3)', () {
    group('[Pitch] asks, then cycles (walkthrough 17.2)', () {
      test('S39: Rise 8ft over Run 6ft lands 16in/12in, and each press '
          'cycles without recomputing', () {
        var tape = press(const Tape(), '[Rise] 8 ft [Run] 6 ft');
        expect(strip(tape).first, 'Pitch-rise per 12in run: 16in/12in');
        tape = press(tape, '[Pitch]');
        expect(texts(tape), [
          'Rise8ft',
          'Run6ft',
          'Pitch-rise per 12in run 16in/12in',
        ]);
        expect(tape.active, isNull);
        tape = press(tape, 'pill');
        expect(lastResult(tape), 'Pitch-degrees 53.13°');
        tape = press(tape, '[Pitch]');
        expect(lastResult(tape), 'Pitch-grade 133.3%');
        tape = press(tape, '[Pitch]');
        expect(lastResult(tape), 'Pitch-rise per 12in run 16in/12in');
        expect(tape.chips, hasLength(3), reason: 'one ratio, three spellings');
      });

      test('S42: a slope entry gets the same ask-then-cycle duty', () {
        var tape = press(const Tape(), '[Slope] 7');
        expect(strip(tape), [
          'Pitch-rise per 12in run: 13/16in/12in',
          'Pitch-degrees: 4°',
        ]);
        tape = press(tape, '[Pitch]');
        expect(lastResult(tape), 'Pitch-rise per 12in run 13/16in/12in');
        tape = press(tape, '[Pitch]');
        expect(lastResult(tape), 'Pitch-degrees 4°');
        tape = press(tape, '[Pitch]');
        expect(lastResult(tape), 'Pitch-grade 7%');
      });

      test('S84: a bare number into [Pitch] is degrees, and [Pitch] asks the '
          'trade form, then cycles back to what was typed', () {
        var tape = press(const Tape(), '[Pitch] 2 6 . 5 7');
        expect(strip(tape), [
          'Pitch-degrees: 26.57°',
          'Pitch-rise per 12in run: 6in/12in',
          'Pitch-grade: 50%',
        ]);
        tape = press(tape, '[Pitch]');
        expect(lastResult(tape), 'Pitch-rise per 12in run 6in/12in');
        tape = press(tape, '[Pitch]');
        expect(lastResult(tape), 'Pitch-degrees 26.57°');
      });

      test('with nothing to ask, [Pitch] opens a chip as any key does', () {
        expect(texts(press(const Tape(), '[Pitch]')), ['Pitch']);
        expect(texts(press(const Tape(), '[Width] 8 ft [Pitch]')), [
          'Width8ft',
          'Pitch',
        ]);
        expect(
          texts(press(const Tape(), '3 8 SIN [Pitch]')),
          ['Sine38', 'Sine 0.615661', 'Pitch'],
          reason: 'a finished trig lookup holds no pitch to ask for',
        );
      });

      test('an angle answer that is not a pitch is neither cycled nor asked '
          'for', () {
        final roof = press(const Tape(), '1 2 ÷ 2 3 ATAN');
        expect(lastResult(roof), 'Arctangent 27.55°');
        expect(texts(press(roof, '[Pitch]')).last, 'Pitch');
        expect(
          roof.cyclePitchSpelling(),
          const TapeRefused(TapeRefusal.noPitchToCycle),
        );
        final polygon = press(const Tape(), '[Diameter] 1 2 ft [Sides] 6');
        expect(strip(polygon), contains('Corner angle: 120°'));
        expect(texts(press(polygon, '[Pitch]')), [
          'Diameter12ft',
          'Sides6',
          'Pitch',
        ]);
      });

      test('an unfinished value is refused before the pitch is asked', () {
        expect(
          press(const Tape(), '[Rise] 8 ft [Run] 6').pressFunctionKey(
            PlainNumberKeys.pitch,
            keyWantsUnit: false,
            readsDegrees: true,
          ),
          const TapeRefused(TapeRefusal.finishThisValueFirst),
        );
      });

      test('the pill is refused when the tape does not end on a pitch', () {
        expect(
          const Tape().cyclePitchSpelling(),
          const TapeRefused(TapeRefusal.noPitchToCycle),
        );
        expect(
          press(const Tape(), '3 8 SIN').cyclePitchSpelling(),
          const TapeRefused(TapeRefusal.noPitchToCycle),
        );
        expect(
          press(const Tape(), '[Rise] 8 ft [Run] 6 ft').cyclePitchSpelling(),
          const TapeRefused(TapeRefusal.noPitchToCycle),
        );
      });

      test('S117: [Rise] after a finished pitch recomputes that triangle', () {
        final pitch = press(const Tape(), '[Rise] 8 ft [Run] 6 ft [Pitch]');
        expect(lastResult(pitch), 'Pitch-rise per 12in run 16in/12in');
        final again = press(pitch, '[Rise] 4 ft');
        expect(strip(again).first, 'Pitch-rise per 12in run: 8in/12in');
        expect(strip(again)[1], 'Pitch-degrees: 33.69°');
      });
    });

    group('the rise per 12in of run is a fraction of an inch (Q31)', () {
      test('S157: 7% reads 13/16in/12in, 47.25% reads 5-11/16in/12in, a '
          'whole rise stays plain', () {
        expect(
          strip(press(const Tape(), '[Slope] 7')).first,
          'Pitch-rise per 12in run: 13/16in/12in',
        );
        expect(
          strip(press(const Tape(), '[Slope] 4 7 . 2 5')).first,
          'Pitch-rise per 12in run: 5-11/16in/12in',
        );
        expect(
          strip(press(const Tape(), '[Rise] 6 ft [Run] 1 2 ft')).first,
          'Pitch-rise per 12in run: 6in/12in',
        );
      });

      test('S157: at the 1/4 setting a 7% grade reads 3/4in/12in', () {
        const quarter = CalculatorPreferences(
          fractionResolution: FractionResolution.quarter,
        );
        final tape = press(const Tape(preferences: quarter), '[Slope] 7');
        expect(
          tape.formatter.format(rules.answersFor(tape.namedValues).first.value),
          '3/4in/12in',
        );
      });

      test('S88: a bare 6 is a near-flat 1-1/4in/12in roof', () {
        expect(
          strip(press(const Tape(), '[Pitch] 6'))[1],
          'Pitch-rise per 12in run: 1-1/4in/12in',
        );
      });
    });

    group('an out-of-range pitch says why (S89)', () {
      test('89° is steep but real; 899° cannot be a pitch', () {
        final steep = press(const Tape(), '[Pitch] 8 9');
        expect(strip(steep).first, 'Pitch-degrees: 89°');
        expect(rules.refusalFor(steep.namedValues), isNull);
        final wall = press(steep, '9');
        expect(strip(wall), isEmpty);
        expect(rules.refusalFor(wall.namedValues), RuleRefusal.pitchOutOfRange);
      });

      test('0° and a 0% grade are the same silence at the other end; a 0.5% '
          'grade is a real slope', () {
        expect(
          rules.refusalFor(press(const Tape(), '[Pitch] 0').namedValues),
          RuleRefusal.pitchOutOfRange,
        );
        expect(
          rules.refusalFor(press(const Tape(), '[Slope] 0').namedValues),
          RuleRefusal.slopeOutOfRange,
        );
        expect(
          rules.refusalFor(press(const Tape(), '[Slope] 7').namedValues),
          isNull,
        );
        expect(
          rules.refusalFor(press(const Tape(), '[Slope] 0 . 5').namedValues),
          isNull,
        );
        expect(rules.refusalFor(const {}), isNull);
      });

      test('a second dimension on top of it does not bury the reason', () {
        final tape = press(const Tape(), '[Pitch] 9 5 [Diag] 2 2 ft');
        expect(strip(tape), isEmpty);
        expect(rules.refusalFor(tape.namedValues), RuleRefusal.pitchOutOfRange);
      });

      test('a pitch typed as a length is read before it is judged', () {
        final tape = press(const Tape(), '[Pitch] 9 5 in');
        expect(rules.refusalFor(tape.namedValues), isNull);
        expect(strip(tape).first, 'Pitch-degrees: 82.8°');
      });
    });

    group('one grammar for every bare number (S87, S117)', () {
      test('[Pitch] 6 × 2 is 12°, and an angle times a length is refused', () {
        expect(lastResult(press(const Tape(), '[Pitch] 6 × 2 =')), 'Calc 12°');
        expect(
          lastResult(press(const Tape(), '[Pitch] 6 × 2 ft =')),
          CalculationError.dimensionError.name,
        );
        expect(
          lastResult(press(const Tape(), '[Slope] 0 . 6 5 × 2 =')),
          'Calc 1.3',
          reason: '[Slope] is untouched: 0.65% is a grade, not an angle',
        );
      });

      test('a pitch is a ratio: it can never be raised to an area', () {
        final pitch = press(const Tape(), '[Pitch] 6 in');
        expect(
          pitch.pressUnit(Unit.inch, holdsLengthOnly: true),
          const TapeUnitRefused(UnitKeyRefused(UnitKeyRefusal.keepsLength)),
        );
        expect(strip(pitch).first, 'Pitch-degrees: 26.57°');
      });

      test('a length into [Slope] is refused and the grade survives', () {
        final grade = press(const Tape(), '[Slope] 7');
        expect(
          grade.pressUnit(Unit.inch, takesAGrade: true),
          const TapeRefused(TapeRefusal.slopeTakesAGrade),
        );
        expect(strip(grade)[1], 'Pitch-degrees: 4°');
      });
    });
  });
}
