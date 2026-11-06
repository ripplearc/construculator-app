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
