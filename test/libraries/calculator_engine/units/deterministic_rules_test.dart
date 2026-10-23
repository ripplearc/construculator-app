import 'dart:math' as math;

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
          keyWantsUnit: !PlainNumberKeys.all.contains(
            key.substring(1, key.length - 1),
          ),
          readsDegrees: key == '[${PlainNumberKeys.pitch}]',
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
        expect(
          unitDiagonal.preciseTicks,
          closeTo(1.41421, 1 / Length.partsPerTick),
        );
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

      test('a diagonal past 2⁵³ ticks is left out, the other answers stay', () {
        const twelveTrillionFeet = Length(
          12000000000000 * Length.ticksPerFoot,
          unit: Unit.foot,
        );
        final answers = rules.answersFor({
          'Length': twelveTrillionFeet,
          'Width': twelveTrillionFeet,
        });
        expect(answers.map((answer) => answer.key), ['Area', 'Perimeter']);
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

      test('a wall area of three 19,999,999ft sides does not wrap', () {
        const side = Length(19999999 * Length.ticksPerFoot, unit: Unit.foot);
        final answers = rules.answersFor({
          'Length': side,
          'Width': side,
          'Height': side,
        });
        expect(
          texts(answers).singleWhere((text) => text.startsWith('Wall area')),
          'Wall area: 1,599,999,840,000,004ft²',
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
      test('S41: Rise 12ft and Run 15ft give the pitch, then Diagonal', () {
        final answers = rules.answersFor({'Rise': feet12, 'Run': feet15});
        expect(texts(answers).take(4), [
          'Pitch-rise per 12in run: 9.6in/12in',
          'Pitch-degrees: 38.66°',
          'Pitch-grade: 80%',
          'Diagonal: 19.21ft',
        ]);
        expect(
          answers.take(4).map((answer) => answer.sources),
          everyElement(['Rise', 'Run']),
        );
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
        expect(texts(answers)[3], 'Diagonal: 14,142,135.62ft');
      });

      test(
        'Rise and Run whose diagonal passes 2⁵³ ticks offer no Diagonal',
        () {
          const twelveTrillionFeet = Length(
            12000000000000 * Length.ticksPerFoot,
            unit: Unit.foot,
          );
          final answers = rules.answersFor({
            'Rise': twelveTrillionFeet,
            'Run': twelveTrillionFeet,
          });
          expect(answers.where((answer) => answer.key == 'Diagonal'), isEmpty);
        },
      );

      test('a rectangle and a triangle on one tape answer in that order', () {
        final answers = rules.answersFor({
          'Length': feet20,
          'Width': feet9,
          'Rise': feet12,
          'Run': feet15,
        });
        expect(answers.map((answer) => answer.key).take(7), [
          'Area',
          'Diagonal',
          'Perimeter',
          'Pitch-rise per 12in run',
          'Pitch-degrees',
          'Pitch-grade',
          'Diagonal',
        ]);
      });
    });

    group('derived values follow the entry system', () {
      const rise = Length(7811, unit: Unit.metre);
      const run = Length(10583, unit: Unit.metre);

      test('S60: Rise 3.1m and Run 4.2m give Diagonal 5.22m', () {
        final answers = rules.answersFor({'Rise': rise, 'Run': run});
        expect(texts(answers)[3], 'Diagonal: 5.22m');
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

      test(
        'mixed sides keep the prototype vote, not the setting (CA-1233)',
        () {
          const metre = Length(2520, unit: Unit.metre);
          expect(texts(rules.answersFor({'Length': feet12, 'Width': metre})), [
            'Area: 39.38ft²',
            'Diagonal: 12.44ft',
            'Perimeter: 30.56ft',
          ]);
        },
      );

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
        expect(texts(from(beside, 'Rise Run'))[3], 'Diagonal: 19.21ft');
        final triangle = rules.answersFor({
          'Rise': rise,
          'Run': run,
          'Length': feet22,
        });
        expect(texts(from(triangle, 'Rise Run'))[3], 'Diagonal: 5.22m');
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

      test('an odd span keeps its half tick in the area, not in a length', () {
        const oddSpan = Length(9217, unit: Unit.foot);
        final answers = rules.answersFor({'Diameter': oddSpan});
        expect(answers, [
          const Answer(
            key: 'Radius',
            value: Length(4609, unit: Unit.foot),
            sources: ['Diameter'],
          ),
          Answer(
            key: 'Circle area',
            value: Area(math.pi * 4608.5 * 4608.5, unit: Unit.foot),
            sources: const ['Diameter'],
          ),
          const Answer(
            key: 'Circumference',
            value: Length(28956, unit: Unit.foot),
            sources: ['Diameter'],
          ),
        ]);
      });

      test('a Radius at the 19,999,999ft limit doubles without wrapping', () {
        const limit = Length(19999999 * Length.ticksPerFoot, unit: Unit.foot);
        final answers = texts(rules.answersFor({'Radius': limit}));
        expect(answers.first, 'Diameter: 39,999,998ft');
        expect(answers.last, 'Circumference: 125,663,699.86ft');
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

      test('S34 off a real tape: [Diameter] 12 ft [Sides] 6', () {
        final tape = press(const Tape(), '[Diameter] 1 2 ft [Sides] 6');
        expect(tape.namedValues, {
          'Diameter': feet12,
          'Sides': const Scalar(6),
        });
        expect(
          texts(rules.answersFor(tape.namedValues)).first,
          'Polygon area: 93.53ft²',
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

      test('a metric polygon answers in square metres and metres', () {
        final answers = rules.answersFor({
          'Diameter': const Length(2520, unit: Unit.metre),
          'Sides': const Scalar(6),
        });
        expect(texts(answers), [
          'Polygon area: 0.65m²',
          'Side length: 0.5m',
          'Perimeter: 3m',
          'Corner angle: 120°',
        ]);
      });

      test('an odd span gives exact areas and whole-tick lengths', () {
        const oddSpan = Length(9217, unit: Unit.foot);
        final answers = rules.answersFor({
          'Diameter': oddSpan,
          'Sides': const Scalar(4),
        });
        expect(answers.take(3), [
          Answer(
            key: 'Polygon area',
            value: Area(
              0.5 * 4 * 4608.5 * 4608.5 * math.sin(2 * math.pi / 4),
              unit: Unit.foot,
            ),
            sources: const ['Diameter', 'Sides'],
          ),
          const Answer(
            key: 'Side length',
            value: Length(6517, unit: Unit.foot),
            sources: ['Diameter', 'Sides'],
          ),
          const Answer(
            key: 'Perimeter',
            value: Length(26070, unit: Unit.foot),
            sources: ['Diameter', 'Sides'],
          ),
        ]);
      });

      test(
        'a Sides of 10¹⁷ reads a Corner angle of 180°, not a wrapped one',
        () {
          final answers = texts(
            rules.answersFor({'Diameter': feet12, 'Sides': const Scalar(1e17)}),
          );
          expect(answers.last, 'Corner angle: 180°');
        },
      );

      test('polygonArea refuses fewer than three sides', () {
        expect(() => rules.polygonArea(feet12, 2), throwsAssertionError);
        expect(formatter.format(rules.polygonArea(feet12, 3)), '46.77ft²');
      });

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
          expect(texts(answers).skip(3), [
            'Diagonal: 10.44ft',
            'Arc angle: 141.78°',
            'Arc radius: 5.2ft',
            'Arc length: 12.88ft',
          ]);
          expect(texts(answers).first, 'Pitch-rise per 12in run: 4.3in/12in');
          expect(answers[4].sources, ['Run', 'Rise']);
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

      test('a half circle on a very long chord is still 180°', () {
        const chord = Length(189817298, unit: Unit.foot);
        const rise = Length(94908649, unit: Unit.foot);
        expect(
          texts(rules.answersFor({'Chord': chord, 'Rise': rise})).first,
          'Arc angle: 180°',
        );
      });

      test('one tick either side of half the chord crosses 180°', () {
        const chord4 = Length(4 * Length.ticksPerFoot, unit: Unit.foot);
        const aboveHalf = Length(1537, unit: Unit.foot);
        const belowHalf = Length(1535, unit: Unit.foot);
        expect(
          texts(rules.answersFor({'Chord': chord4, 'Rise': aboveHalf})).first,
          'Arc angle: 180.07°',
        );
        expect(
          texts(rules.answersFor({'Chord': chord4, 'Rise': belowHalf})).first,
          'Arc angle: 179.93°',
        );
      });

      test('the radius and the length each round to their own tick', () {
        const chord4 = Length(4 * Length.ticksPerFoot, unit: Unit.foot);
        const rise = Length(809, unit: Unit.foot);
        final answers = rules.answersFor({'Chord': chord4, 'Rise': rise});
        expect(answers.skip(1), const [
          Answer(
            key: 'Arc radius',
            value: Length(1863, unit: Unit.foot),
            sources: ['Chord', 'Rise'],
          ),
          Answer(
            key: 'Arc length',
            value: Length(3612, unit: Unit.foot),
            sources: ['Chord', 'Rise'],
          ),
        ]);
      });

      test('a chord at the limit over a one-tick height has no arc', () {
        const chord = Length(19999999 * Length.ticksPerFoot, unit: Unit.foot);
        const oneTick = Length(1, unit: Unit.foot);
        expect(rules.answersFor({'Chord': chord, 'Rise': oneTick}), isEmpty);
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
          const belowNothing = Length(-768, unit: Unit.foot);
          expect(
            rules.answersFor({'Chord': run9ft10, 'Rise': belowNothing}),
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

    group('the triangle solver and the pitch (C3)', () {
      const eightInches = Length(8 * Length.ticksPerInch, unit: Unit.inch);
      const sixInches = Length(6 * Length.ticksPerInch, unit: Unit.inch);
      const feet22 = Length(22 * Length.ticksPerFoot, unit: Unit.foot);
      const feet5 = Length(5 * Length.ticksPerFoot, unit: Unit.foot);
      const feet6 = Length(6 * Length.ticksPerFoot, unit: Unit.foot);
      const feet8 = Length(8 * Length.ticksPerFoot, unit: Unit.foot);
      const feet10 = Length(10 * Length.ticksPerFoot, unit: Unit.foot);
      const feet13 = Length(13 * Length.ticksPerFoot, unit: Unit.foot);

      test('S39: Rise 8ft and Run 6ft give 16in/12in, 53.13°, 133.3%', () {
        expect(texts(rules.answersFor({'Rise': feet8, 'Run': feet6})).take(4), [
          'Pitch-rise per 12in run: 16in/12in',
          'Pitch-degrees: 53.13°',
          'Pitch-grade: 133.3%',
          'Diagonal: 10ft',
        ]);
      });

      test('S40: Pitch 8in and Diag 22ft give Rise 12.2ft and Run 18.31ft', () {
        final answers = rules.answersFor({
          'Pitch': eightInches,
          'Diag': feet22,
        });
        expect(texts(answers), ['Rise: 12.2ft', 'Run: 18.31ft']);
        expect(
          answers.map((answer) => answer.sources),
          everyElement(['Pitch', 'Diag']),
        );
      });

      test('Pitch with Run gives Rise and Diagonal, with Rise gives Run', () {
        expect(texts(rules.answersFor({'Pitch': sixInches, 'Run': feet12})), [
          'Rise: 6ft',
          'Diagonal: 13.42ft',
        ]);
        final fromRise = rules.answersFor({'Pitch': sixInches, 'Rise': feet6});
        expect(texts(fromRise), ['Run: 12ft', 'Diagonal: 13.42ft']);
        expect(fromRise.first.sources, ['Pitch', 'Rise']);
      });

      test('S42: Slope 7 alone reads as 0.8in/12in and 4°', () {
        final answers = rules.answersFor({'Slope': const Scalar(7)});
        expect(texts(answers), [
          'Pitch-rise per 12in run: 0.8in/12in',
          'Pitch-degrees: 4°',
        ]);
        expect(answers.first.sources, ['Slope']);
      });

      test('a pitch alone offers its three spellings, degrees first', () {
        expect(texts(rules.answersFor({'Pitch': eightInches})), [
          'Pitch-degrees: 33.69°',
          'Pitch-rise per 12in run: 8in/12in',
          'Pitch-grade: 66.7%',
        ]);
        expect(texts(rules.answersFor({'Pitch': const Scalar(6)})), [
          'Pitch-degrees: 6°',
          'Pitch-rise per 12in run: 1.3in/12in',
          'Pitch-grade: 10.5%',
        ]);
        expect(rules.answersFor({'Pitch': const Scalar(30)}).first.sources, [
          'Pitch',
        ]);
      });

      test('S93: a slope reaches the solver with a Run', () {
        expect(
          texts(rules.answersFor({'Slope': const Scalar(7), 'Run': feet12})),
          ['Rise: 0.84ft', 'Diagonal: 12.03ft'],
        );
        expect(
          texts(rules.answersFor({'Slope': const Scalar(50), 'Run': feet10})),
          ['Rise: 5ft', 'Diagonal: 11.18ft'],
        );
      });

      test('a diagonal with one leg gives the other leg, then the pitch', () {
        final fromRise = rules.answersFor({'Rise': feet5, 'Diag': feet13});
        expect(texts(fromRise), [
          'Run: 12ft',
          'Pitch-rise per 12in run: 5in/12in',
          'Pitch-degrees: 22.62°',
          'Pitch-grade: 41.7%',
        ]);
        expect(fromRise.first.sources, ['Rise', 'Diag']);
        expect(
          texts(rules.answersFor({'Run': feet12, 'Diag': feet13})).first,
          'Rise: 5ft',
        );
        expect(rules.answersFor({'Rise': feet13, 'Diag': feet5}), isEmpty);
      });

      test('a flat triangle offers its 0° pitch, an upright one nothing', () {
        const nothing = Length(0, unit: Unit.foot);
        expect(
          texts(rules.answersFor({'Rise': nothing, 'Run': feet6})).take(4),
          [
            'Pitch-rise per 12in run: 0in/12in',
            'Pitch-degrees: 0°',
            'Pitch-grade: 0%',
            'Diagonal: 6ft',
          ],
        );
        expect(texts(rules.answersFor({'Run': feet5, 'Diag': feet5})), [
          'Rise: 0ft',
          'Pitch-rise per 12in run: 0in/12in',
          'Pitch-degrees: 0°',
          'Pitch-grade: 0%',
        ]);
        expect(rules.answersFor({'Rise': feet5, 'Diag': feet5}), isEmpty);
      });

      test('a rise below zero, or a column of no size, answers nothing', () {
        const dropOf3ft = Length(-3 * Length.ticksPerFoot, unit: Unit.foot);
        const nineInches = Length(9 * Length.ticksPerInch, unit: Unit.inch);
        const nothing = Length(0, unit: Unit.foot);
        final dropped = rules.answersFor({'Rise': dropOf3ft, 'Run': feet6});
        expect(
          dropped.where((answer) => answer.key.startsWith('Pitch')),
          isEmpty,
        );
        expect(dropped.where((answer) => answer.key == 'Diagonal'), isEmpty);
        for (final namedValues in <Map<String, Quantity>>[
          {'Height': dropOf3ft, 'Radius': nineInches},
          {'Height': feet8, 'Radius': nothing},
          {'Height': nothing, 'Radius': nineInches},
          {'Height': feet8, 'Diameter': dropOf3ft},
        ]) {
          expect(
            rules.answersFor(namedValues).map((answer) => answer.key),
            isNot(anyElement(anyOf('Column', 'Cone'))),
            reason: '$namedValues',
          );
        }
      });

      test('a pitch of 0° or less, or of 90° or more, answers nothing', () {
        const outOfRange = <Map<String, Quantity>>[
          {'Pitch': Scalar(90), 'Run': feet12},
          {'Pitch': Scalar(0), 'Rise': feet6},
          {'Pitch': Scalar(100), 'Diag': feet22},
          {'Pitch': Scalar(-5), 'Run': feet10},
          {'Pitch': Scalar(0), 'Run': feet10},
          {'Pitch': Scalar(90)},
          {'Slope': Scalar(0)},
          {'Slope': Scalar(-3), 'Run': feet10},
        ];
        for (final namedValues in outOfRange) {
          expect(
            rules.answersFor(namedValues),
            isEmpty,
            reason: '$namedValues',
          );
        }
        expect(
          texts(
            rules.answersFor({'Pitch': const Scalar(89.9), 'Run': feet10}),
          ).first,
          'Rise: 5,729.57ft',
        );
      });

      test('a solved leg past the tick limit is left out', () {
        const tenMillionFeet = Length(
          10000000 * Length.ticksPerFoot,
          unit: Unit.foot,
        );
        expect(
          rules.answersFor({
            'Pitch': const Scalar(89.999999),
            'Run': tenMillionFeet,
          }),
          isEmpty,
        );
      });

      test('a solved leg follows the entry system of the sides it read', () {
        const tenMetres = Length(25197, unit: Unit.metre);
        final answers = rules.answersFor({
          'Pitch': eightInches,
          'Diag': tenMetres,
        });
        expect(texts(answers), ['Rise: 5.55m', 'Run: 8.32m']);
      });

      test(
        'S35: Height 3ft and Radius 9in give Column 5.3ft³, Cone 1.77ft³',
        () {
          const nineInches = Length(9 * Length.ticksPerInch, unit: Unit.inch);
          const threeFeet = Length(3 * Length.ticksPerFoot, unit: Unit.foot);
          final answers = rules.answersFor({
            'Height': threeFeet,
            'Radius': nineInches,
          });
          expect(texts(answers).take(2), ['Column: 5.3ft³', 'Cone: 1.77ft³']);
          expect(answers.first.sources, ['Height', 'Radius']);
          const eighteenInches = Length(
            18 * Length.ticksPerInch,
            unit: Unit.inch,
          );
          final fromDiameter = rules.answersFor({
            'Height': threeFeet,
            'Diameter': eighteenInches,
          });
          expect(texts(fromDiameter).take(2), [
            'Column: 5.3ft³',
            'Cone: 1.77ft³',
          ]);
          expect(fromDiameter.first.sources, ['Height', 'Diameter']);
          const metre = Length(2520, unit: Unit.metre);
          expect(
            texts(rules.answersFor({'Height': metre, 'Radius': metre})).first,
            'Column: 3.14m³',
          );
          final both = rules.answersFor({
            'Height': threeFeet,
            'Diameter': eighteenInches,
            'Radius': feet5,
          });
          expect(texts(both).first, 'Column: 5.3ft³');
          expect(both.first.sources, ['Height', 'Diameter']);
        },
      );

      test('the column and the cone lead the box and the circle', () {
        final answers = rules.answersFor({
          'Length': feet12,
          'Width': feet10,
          'Height': feet8,
          'Radius': feet5,
        });
        expect(answers.map((answer) => answer.key).take(4), [
          'Column',
          'Cone',
          'Volume',
          'Wall area',
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

      test(
        'S40 end to end: [Pitch] 8 in [Diag] 22 ft solves through the tape',
        () {
          final tape = press(const Tape(), '[Pitch] 8 in [Diag] 2 2 ft');
          expect(tape.namedValues.keys, ['Pitch', 'Diag']);
          final answers = rules.answersFor(tape.namedValues);
          expect(texts(answers), ['Rise: 12.2ft', 'Run: 18.31ft']);
          expect(answers.first.sources, ['Pitch', 'Diag']);
          final fromLeg = rules.answersFor(
            press(const Tape(), '[Rise] 5 ft [Diag] 1 3 ft').namedValues,
          );
          expect(texts(fromLeg).first, 'Run: 12ft');
        },
      );

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
