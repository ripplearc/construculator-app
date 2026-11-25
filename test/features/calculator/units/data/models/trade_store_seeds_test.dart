import 'package:construculator/features/calculator/data/models/trade_store_seeds.dart';
import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const formatter = QuantityFormatter();
  const metric = QuantityFormatter(
    preferences: CalculatorPreferences(system: MeasurementSystem.metric),
  );

  List<String> render(Iterable<StoredSize> sizes, QuantityFormatter f) => [
    for (final size in sizes)
      '${f.formatStoredLength(size.width)} x ${f.formatStoredLength(size.height)}',
  ];

  group('TradeStoreSeeds', () {
    test(
      'seeds imperial sheets in inches and metric sheets in millimetres',
      () {
        final imperial = TradeStoreSeeds.sizes(
          SizeStore.sheet,
          MeasurementSystem.imperial,
        );
        expect(render(imperial, formatter), [
          '48in x 96in',
          '48in x 108in',
          '48in x 120in',
        ]);
        expect(imperial.map((s) => s.seed), [
          'sheet_48x96in',
          'sheet_48x108in',
          'sheet_48x120in',
        ]);
        final metricSheets = TradeStoreSeeds.sizes(
          SizeStore.sheet,
          MeasurementSystem.metric,
        );
        expect(render(metricSheets, metric), [
          '1200mm x 2400mm',
          '1200mm x 2700mm',
          '1200mm x 3000mm',
        ]);
        expect(metricSheets.map((s) => s.seed), [
          'sheet_1200x2400mm',
          'sheet_1200x2700mm',
          'sheet_1200x3000mm',
        ]);
        expect(
          metricSheets.map((s) => s.width.unit),
          everyElement(Unit.millimetre),
        );
      },
    );

    test(
      'seeds one set of masonry and footing sizes for both systems, in order',
      () {
        for (final system in MeasurementSystem.values) {
          final masonry = TradeStoreSeeds.sizes(SizeStore.masonry, system);
          expect(render(masonry, formatter), ['8in x 16in', '4in x 8in']);
          expect(masonry.map((s) => s.seed), [
            'masonry_8x16in',
            'masonry_4x8in',
          ]);
          expect(masonry.map((s) => s.position), [0, 1]);
          final footing = TradeStoreSeeds.sizes(SizeStore.footing, system);
          expect(render(footing, formatter), ['16in x 8in', '24in x 18in']);
          expect(footing.map((s) => s.seed), [
            'footing_16x8in',
            'footing_24x18in',
          ]);
        }
        expect(
          TradeStoreSeeds.sizes(SizeStore.masonry, MeasurementSystem.metric),
          TradeStoreSeeds.sizes(SizeStore.masonry, MeasurementSystem.imperial),
        );
      },
    );

    test('a metric seed is exact, so 172.8 m² of 1200 × 2400 mm sheets counts '
        '60 and 1 m² of 100 × 100 mm tiles counts 100, never 59.99 or 99.98 '
        '(CA-1466; Sections 6 and 9)', () {
      final sheet = TradeStoreSeeds.sizes(
        SizeStore.sheet,
        MeasurementSystem.metric,
      ).first;
      expect(sheet.width.inches, const Rational(6000, 127));
      expect(sheet.height.inches, const Rational(12000, 127));
      final squareTicksPerSquareMetre =
          Unit.metre.ticksPerUnit * Unit.metre.ticksPerUnit;
      final sheetFace = PieceSize(
        width: sheet.width,
        height: sheet.height,
      ).squareTicks;
      expect(172.8 * squareTicksPerSquareMetre / sheetFace, closeTo(60, 1e-9));
      final tile = PieceSize(
        width: const Length.exact(Rational(500, 127), unit: Unit.millimetre),
        height: const Length.exact(Rational(500, 127), unit: Unit.millimetre),
      );
      expect(squareTicksPerSquareMetre / tile.squareTicks, closeTo(100, 1e-9));
      expect(
        10 *
            squareTicksPerSquareMetre /
            PieceSize(
              width: const Length.exact(
                Rational(1500, 127),
                unit: Unit.millimetre,
              ),
              height: const Length.exact(
                Rational(1500, 127),
                unit: Unit.millimetre,
              ),
            ).squareTicks,
        closeTo(111.11111111, 1e-6),
      );
    });

    test('an imperial seed is still its whole ticks, so its count is '
        'unchanged (CA-1466)', () {
      final sheet = TradeStoreSeeds.sizes(
        SizeStore.sheet,
        MeasurementSystem.imperial,
      ).first;
      expect(
        sheet.width,
        const Length(48 * Length.ticksPerInch, unit: Unit.inch),
      );
      expect(
        sheet.height,
        const Length(96 * Length.ticksPerInch, unit: Unit.inch),
      );
      expect(sheet.width.preciseTicks, 48 * 64);
      for (final (store, index) in const [
        (SizeStore.masonry, 0),
        (SizeStore.footing, 0),
      ]) {
        final size = TradeStoreSeeds.sizes(
          store,
          MeasurementSystem.metric,
        )[index];
        expect(size.width.preciseTicks, size.width.ticks.toDouble());
      }
      expect(TradeStoreSeeds.spacings.first.spacing.preciseTicks, 16 * 64);
      expect(TradeStoreSeeds.fence.onCentre.preciseTicks, 8 * 768);
    });

    test('no seed has an id and every seed names itself', () {
      final all = [
        for (final store in SizeStore.values)
          for (final system in MeasurementSystem.values)
            ...TradeStoreSeeds.sizes(store, system),
      ];
      expect(all.every((s) => s.id == null && s.seed != null), isTrue);
      expect(all.map((s) => s.seed).toSet(), hasLength(3 + 3 + 2 + 2));
      expect(
        TradeStoreSeeds.spacings.every((s) => s.id == null && s.seed != null),
        isTrue,
      );
      expect(
        TradeStoreSeeds.densities.every((d) => d.id == null && d.seed != null),
        isTrue,
      );
    });

    test(
      'seeds the spacings, the fence, the waste factors and the densities of Appendix B',
      () {
        expect(
          TradeStoreSeeds.spacings.map((s) => formatter.format(s.spacing)),
          ['16in', '24in'],
        );
        expect(TradeStoreSeeds.spacings.map((s) => s.seed), [
          'spacing_16in',
          'spacing_24in',
        ]);
        expect(formatter.format(TradeStoreSeeds.fence.onCentre), '8ft');
        expect(TradeStoreSeeds.fence.railsPerSection, 3);
        expect(TradeStoreSeeds.waste.map((w) => w.unit), RateUnit.values);
        expect(TradeStoreSeeds.waste.every((w) => w.percent == 0), isTrue);
        expect(
          TradeStoreSeeds.densities.map(
            (d) => '${d.name} ${d.poundsPerCubicYard}',
          ),
          ['concrete 4050.0', 'gravel 3000.0', 'sand 2700.0'],
        );
        expect(TradeStoreSeeds.densities.map((d) => d.seed), [
          'density_concrete',
          'density_gravel',
          'density_sand',
        ]);
      },
    );
  });
}
