import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const rules = DeterministicRules();
  const formatter = QuantityFormatter();
  const feet22 = Length(22 * Length.ticksPerFoot, unit: Unit.foot);
  const feet18in8 = Length(
    18 * Length.ticksPerFoot + 8 * Length.ticksPerInch,
    unit: Unit.footInch,
  );
  const feet20 = Length(20 * Length.ticksPerFoot, unit: Unit.foot);
  const feet9 = Length(9 * Length.ticksPerFoot, unit: Unit.foot);
  const feet12 = Length(12 * Length.ticksPerFoot, unit: Unit.foot);
  const feet15 = Length(15 * Length.ticksPerFoot, unit: Unit.foot);

  List<String> texts(List<Answer> answers) => [
    for (final answer in answers)
      '${answer.key}: ${formatter.format(answer.value)}',
  ];

  Tape press(Tape tape, String keys) {
    var current = tape;
    for (final key in keys.split(' ')) {
      final outcome = switch (key) {
        'ft' => current.pressUnit(Unit.foot),
        'in' => current.pressUnit(Unit.inch),
        'm' => current.pressUnit(Unit.metre),
        _ when key.startsWith('[') => current.pressFunctionKey(
          key.substring(1, key.length - 1),
        ),
        _ => current.typeDigit(key),
      };
      current = (outcome as TapeChanged).tape;
    }
    return current;
  }

  group('DeterministicRules', () {
    group('a rectangle from two named sides (Section 8)', () {
      test('S01: Length 22ft and Width 18ft 8in give Area 410.67ft²', () {
        final answers = rules.answersFor({
          'Length': feet22,
          'Width': feet18in8,
        });
        expect(texts(answers), [
          'Area: 410.67ft²',
          'Diagonal: 28.85ft',
          'Perimeter: 81.33ft',
        ]);
        expect(
          answers.first,
          const Answer(
            key: 'Area',
            value: Area(16896.0 * 14336, unit: Unit.foot),
            sources: ['Length', 'Width'],
          ),
        );
      });

      test(
        'S02 and S09: Length 20ft and Height 9ft give 180ft², 21.93ft, 58ft',
        () {
          final answers = rules.answersFor({'Length': feet20, 'Height': feet9});
          expect(texts(answers), [
            'Area: 180ft²',
            'Diagonal: 21.93ft',
            'Perimeter: 58ft',
          ]);
          expect(answers.first.sources, ['Length', 'Height']);
        },
      );

      test('Width and Height make a rectangle too', () {
        final answers = rules.answersFor({'Width': feet20, 'Height': feet9});
        expect(texts(answers).first, 'Area: 180ft²');
        expect(answers.first.sources, ['Width', 'Height']);
      });

      test('Length and Width are read before Height', () {
        final answers = rules.answersFor({
          'Length': feet22,
          'Width': feet18in8,
          'Height': feet9,
        });
        expect(answers.first.sources, ['Length', 'Width']);
      });

      test('the diagonal is rounded to a whole tick, half up', () {
        const three = Length(3, unit: Unit.inch);
        const four = Length(4, unit: Unit.inch);
        const one = Length(1, unit: Unit.inch);
        expect(
          rules.answersFor({'Length': three, 'Width': four})[1].value,
          const Length(5, unit: Unit.foot),
        );
        expect(
          rules.answersFor({'Length': one, 'Width': one})[1].value,
          const Length(1, unit: Unit.foot),
        );
        const two = Length(2, unit: Unit.inch);
        expect(
          rules.answersFor({'Length': two, 'Width': three})[1].value,
          const Length(4, unit: Unit.foot),
        );
      });

      test('the diagonal of 10,000,000ft by 10,000,000ft does not wrap', () {
        const tenMillionFeet = Length(
          10000000 * Length.ticksPerFoot,
          unit: Unit.foot,
        );
        final answers = rules.answersFor({
          'Length': tenMillionFeet,
          'Width': tenMillionFeet,
        });
        expect(texts(answers)[1], 'Diagonal: 14,142,135.62ft');
        expect(texts(answers)[2], 'Perimeter: 40,000,000ft');
      });

      test('one named side is not a rectangle', () {
        expect(rules.answersFor({'Length': feet22}), isEmpty);
        expect(rules.answersFor({'Width': feet22, 'Rise': feet9}), isEmpty);
      });

      test('a named value that is not a length is not a side', () {
        expect(
          rules.answersFor({'Length': feet22, 'Width': const Scalar(18)}),
          isEmpty,
        );
      });
    });

    group('a right triangle from Rise and Run', () {
      test('S41: Rise 12ft and Run 15ft give Diagonal 19.21ft', () {
        final answers = rules.answersFor({'Rise': feet12, 'Run': feet15});
        expect(texts(answers), ['Diagonal: 19.21ft']);
        expect(answers.single.sources, ['Rise', 'Run']);
      });

      test('Rise alone, Run alone, or a run of nothing give no diagonal', () {
        expect(rules.answersFor({'Rise': feet12}), isEmpty);
        expect(rules.answersFor({'Run': feet15}), isEmpty);
        expect(
          rules.answersFor({
            'Rise': feet12,
            'Run': const Length(0, unit: Unit.foot),
          }),
          isEmpty,
        );
      });

      test('S41 at 10,000,000ft a side: the squares do not wrap', () {
        const tenMillionFeet = Length(
          10000000 * Length.ticksPerFoot,
          unit: Unit.foot,
        );
        final answers = rules.answersFor({
          'Rise': tenMillionFeet,
          'Run': tenMillionFeet,
        });
        expect(texts(answers).first, 'Diagonal: 14,142,135.62ft');
      });

      test('a rectangle and a triangle on one tape answer in that order', () {
        final answers = rules.answersFor({
          'Length': feet20,
          'Width': feet9,
          'Rise': feet12,
          'Run': feet15,
        });
        expect(answers.map((answer) => answer.key), [
          'Area',
          'Diagonal',
          'Perimeter',
          'Diagonal',
        ]);
      });
    });

    group('derived values follow the entry system', () {
      const rise = Length(7811, unit: Unit.metre);
      const run = Length(10583, unit: Unit.metre);

      test('S60: Rise 3.1m and Run 4.2m give Diagonal 5.22m', () {
        final answers = rules.answersFor({'Rise': rise, 'Run': run});
        expect(texts(answers), ['Diagonal: 5.22m']);
      });

      test('two metric sides answer in metres', () {
        final answers = rules.answersFor({
          'Length': const Length(2520, unit: Unit.centimetre),
          'Width': const Length(2520, unit: Unit.millimetre),
        });
        expect(texts(answers), [
          'Area: 1m²',
          'Diagonal: 1.41m',
          'Perimeter: 4m',
        ]);
      });

      test('a metric side beside an imperial one answers in feet', () {
        final answers = rules.answersFor({'Length': rise, 'Width': feet9});
        expect(
          answers.first.value,
          isA<Area>().having((area) => area.unit, 'unit', Unit.foot),
        );
      });
    });

    group('named values come from the tape', () {
      test('the last readable value under each key', () {
        final tape = press(
          const Tape(),
          '[Length] 2 2 ft [Width] 1 8 ft 8 in [Length] 2 0 ft',
        );
        expect(tape.namedValues, {'Length': feet20, 'Width': feet18in8});
      });

      test('a value still being typed and a bare number are left out', () {
        final tape = press(const Tape(), '[Length] 2 2 ft 8 ft [Width] 1 8');
        expect(tape.namedValues, {'Length': feet22});
      });

      test('S01 end to end: the strip reads Area 410.67ft² from the tape', () {
        final tape = press(const Tape(), '[Length] 2 2 ft [Width] 1 8 ft 8 in');
        expect(
          texts(rules.answersFor(tape.namedValues)).first,
          'Area: 410.67ft²',
        );
      });
    });

    test('is equal to another, and an answer compares by what it carries', () {
      expect(const DeterministicRules(), rules);
      const answer = Answer(key: 'Area', value: Area(1), sources: ['Length']);
      expect(
        answer,
        const Answer(key: 'Area', value: Area(1), sources: ['Length']),
      );
      expect(
        answer,
        isNot(const Answer(key: 'Area', value: Area(1), sources: ['Width'])),
      );
    });
  });
}
