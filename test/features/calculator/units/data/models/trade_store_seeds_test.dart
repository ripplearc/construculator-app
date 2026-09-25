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
        final imperial = TradeStoreSeeds.sizes.where(
          (s) =>
              s.store == SizeStore.sheet &&
              s.system == MeasurementSystem.imperial,
        );
        expect(render(imperial, formatter), [
          '48in x 96in',
          '48in x 108in',
          '48in x 120in',
        ]);
        final metricSheets = TradeStoreSeeds.sizes.where(
          (s) =>
              s.store == SizeStore.sheet &&
              s.system == MeasurementSystem.metric,
        );
        expect(render(metricSheets, metric), [
          '1200mm x 2400mm',
          '1200mm x 2700mm',
          '1200mm x 3000mm',
        ]);
      },
    );

    test('seeds masonry and footing sizes under both systems, in order', () {
      for (final system in MeasurementSystem.values) {
        final masonry = TradeStoreSeeds.sizes.where(
          (s) => s.store == SizeStore.masonry && s.system == system,
        );
        expect(render(masonry, formatter), ['8in x 16in', '4in x 8in']);
        expect(masonry.map((s) => s.position), [0, 1]);
        final footing = TradeStoreSeeds.sizes.where(
          (s) => s.store == SizeStore.footing && s.system == system,
        );
        expect(render(footing, formatter), ['16in x 8in', '24in x 18in']);
      }
      expect(TradeStoreSeeds.sizes.every((s) => s.id == null), isTrue);
    });

    test(
      'seeds the spacings, the fence, the rates and the densities of Appendix B',
      () {
        expect(
          TradeStoreSeeds.spacings.map((s) => formatter.format(s.spacing)),
          ['16in', '24in'],
        );
        expect(formatter.format(TradeStoreSeeds.fence.onCentre), '8ft');
        expect(TradeStoreSeeds.fence.railsPerSection, 3);
        expect(
          TradeStoreSeeds.rates.map((r) => r.unit).toSet(),
          RateUnit.values.toSet(),
        );
        expect(TradeStoreSeeds.rates.every((r) => r.wastePercent == 0), isTrue);
        expect(
          TradeStoreSeeds.rates
              .firstWhere((r) => r.unit == RateUnit.squareFoot)
              .rate,
          12.3,
        );
        expect(
          TradeStoreSeeds.rates
              .firstWhere((r) => r.unit == RateUnit.thousandBoardFeet)
              .rate,
          412,
        );
        expect(
          TradeStoreSeeds.densities.map(
            (d) => '${d.name} ${d.poundsPerCubicYard}',
          ),
          ['concrete 4050.0', 'gravel 3000.0', 'sand 2700.0'],
        );
      },
    );
  });
}
