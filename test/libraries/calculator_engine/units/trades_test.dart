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
        'Drywall: 5 (48in x 108in)',
        'Drywall: 4.5 (48in x 120in)',
      ]);
    });

    test('S43: 143ft² of masonry is 160.88 blocks or 643.5 bricks', () {
      const area = Area(143.0 * squareTicksPerSquareFoot);
      final counts = trades.countsFor(Trade.masonry, area, masonry);
      expect(texts(counts), [
        'Masonry: 160.88 (8in x 16in)',
        'Masonry: 643.5 (4in x 8in)',
      ]);
      expect(counts.first.trade.resultKey, 'Number of pieces');
    });

    test('S43: the piece-size pill recounts the same area as 572 tiles', () {
      const area = Area(143.0 * squareTicksPerSquareFoot);
      final block = trades.countsFor(Trade.masonry, area, masonry).first;
      final tile = block.recount(inches(6, 6))!;
      expect(formatter.format(tile.value), '572');
      expect(tile.area, area);
      expect(tile.trade, Trade.masonry);
      expect(tile.size, inches(6, 6));
    });

    test('a count is kept exact and rounded only at display', () {
      final count = trades.countsFor(Trade.drywall, area180, appendixSheets)[0];
      expect(count.count, 180 / 32);
      expect(count.value, const Scalar(5.625));
    });

    test('a size with no face counts nothing and is left out', () {
      final counts = trades.countsFor(Trade.drywall, area180, [
        inches(0, 96),
        inches(48, 96),
        inches(48, 0),
      ]);
      expect(counts.map((count) => count.size), [inches(48, 96)]);
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
        'is taken from the precise sides, not from whole ticks (B1)', () {
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
      expect(formatter.format(sheets.single.value), '60');

      final tile = PieceSize(width: millimetres(100), height: millimetres(100));
      final tiles = trades.countsFor(Trade.masonry, squareMetres(1), [tile]);
      expect(formatter.format(tiles.single.value), '100');

      final big = PieceSize(width: millimetres(300), height: millimetres(300));
      final bigs = trades.countsFor(Trade.masonry, squareMetres(10), [big]);
      expect(formatter.format(bigs.single.value), '111.11');
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
