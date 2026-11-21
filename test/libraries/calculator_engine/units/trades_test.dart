import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const trades = Trades();
  const formatter = QuantityFormatter();
  const squareTicksPerSquareFoot =
      Area.squareTicksPerSquareInch * Area.squareInchesPerSquareFoot;

  PieceSize inches(double width, double height) => PieceSize(
    width: Length((width * Length.ticksPerInch).round(), unit: Unit.inch),
    height: Length((height * Length.ticksPerInch).round(), unit: Unit.inch),
  );

  String sizeText(PieceSize size) =>
      '${formatter.formatStoredLength(size.width)} x '
      '${formatter.formatStoredLength(size.height)}';

  List<String> texts(List<TradeCount> counts) => [
    for (final count in counts)
      '${count.trade.offerKey}: ${formatter.format(count.value)} '
          '(${sizeText(count.size)})',
  ];

  final prototypeSheets = [
    inches(47.24, 94.49),
    inches(47.24, 106.3),
    inches(47.24, 118.11),
  ];
  final appendixSheets = [inches(48, 96), inches(48, 108), inches(48, 120)];
  final masonry = [inches(8, 16), inches(4, 8)];
  const area180 = Area(180.0 * squareTicksPerSquareFoot);

  group('Trades', () {
    // The prototype's metric sheets are 47.24in decimals; stored as whole
    // ticks they read 47.23in (one tick under), which #638 already pins.
    test('S02 and S27: 180ft² of drywall, one count per stored sheet', () {
      final counts = trades.countsFor(Trade.drywall, area180, prototypeSheets);
      expect(texts(counts), [
        'Drywall: 5.81 (47.23in x 94.48in)',
        'Drywall: 5.16 (47.23in x 106.3in)',
        'Drywall: 4.65 (47.23in x 118.11in)',
      ]);
      expect(counts.first.trade.resultKey, 'Number of sheets');
    });

    test('S01: 410.67ft² reads 13.25 sheets of the first prototype size', () {
      const area = Area(
        22.0 * Length.ticksPerFoot * (18 * Length.ticksPerFoot + 8 * 64),
      );
      final counts = trades.countsFor(Trade.drywall, area, prototypeSheets);
      expect(formatter.format(counts.first.value), '13.25');
    });

    test('Appendix B seeds: 180ft² is 5.63, 5 and 4.5 sheets', () {
      final counts = trades.countsFor(Trade.drywall, area180, appendixSheets);
      expect(texts(counts), [
        'Drywall: 5.63 (48in x 96in)',
        'Drywall: 5.00 (48in x 108in)',
        'Drywall: 4.50 (48in x 120in)',
      ]);
    });

    test('S43: 143ft² of masonry is 160.88 blocks or 643.50 bricks', () {
      const area = Area(143.0 * squareTicksPerSquareFoot);
      final counts = trades.countsFor(Trade.masonry, area, masonry);
      expect(texts(counts), [
        'Masonry: 160.88 (8in x 16in)',
        'Masonry: 643.50 (4in x 8in)',
      ]);
      expect(counts.first.trade.resultKey, 'Number of pieces');
    });

    test('S43: the piece-size pill recounts the same area as 572 tiles', () {
      const area = Area(143.0 * squareTicksPerSquareFoot);
      final block = trades.countsFor(Trade.masonry, area, masonry).first;
      final tile = block.recount(inches(6, 6))!;
      expect(formatter.format(tile.value), '572.00');
      expect(tile.area, area);
      expect(tile.trade, Trade.masonry);
      expect(tile.size, inches(6, 6));
    });

    test('a count is kept exact and rounded only at display', () {
      final count = trades.countsFor(Trade.drywall, area180, appendixSheets)[0];
      expect(count.count, 180 / 32);
      expect(count.value, const Scalar(5.625, decimals: 2, padsDecimals: true));
    });

    test('a size with no face counts nothing and is left out', () {
      final counts = trades.countsFor(Trade.drywall, area180, [
        inches(0, 96),
        inches(48, 96),
        inches(48, 0),
      ]);
      expect(counts.map((count) => count.size), [inches(48, 96)]);
    });

    test('a stored size with one or two negative sides is left out: a face '
        'of (−48in) × (−96in) is positive, but the size is no size', () {
      expect(
        trades.countsFor(Trade.drywall, area180, [inches(-48, -96)]),
        isEmpty,
      );
      expect(
        trades.countsFor(Trade.drywall, area180, [inches(-48, 96)]),
        isEmpty,
      );
      expect(
        trades.countsFor(Trade.drywall, area180, [inches(48, -96)]),
        isEmpty,
      );
      const area = Area(143.0 * squareTicksPerSquareFoot);
      expect(trades.countsFor(Trade.masonry, area, [inches(-8, -16)]), isEmpty);
    });

    test('a count is always written to two decimals, zeros kept, never to '
        'two significant digits', () {
      Area squareFeet(double value) => Area(value * squareTicksPerSquareFoot);
      final sheet = [inches(48, 96)];
      String count(double area) => formatter.format(
        trades.countsFor(Trade.drywall, squareFeet(area), sheet).single.value,
      );
      expect(count(1), '0.03');
      expect(count(0.1), '0.00');
      expect(count(1.44), '0.05');
      expect(count(0.16), '0.01');
      expect(count(0.15), '0.00');
      expect(count(16), '0.50');
      expect(count(32), '1.00');
      expect(count(1000000), '31,250.00');
    });

    test('no sizes is no count', () {
      expect(trades.countsFor(Trade.drywall, area180, const []), isEmpty);
    });

    test('an area of zero or less has no count: (0ft − 12ft) × 10ft is '
        '−120ft², and Drywall on it is refused by the screen, not counted', () {
      expect(trades.countsFor(Trade.drywall, const Area(0), masonry), isEmpty);
      const negative = Area(-120.0 * squareTicksPerSquareFoot);
      expect(
        trades.countsFor(Trade.drywall, negative, appendixSheets),
        isEmpty,
      );
      expect(trades.countsFor(Trade.masonry, negative, masonry), isEmpty);
    });

    test('an area that is not a finite number has no count either, since no '
        'formatter could write it (Nit 1)', () {
      for (final area in const [
        Area(double.nan),
        Area(double.infinity),
        Area(double.negativeInfinity),
      ]) {
        expect(trades.countsFor(Trade.drywall, area, appendixSheets), isEmpty);
        expect(trades.countsFor(Trade.masonry, area, masonry), isEmpty);
      }
    });

    test('the smallest area above zero is counted', () {
      final counts = trades.countsFor(Trade.drywall, const Area(1), masonry);
      expect(counts, hasLength(2));
      expect(counts.first.count, greaterThan(0));
    });

    test('a recount to a size with a zero or a negative side is refused, so '
        'the caller keeps the last good size', () {
      const area = Area(143.0 * squareTicksPerSquareFoot);
      final block = trades.countsFor(Trade.masonry, area, masonry).first;
      expect(block.recount(inches(0, 96)), isNull);
      expect(block.recount(inches(48, 0)), isNull);
      expect(block.recount(inches(-6, 6)), isNull);
      expect(block.recount(inches(6, -6)), isNull);
      expect(block.recount(inches(6, 6)), isNotNull);
    });

    test('a recount to a size with two negative sides is refused too: '
        '(−6in) × (−6in) has a positive face but no side above zero', () {
      const area = Area(143.0 * squareTicksPerSquareFoot);
      final block = trades.countsFor(Trade.masonry, area, masonry).first;
      expect(block.recount(inches(-6, -6)), isNull);
      expect(block.recount(inches(-0.5, -0.5)), isNull);
    });

    test('a piece has a face only when both sides are above zero', () {
      expect(inches(6, 6).hasFace, isTrue);
      expect(inches(0.015625, 0.015625).hasFace, isTrue);
      expect(inches(0, 6).hasFace, isFalse);
      expect(inches(6, 0).hasFace, isFalse);
      expect(inches(-6, 6).hasFace, isFalse);
      expect(inches(6, -6).hasFace, isFalse);
      expect(inches(-6, -6).hasFace, isFalse);
      expect(inches(-6, -6).squareTicks, greaterThan(0));
    });

    test('a metric sheet counts a metric area the same way', () {
      final sheet = PieceSize(
        width: const Length(3024, unit: Unit.millimetre),
        height: const Length(6047, unit: Unit.millimetre),
      );
      const tenSquareMetres = Area(10.0 * 2520 * 2520, unit: Unit.metre);
      final count = trades.countsFor(Trade.drywall, tenSquareMetres, [sheet]);
      expect(formatter.format(count.single.value), '3.47');
    });

    test('an exact metric size counts an exact metric area exactly: the face '
        'is taken from the precise sides, not from whole ticks', () {
      const ticksPerMillimetre = Length.ticksPerInch / 25.4;
      Length millimetres(double value) =>
          Length.computed(value * ticksPerMillimetre, unit: Unit.millimetre);
      Area squareMetres(double value) => Area(
        value * 1000 * ticksPerMillimetre * 1000 * ticksPerMillimetre,
        unit: Unit.metre,
      );
      final sheet = PieceSize(
        width: millimetres(1200),
        height: millimetres(2400),
      );
      final sheets = trades.countsFor(Trade.drywall, squareMetres(172.8), [
        sheet,
      ]);
      // A computed length is kept to parts of a tick (Length.partsPerTick),
      // so the exact 60 is reached within what the display rounds away.
      expect(sheets.single.count, closeTo(60, 1e-4));
      expect(formatter.format(sheets.single.value), '60.00');

      final tile = PieceSize(width: millimetres(100), height: millimetres(100));
      final tiles = trades.countsFor(Trade.masonry, squareMetres(1), [tile]);
      expect(formatter.format(tiles.single.value), '100.00');

      final big = PieceSize(width: millimetres(300), height: millimetres(300));
      final bigs = trades.countsFor(Trade.masonry, squareMetres(10), [big]);
      expect(formatter.format(bigs.single.value), '111.11');
    });

    group('D2: footing, fence and members at spacing (CA-1066)', () {
      Length feet(double value) => Length.exact(
        Rational((value * 100).round() * 12, 100),
        unit: Unit.foot,
      );
      Length inchesLong(double value) =>
          Length.exact(Rational((value * 100).round(), 100), unit: Unit.inch);
      Length metres(double value) => Length.exact(
        Rational((value * 1000).round() * 10, 254),
        unit: Unit.metre,
      );
      const noLength = Length(0, unit: Unit.foot);
      final crossSections = [inches(16, 8), inches(24, 18)];
      final seventyFiveFeet = feet(75);
      final eightFeet = feet(8);

      String sizeText(PieceSize size) =>
          '${formatter.formatStoredLength(size.width)} x '
          '${formatter.formatStoredLength(size.height)}';

      test('S45, row 238: 22ft of footing is 0.72yd³ at 16in x 8in and '
          '2.44yd³ at 24in x 18in, in the store\'s order', () {
        final volumes = trades.footingVolumesFor(
          feet(22),
          crossSections,
          system: MeasurementSystem.imperial,
        );
        expect(
          [
            for (final volume in volumes)
              '${FootingVolume.offerKey}: ${formatter.format(volume.volume)} '
                  '(${sizeText(volume.crossSection)})',
          ],
          ['Footing: 0.72yd³ (16in x 8in)', 'Footing: 2.44yd³ (24in x 18in)'],
        );
        expect(FootingVolume.resultKey, 'Footing volume');
      });

      test('the volume is kept exact and rounded only at display', () {
        final volume = trades
            .footingVolumesFor(
              feet(22),
              crossSections,
              system: MeasurementSystem.imperial,
            )
            .first;
        expect(volume.volume.cubicFeet, closeTo(22 * 16 * 8 / 144, 1e-9));
        expect(volume.volume.unit, Unit.yard);
      });

      test('R1 (D1, product manager 17 November 2026): a footing follows '
          'the System of units setting, whatever unit the length was typed '
          'in — 10m then Footng reads in yd³ under Imperial and in m³ under '
          'Metric (Section 6, "Display settings"; Section 9, "(m³ under '
          'Metric)")', () {
        String first(Length length, MeasurementSystem system) {
          final volume = trades
              .footingVolumesFor(length, crossSections, system: system)
              .first;
          expect(volume.system, system);
          return QuantityFormatter(
            preferences: CalculatorPreferences(system: system),
          ).format(volume.volume);
        }

        expect(first(metres(10), MeasurementSystem.metric), '0.83m³');
        expect(first(metres(10), MeasurementSystem.imperial), '1.08yd³');
        expect(first(metres(7), MeasurementSystem.metric), '0.58m³');
        expect(first(feet(22), MeasurementSystem.metric), '0.55m³');
        expect(first(feet(22), MeasurementSystem.imperial), '0.72yd³');
      });

      test('R1: a recount keeps the system with the length', () {
        final metric = trades
            .footingVolumesFor(
              feet(22),
              crossSections,
              system: MeasurementSystem.metric,
            )
            .first;
        final wider = metric.recount(inches(24, 18))!;
        expect(wider.system, MeasurementSystem.metric);
        expect(wider.volume.unit, Unit.metre);
        expect(
          metric,
          isNot(
            FootingVolume(
              length: metric.length,
              crossSection: metric.crossSection,
              system: MeasurementSystem.imperial,
            ),
          ),
          reason: 'the system is part of the volume',
        );
      });

      test('the cross-section pill recomputes the same length: 22ft at '
          '24in x 18in is 2.44yd³, and a section with no face is refused', () {
        final volume = trades
            .footingVolumesFor(
              feet(22),
              crossSections,
              system: MeasurementSystem.imperial,
            )
            .first;
        final wider = volume.recount(inches(24, 18))!;
        expect(formatter.format(wider.volume), '2.44yd³');
        expect(wider.length, feet(22));
        expect(volume.recount(inches(0, 8)), isNull);
        expect(volume.recount(inches(16, -8)), isNull);
      });

      test('a length of zero or less takes no concrete, one under half a '
          'tick (0.1mm) still does, and a cross-section with no face is left '
          'out', () {
        expect(
          trades.footingVolumesFor(
            noLength,
            crossSections,
            system: MeasurementSystem.imperial,
          ),
          isEmpty,
        );
        expect(
          trades.footingVolumesFor(
            feet(-22),
            crossSections,
            system: MeasurementSystem.imperial,
          ),
          isEmpty,
        );
        const tenthOfAMillimetre = Length.exact(
          Rational(1, 254),
          unit: Unit.millimetre,
        );
        expect(tenthOfAMillimetre.ticks, 0, reason: 'under half a tick');
        expect(
          trades.footingVolumesFor(
            tenthOfAMillimetre,
            crossSections,
            system: MeasurementSystem.imperial,
          ),
          hasLength(2),
        );
        expect(
          trades
              .footingVolumesFor(feet(22), [
                inches(0, 8),
                inches(16, 8),
              ], system: MeasurementSystem.imperial)
              .map((volume) => volume.crossSection),
          [inches(16, 8)],
        );
        expect(
          trades.footingVolumesFor(
            feet(22),
            const [],
            system: MeasurementSystem.imperial,
          ),
          isEmpty,
        );
      });

      test('the longest footing the parser accepts, 19,999,999.99ft at '
          '24in x 18in, is 2,222,222.22yd³', () {
        final volume = trades
            .footingVolumesFor(
              feet(19999999.99),
              crossSections,
              system: MeasurementSystem.imperial,
            )
            .last;
        expect(formatter.format(volume.volume), '2,222,222.22yd³');
      });

      test('S44, row 241: 75ft of fence at 8ft on centre with 3 rails per '
          'section is 11 posts and 30 rails', () {
        final fence = trades.fenceFor(
          seventyFiveFeet,
          onCentre: eightFeet,
          railsPerSection: 3,
        )!;
        expect(fence.sections, 10);
        expect(fence.posts, 11);
        expect(fence.rails, 30);
        expect(formatter.format(fence.postsValue), '11');
        expect(formatter.format(fence.railsValue), '30');
        expect(FenceCount.postsKey, 'Fence posts');
        expect(FenceCount.railsOfferKey, 'Rails');
        expect(FenceCount.railsKey, 'Fence rails');
      });

      test('row 241: the O.C. pill set to 10ft recomputes 9 posts and 24 '
          'rails, keeping the length and the rails per section', () {
        final fence = trades.fenceFor(
          seventyFiveFeet,
          onCentre: eightFeet,
          railsPerSection: 3,
        )!;
        final wider = fence.recount(onCentre: feet(10))!;
        expect(wider.posts, 9);
        expect(wider.rails, 24);
        expect(wider.length, seventyFiveFeet);
        expect(wider.railsPerSection, 3);
        final twoRails = fence.recount(railsPerSection: 2)!;
        expect(twoRails.rails, 20);
        expect(twoRails.onCentre, eightFeet);
      });

      test('a length that is a whole number of sections takes no extra one: '
          '80ft at 8ft is 10 sections and 11 posts', () {
        final fence = trades.fenceFor(
          feet(80),
          onCentre: eightFeet,
          railsPerSection: 3,
        )!;
        expect(fence.sections, 10);
        expect(fence.posts, 11);
      });

      test('the sections are counted exactly over the inches, never over '
          'doubles: 0.9m at 0.3m is 3 sections, 24m at 2.4m is 10, and '
          '55.5m at 0.5m is 111, where a double ratio reads 112', () {
        expect(
          trades
              .fenceFor(
                metres(55.5),
                onCentre: metres(0.5),
                railsPerSection: 1,
              )!
              .sections,
          111,
        );
        expect(
          trades
              .fenceFor(metres(0.9), onCentre: metres(0.3), railsPerSection: 1)!
              .sections,
          3,
        );
        expect(
          trades
              .fenceFor(metres(24), onCentre: metres(2.4), railsPerSection: 1)!
              .sections,
          10,
        );
      });

      group('R1 (review of 19 Nov): a Calc length made by a division', () {
        const arithmetic = ChainArithmetic();
        Quantity combined(Quantity left, Operator operator, Quantity right) =>
            switch (arithmetic.combine(left, operator, right)) {
              ArithmeticValue(:final value) => value,
              final outcome => throw StateError('expected a value: $outcome'),
            };
        Length calcMetres(double metresLong, double by) =>
            combined(
                  combined(
                    metres(metresLong * by),
                    Operator.multiply,
                    metres(1),
                  ),
                  Operator.divide,
                  metres(by),
                )
                as Length;

        test('blocker 1: Calc 24m from 57.6m² ÷ 2.4m at 2.4m is 10 '
            'sections, 11 posts and 30 rails, as a typed 24m is', () {
          final calc24 = calcMetres(24, 2.4);
          expect(formatter.format(calc24), '24m');
          expect(
            calc24.inches,
            isNot(metres(24).inches),
            reason: 'a computed length is kept to 1/512 of a tick',
          );
          final fence = trades.fenceFor(
            calc24,
            onCentre: metres(2.4),
            railsPerSection: 3,
          )!;
          expect(fence.sections, 10);
          expect(fence.posts, 11);
          expect(fence.rails, 30);
          expect(
            trades.spacingCountsFor(calc24, [metres(2.4)]).single.members,
            11,
          );
        });

        test('the other runs of the review read as typed: Calc 2.4m at 0.4m '
            'is 7 posts, Calc 0.9m at 0.3m is 4, Calc 4.8m at 0.4m is 13, '
            'and Qty@OC the same', () {
          for (final (long, by, spacing, posts) in [
            (2.4, 2.4, 0.4, 7),
            (0.9, 2.4, 0.3, 4),
            (4.8, 2.4, 0.4, 13),
            (24.0, 2.4, 2.4, 11),
          ]) {
            final calc = calcMetres(long, by);
            final fence = trades.fenceFor(
              calc,
              onCentre: metres(spacing),
              railsPerSection: 1,
            )!;
            expect(fence.posts, posts, reason: 'Calc ${long}m at ${spacing}m');
            expect(
              trades.spacingCountsFor(calc, [metres(spacing)]).single.members,
              posts,
              reason: 'Qty@OC on Calc ${long}m at ${spacing}m',
            );
          }
        });

        test('a length one part of a tick past a whole number of spacings '
            'is that many, and two parts past is one more', () {
          final twentyFour = metres(24);
          Length plusParts(int parts) => Length.exact(
            twentyFour.inches +
                Rational(parts, Length.ticksPerInch * Length.partsPerTick),
            unit: Unit.metre,
          );
          FenceCount fenceOn(Length length) => trades.fenceFor(
            length,
            onCentre: metres(2.4),
            railsPerSection: 1,
          )!;
          expect(fenceOn(plusParts(1)).sections, 10);
          expect(fenceOn(plusParts(2)).sections, 11);
        });

        test('a length of one part of a tick is still one section', () {
          final onePart = Length.exact(
            Rational(1, Length.ticksPerInch * Length.partsPerTick),
            unit: Unit.inch,
          );
          final fence = trades.fenceFor(
            onePart,
            onCentre: eightFeet,
            railsPerSection: 3,
          )!;
          expect(fence.sections, 1);
          expect(
            trades.spacingCountsFor(onePart, [eightFeet]).single.members,
            2,
          );
        });

        test('nit 1: a length and a spacing too long for exact sums are '
            'counted in ticks, never thrown: 123.456789012m at '
            '0.4123456789m is 300 sections and 301 posts', () {
          final long = Length.exact(
            const Rational(1234567890120, 254000000).reduced,
            unit: Unit.metre,
          );
          final spacing = Length.exact(
            const Rational(4123456789, 254000000).reduced,
            unit: Unit.metre,
          );
          expect(
            () => long.inches / spacing.inches,
            throwsA(isA<RationalOverflow>()),
            reason: 'the exact ratio does not fit a Rational',
          );
          final fence = trades.fenceFor(
            long,
            onCentre: spacing,
            railsPerSection: 1,
          )!;
          expect(fence.sections, 300);
          expect(fence.posts, 301);
          expect(trades.spacingCountsFor(long, [spacing]).single.members, 301);
        });
      });

      test('a length shorter than one spacing is one section: 1in at 8ft '
          'is 2 posts and 3 rails', () {
        final fence = trades.fenceFor(
          inchesLong(1),
          onCentre: eightFeet,
          railsPerSection: 3,
        )!;
        expect(fence.sections, 1);
        expect(fence.posts, 2);
        expect(fence.rails, 3);
      });

      test('no rails per section is a fence of posts only; rails below zero '
          'or a spacing of zero or less are refused, and so is a length of '
          'zero or less', () {
        final posts = trades.fenceFor(
          seventyFiveFeet,
          onCentre: eightFeet,
          railsPerSection: 0,
        )!;
        expect(posts.rails, 0);
        expect(posts.posts, 11);
        expect(
          trades.fenceFor(
            seventyFiveFeet,
            onCentre: eightFeet,
            railsPerSection: -1,
          ),
          isNull,
        );
        expect(
          trades.fenceFor(
            seventyFiveFeet,
            onCentre: noLength,
            railsPerSection: 3,
          ),
          isNull,
        );
        expect(
          trades.fenceFor(
            seventyFiveFeet,
            onCentre: feet(-8),
            railsPerSection: 3,
          ),
          isNull,
        );
        expect(
          trades.fenceFor(noLength, onCentre: eightFeet, railsPerSection: 3),
          isNull,
        );
        expect(
          trades.fenceFor(feet(-75), onCentre: eightFeet, railsPerSection: 3),
          isNull,
        );
        expect(posts.recount(onCentre: noLength), isNull);
        expect(posts.recount(railsPerSection: -1), isNull);
        expect(posts.recount(railsPerSection: 0)!.rails, 0);
      });

      test('the longest fence the parser accepts, 19,999,999.99ft at 8ft, '
          'is 2,500,001 posts and 7,500,000 rails', () {
        final fence = trades.fenceFor(
          feet(19999999.99),
          onCentre: eightFeet,
          railsPerSection: 3,
        )!;
        expect(formatter.format(fence.postsValue), '2,500,001');
        expect(formatter.format(fence.railsValue), '7,500,000');
      });

      test('S46, row 242: 22ft 8-3/4in at 16in on centre is 19 members, and '
          'at 24in it is 13, in the store\'s order', () {
        final span = inchesLong(22 * 12 + 8.75);
        final counts = trades.spacingCountsFor(span, [
          inchesLong(16),
          inchesLong(24),
        ]);
        expect(
          [
            for (final count in counts)
              '${SpacingCount.offerKey} @'
                  '${formatter.formatStoredLength(count.spacing)}: '
                  '${formatter.format(count.value)}',
          ],
          ['Qty @16in: 19', 'Qty @24in: 13'],
        );
        expect(SpacingCount.resultKey, 'Quantity');
      });

      test('row 242: the O.C. pill set to 19.5in recomputes 15 members over '
          'the same span, and a spacing of zero or less is refused', () {
        final span = inchesLong(22 * 12 + 8.75);
        final count = trades.spacingCountsFor(span, [inchesLong(16)]).single;
        final wider = count.recount(inchesLong(19.5))!;
        expect(wider.members, 15);
        expect(wider.span, span);
        expect(count.recount(noLength), isNull);
        expect(count.recount(inchesLong(-16)), isNull);
      });

      test('a span up to one spacing long has two members, one at each '
          'end: 6in and 16in at 16in', () {
        expect(
          trades
              .spacingCountsFor(inchesLong(6), [inchesLong(16)])
              .single
              .members,
          2,
        );
        expect(
          trades
              .spacingCountsFor(inchesLong(16), [inchesLong(16)])
              .single
              .members,
          2,
        );
      });

      test('a span of zero or less has no members, a spacing of zero or '
          'less is left out, and no spacings is no count', () {
        final spacings = [inchesLong(16), inchesLong(24)];
        expect(trades.spacingCountsFor(noLength, spacings), isEmpty);
        expect(trades.spacingCountsFor(feet(-22), spacings), isEmpty);
        expect(
          trades
              .spacingCountsFor(feet(22), [noLength, inchesLong(16)])
              .map((count) => count.spacing),
          [inchesLong(16)],
        );
        expect(trades.spacingCountsFor(feet(22), const []), isEmpty);
      });

      test('the longest span the parser accepts, 19,999,999.99ft at 16in, '
          'is 15,000,001 members', () {
        final count = trades.spacingCountsFor(feet(19999999.99), [
          inchesLong(16),
        ]).single;
        expect(formatter.format(count.value), '15,000,001');
      });

      test('volumes, fences and counts compare by what they carry', () {
        expect(
          FootingVolume(
            length: feet(22),
            crossSection: inches(16, 8),
            system: MeasurementSystem.imperial,
          ),
          FootingVolume(
            length: feet(22),
            crossSection: inches(16, 8),
            system: MeasurementSystem.imperial,
          ),
        );
        expect(
          FootingVolume(
            length: feet(22),
            crossSection: inches(16, 8),
            system: MeasurementSystem.imperial,
          ),
          isNot(
            FootingVolume(
              length: feet(22),
              crossSection: inches(24, 18),
              system: MeasurementSystem.imperial,
            ),
          ),
        );
        expect(
          FenceCount(length: feet(75), onCentre: feet(8), railsPerSection: 3),
          FenceCount(length: feet(75), onCentre: feet(8), railsPerSection: 3),
        );
        expect(
          FenceCount(length: feet(75), onCentre: feet(8), railsPerSection: 3),
          isNot(
            FenceCount(length: feet(75), onCentre: feet(8), railsPerSection: 2),
          ),
        );
        expect(
          SpacingCount(span: feet(22), spacing: inchesLong(16)),
          SpacingCount(span: feet(22), spacing: inchesLong(16)),
        );
        expect(
          SpacingCount(span: feet(22), spacing: inchesLong(16)),
          isNot(SpacingCount(span: feet(22), spacing: inchesLong(24))),
        );
      });
    });

    test('counts and sizes compare by what they carry', () {
      final size = inches(48, 96);
      const count = TradeCount(
        trade: Trade.drywall,
        area: area180,
        size: PieceSize(
          width: Length(3072, unit: Unit.inch),
          height: Length(6144, unit: Unit.inch),
        ),
      );
      expect(
        TradeCount(trade: Trade.drywall, area: area180, size: size),
        count,
      );
      expect(count.recount(inches(48, 108)), isNot(count));
      expect(count.recount(inches(48, 96)), count);
      expect(const Trades(), trades);
    });
  });
}
