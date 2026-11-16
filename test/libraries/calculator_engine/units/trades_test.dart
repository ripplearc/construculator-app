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

    group('D2: footing (CA-1066)', () {
      Length feet(double value) => Length.exact(
        Rational((value * 100).round() * 12, 100),
        unit: Unit.foot,
      );
      Length metres(double value) => Length.exact(
        Rational((value * 1000).round() * 10, 254),
        unit: Unit.metre,
      );
      const noLength = Length(0, unit: Unit.foot);
      final crossSections = [inches(16, 8), inches(24, 18)];

      String sizeText(PieceSize size) =>
          '${formatter.formatStoredLength(size.width)} x '
          '${formatter.formatStoredLength(size.height)}';

      test('S45, row 238: 22ft of footing is 0.72yd³ at 16in x 8in and '
          '2.44yd³ at 24in x 18in, in the store\'s order', () {
        final volumes = trades.footingVolumesFor(feet(22), crossSections);
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
        final volume = trades.footingVolumesFor(feet(22), crossSections).first;
        expect(volume.volume.cubicFeet, closeTo(22 * 16 * 8 / 144, 1e-9));
        expect(volume.volume.unit, Unit.yard);
      });

      test('a metric length of footing answers in cubic metres: 7m at '
          '16in x 8in is 0.58m³ (Section 6, results follow the entry '
          'system)', () {
        final volume = trades.footingVolumesFor(metres(7), crossSections).first;
        expect(formatter.format(volume.volume), '0.58m³');
      });

      test('the cross-section pill recomputes the same length: 22ft at '
          '24in x 18in is 2.44yd³, and a section with no face is refused', () {
        final volume = trades.footingVolumesFor(feet(22), crossSections).first;
        final wider = volume.recount(inches(24, 18))!;
        expect(formatter.format(wider.volume), '2.44yd³');
        expect(wider.length, feet(22));
        expect(volume.recount(inches(0, 8)), isNull);
        expect(volume.recount(inches(16, -8)), isNull);
      });

      test('a length of zero or less takes no concrete, one under half a '
          'tick (0.1mm) still does, and a cross-section with no face is left '
          'out', () {
        expect(trades.footingVolumesFor(noLength, crossSections), isEmpty);
        expect(trades.footingVolumesFor(feet(-22), crossSections), isEmpty);
        const tenthOfAMillimetre = Length.exact(
          Rational(1, 254),
          unit: Unit.millimetre,
        );
        expect(tenthOfAMillimetre.ticks, 0, reason: 'under half a tick');
        expect(
          trades.footingVolumesFor(tenthOfAMillimetre, crossSections),
          hasLength(2),
        );
        expect(
          trades
              .footingVolumesFor(feet(22), [inches(0, 8), inches(16, 8)])
              .map((volume) => volume.crossSection),
          [inches(16, 8)],
        );
        expect(trades.footingVolumesFor(feet(22), const []), isEmpty);
      });

      test('the longest footing the parser accepts, 19,999,999.99ft at '
          '24in x 18in, is 2,222,222.22yd³', () {
        final volume = trades
            .footingVolumesFor(feet(19999999.99), crossSections)
            .last;
        expect(formatter.format(volume.volume), '2,222,222.22yd³');
      });

      test('volumes compare by what they carry', () {
        expect(
          FootingVolume(length: feet(22), crossSection: inches(16, 8)),
          FootingVolume(length: feet(22), crossSection: inches(16, 8)),
        );
        expect(
          FootingVolume(length: feet(22), crossSection: inches(16, 8)),
          isNot(FootingVolume(length: feet(22), crossSection: inches(24, 18))),
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
