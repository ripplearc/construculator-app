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
        expect(texts(answers).first, 'Diagonal: 19.21ft');
        expect(answers.first.sources, ['Rise', 'Run']);
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
        expect(answers.map((answer) => answer.key).take(4), [
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
        expect(texts(answers).first, 'Diagonal: 5.22m');
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

    group('a circle from a Diameter or a Radius', () {
      const feet6 = Length(6 * Length.ticksPerFoot, unit: Unit.foot);

      test(
        'S33: Radius 6ft leads with the diameter, then area and circumference',
        () {
          final answers = rules.answersFor({'Radius': feet6});
          expect(texts(answers), [
            'Diameter: 12ft',
            'Circle area: 113.1ft²',
            'Circumference: 37.7ft',
          ]);
          expect(
            answers.map((answer) => answer.sources),
            everyElement(['Radius']),
          );
        },
      );

      test('S34 before Sides: Diameter 12ft leads with the radius', () {
        final answers = rules.answersFor({'Diameter': feet12});
        expect(texts(answers), [
          'Radius: 6ft',
          'Circle area: 113.1ft²',
          'Circumference: 37.7ft',
        ]);
        expect(answers.first.sources, ['Diameter']);
      });

      test('a Diameter outranks a Radius on the same tape', () {
        final answers = rules.answersFor({
          'Diameter': feet12,
          'Radius': feet20,
        });
        expect(texts(answers).first, 'Radius: 6ft');
      });

      test('a metric radius answers in metres', () {
        final answers = rules.answersFor({
          'Radius': const Length(2520, unit: Unit.metre),
        });
        expect(texts(answers), [
          'Diameter: 2m',
          'Circle area: 3.14m²',
          'Circumference: 6.28m',
        ]);
      });
    });

    group('a regular polygon from a Diameter and Sides', () {
      test('S34: Diameter 12ft and 6 sides is the gazebo floor', () {
        final answers = rules.answersFor({
          'Diameter': feet12,
          'Sides': const Scalar(6),
        });
        expect(texts(answers), [
          'Polygon area: 93.53ft²',
          'Side length: 6ft',
          'Perimeter: 36ft',
          'Corner angle: 120°',
        ]);
        expect(
          answers.map((answer) => answer.sources),
          everyElement(['Diameter', 'Sides']),
        );
      });

      test('S34: measured across the flats the same span reads 124.71ft²', () {
        final across = rules.polygonArea(feet12, 6, across: PolygonSpan.flats);
        expect(formatter.format(across), '124.71ft²');
        expect(formatter.format(rules.polygonArea(feet12, 6)), '93.53ft²');
      });

      test(
        'a Radius with Sides is a polygon too, with the radius as source',
        () {
          const feet6 = Length(6 * Length.ticksPerFoot, unit: Unit.foot);
          final answers = rules.answersFor({
            'Radius': feet6,
            'Sides': const Scalar(4),
          });
          expect(texts(answers), [
            'Polygon area: 72ft²',
            'Side length: 8.49ft',
            'Perimeter: 33.94ft',
            'Corner angle: 90°',
          ]);
          expect(answers.first.sources, ['Radius', 'Sides']);
        },
      );

      test('fewer than three sides, or a fraction of a side, is a circle', () {
        expect(
          texts(
            rules.answersFor({'Diameter': feet12, 'Sides': const Scalar(2)}),
          ).first,
          'Radius: 6ft',
        );
        expect(
          texts(
            rules.answersFor({'Diameter': feet12, 'Sides': const Scalar(3)}),
          ).first,
          'Polygon area: 46.77ft²',
        );
        expect(
          texts(
            rules.answersFor({'Diameter': feet12, 'Sides': const Scalar(5.5)}),
          ).first,
          'Radius: 6ft',
        );
      });

      test(
        'Sides without a span, or a length under Sides, answers nothing',
        () {
          expect(rules.answersFor({'Sides': const Scalar(6)}), isEmpty);
          expect(
            texts(rules.answersFor({'Diameter': feet12, 'Sides': feet9})).first,
            'Radius: 6ft',
          );
        },
      );
    });

    group('an arc from a chord and a segment height', () {
      const run9ft10 = Length(
        9 * Length.ticksPerFoot + 10 * Length.ticksPerInch,
        unit: Unit.footInch,
      );
      const rise3ft6 = Length(
        3 * Length.ticksPerFoot + 6 * Length.ticksPerInch,
        unit: Unit.footInch,
      );

      test(
        'S36: Run 9ft 10in and Rise 3ft 6in give the arc after the diagonal',
        () {
          final answers = rules.answersFor({'Run': run9ft10, 'Rise': rise3ft6});
          expect(texts(answers), [
            'Diagonal: 10.44ft',
            'Arc angle: 141.78°',
            'Arc radius: 5.2ft',
            'Arc length: 12.88ft',
          ]);
          expect(answers[1].sources, ['Run', 'Rise']);
        },
      );

      test('a Chord is the arc-first vocabulary and skips the triangle', () {
        final answers = rules.answersFor({'Chord': run9ft10, 'Rise': rise3ft6});
        expect(texts(answers), [
          'Arc angle: 141.78°',
          'Arc radius: 5.2ft',
          'Arc length: 12.88ft',
        ]);
        expect(answers.first.sources, ['Chord', 'Rise']);
      });

      test('a Chord outranks a Run on the same tape', () {
        final answers = rules.answersFor({
          'Chord': run9ft10,
          'Run': feet20,
          'Rise': rise3ft6,
        });
        expect(
          answers.firstWhere((answer) => answer.key == 'Arc angle').sources,
          ['Chord', 'Rise'],
        );
      });

      test('a height above half the chord is the major arc', () {
        const chord4 = Length(4 * Length.ticksPerFoot, unit: Unit.foot);
        const rise3 = Length(3 * Length.ticksPerFoot, unit: Unit.foot);
        final answers = rules.answersFor({'Chord': chord4, 'Rise': rise3});
        expect(texts(answers), [
          'Arc angle: 225.24°',
          'Arc radius: 2.17ft',
          'Arc length: 8.52ft',
        ]);
      });

      test('a height of exactly half the chord is a half circle', () {
        const chord4 = Length(4 * Length.ticksPerFoot, unit: Unit.foot);
        const rise2 = Length(2 * Length.ticksPerFoot, unit: Unit.foot);
        expect(texts(rules.answersFor({'Chord': chord4, 'Rise': rise2})), [
          'Arc angle: 180°',
          'Arc radius: 2ft',
          'Arc length: 6.28ft',
        ]);
      });

      test(
        'a height of nothing, a chord of nothing, or no height is no arc',
        () {
          const nothing = Length(0, unit: Unit.foot);
          expect(rules.answersFor({'Chord': run9ft10}), isEmpty);
          expect(
            rules.answersFor({'Chord': run9ft10, 'Rise': nothing}),
            isEmpty,
          );
          expect(
            rules.answersFor({'Chord': nothing, 'Rise': rise3ft6}),
            isEmpty,
          );
        },
      );

      test('a metric arc answers in metres', () {
        final answers = rules.answersFor({
          'Chord': const Length(10079, unit: Unit.metre),
          'Rise': const Length(2520, unit: Unit.metre),
        });
        expect(texts(answers), [
          'Arc angle: 106.27°',
          'Arc radius: 2.5m',
          'Arc length: 4.64m',
        ]);
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
