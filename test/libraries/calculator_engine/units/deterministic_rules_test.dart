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

      test('Length and Width are the rectangle read before Height', () {
        final answers = rules.answersFor({
          'Length': feet22,
          'Width': feet18in8,
          'Height': feet9,
        });
        final area = answers.firstWhere((answer) => answer.key == 'Area');
        expect(area.sources, ['Length', 'Width']);
      });

      test('the diagonal keeps its fraction of a tick', () {
        const three = Length(3, unit: Unit.inch);
        const four = Length(4, unit: Unit.inch);
        const one = Length(1, unit: Unit.inch);
        expect(
          rules.answersFor({'Length': three, 'Width': four})[1].value,
          const Length(5, unit: Unit.foot),
        );
        final unitDiagonal =
            rules.answersFor({'Length': one, 'Width': one})[1].value as Length;
        expect(unitDiagonal.preciseTicks, closeTo(1.41421, 0.00001));
        expect(unitDiagonal.ticks, 1);
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

    group('a diagonal is rounded once, at display (Sections 6 and 8)', () {
      const feet13 = Length(13 * Length.ticksPerFoot, unit: Unit.foot);
      const feet6 = Length(6 * Length.ticksPerFoot, unit: Unit.foot);

      test('Length 13ft and Width 13ft read Diagonal 18.38ft, not 18.39ft', () {
        final diagonal = rules
            .answersFor({'Length': feet13, 'Width': feet13})
            .singleWhere((answer) => answer.key == 'Diagonal');
        expect(formatter.format(diagonal.value), '18.38ft');
        expect(
          (diagonal.value as Length).preciseTicks,
          closeTo(14119.508, 0.001),
        );
        expect((diagonal.value as Length).ticks, 14120);
      });

      test('Rise 15ft and Run 6ft read Diagonal 16.16ft, not 16.15ft', () {
        expect(
          texts(
            rules.answersFor({'Rise': feet15, 'Run': feet6}),
          ).where((text) => text.startsWith('Diagonal')),
          ['Diagonal: 16.16ft'],
        );
      });
    });

    group('a box from Length, Width and Height', () {
      const feet10 = Length(10 * Length.ticksPerFoot, unit: Unit.foot);
      const feet8 = Length(8 * Length.ticksPerFoot, unit: Unit.foot);

      test(
        'S26: 12ft × 10ft × 8ft leads with Volume 960ft³, Wall area 352ft²',
        () {
          final answers = rules.answersFor({
            'Length': feet12,
            'Width': feet10,
            'Height': feet8,
          });
          expect(texts(answers), [
            'Volume: 960ft³',
            'Wall area: 352ft²',
            'Area: 120ft²',
            'Diagonal: 15.62ft',
            'Perimeter: 44ft',
          ]);
          expect(
            answers.first,
            const Answer(
              key: 'Volume',
              value: Volume(960, unit: Unit.foot),
              sources: ['Length', 'Width', 'Height'],
            ),
          );
          expect(answers[1].sources, ['Length', 'Width', 'Height']);
        },
      );

      test(
        'walkthrough 12.1: 20ft × 10ft × 8ft is 1,600ft³, 480ft², 200ft²',
        () {
          final answers = rules.answersFor({
            'Length': feet20,
            'Width': feet10,
            'Height': feet8,
          });
          expect(texts(answers).sublist(0, 3), [
            'Volume: 1,600ft³',
            'Wall area: 480ft²',
            'Area: 200ft²',
          ]);
        },
      );

      test('a volume is kept exact and rounded only at display', () {
        const inch = Length(Length.ticksPerInch, unit: Unit.inch);
        final volume = rules
            .answersFor({'Length': inch, 'Width': inch, 'Height': inch})
            .first
            .value;
        expect(volume, const Volume(1 / 1728, unit: Unit.foot));
        expect(
          formatter.format(const Volume(1 / 1728, unit: Unit.inch)),
          '1in³',
        );
      });

      test('a metric box answers in cubic metres and square metres', () {
        const metre = Length(2520, unit: Unit.metre);
        final answers = rules.answersFor({
          'Length': metre,
          'Width': metre,
          'Height': metre,
        });
        expect(texts(answers).sublist(0, 2), ['Volume: 1m³', 'Wall area: 4m²']);
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

      test('a chip no rule used does not change the unit (rule 4.5)', () {
        // Answers are picked by their sources, because the rules higher in
        // the stack read Height, Rise and Run too.
        List<Answer> from(List<Answer> answers, String sources) => [
          for (final answer in answers)
            if (answer.sources.join(' ') == sources) answer,
        ];
        final beside = rules.answersFor({
          'Length': const Length(2520, unit: Unit.centimetre),
          'Width': const Length(2520, unit: Unit.millimetre),
          'Height': feet9,
          'Rise': feet12,
          'Run': feet15,
        });
        expect(texts(from(beside, 'Length Width')), [
          'Area: 1m²',
          'Diagonal: 1.41m',
          'Perimeter: 4m',
        ]);
        expect(texts(from(beside, 'Rise Run')).first, 'Diagonal: 19.21ft');
        final triangle = rules.answersFor({
          'Rise': rise,
          'Run': run,
          'Length': feet22,
        });
        expect(texts(from(triangle, 'Rise Run')).first, 'Diagonal: 5.22m');
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
