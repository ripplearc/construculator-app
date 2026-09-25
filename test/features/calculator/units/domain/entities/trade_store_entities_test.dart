import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const inch = Length.ticksPerInch;
  const sheet = StoredSize(
    id: 'sheet-1',
    store: SizeStore.sheet,
    system: MeasurementSystem.imperial,
    width: Length(48 * inch, unit: Unit.inch),
    height: Length(96 * inch, unit: Unit.inch),
    position: 0,
  );

  group('StoredSize', () {
    test('copies with fields replaced and keeps the rest', () {
      final metric = sheet.copyWith(
        id: 'sheet-2',
        store: SizeStore.masonry,
        system: MeasurementSystem.metric,
        width: const Length(1, unit: Unit.millimetre),
        height: const Length(2, unit: Unit.millimetre),
        position: 3,
      );
      expect(
        metric,
        const StoredSize(
          id: 'sheet-2',
          store: SizeStore.masonry,
          system: MeasurementSystem.metric,
          width: Length(1, unit: Unit.millimetre),
          height: Length(2, unit: Unit.millimetre),
          position: 3,
        ),
      );
      expect(sheet.copyWith(), sheet);
    });

    test('is equal by value and has no id until stored', () {
      final position = int.parse('0');
      expect(
        StoredSize(
          id: 'sheet-1',
          store: SizeStore.sheet,
          system: MeasurementSystem.imperial,
          width: const Length(48 * inch, unit: Unit.inch),
          height: const Length(96 * inch, unit: Unit.inch),
          position: position,
        ),
        sheet,
      );
      expect(sheet.copyWith(id: null).id, 'sheet-1');
    });
  });

  group('StoredSpacing', () {
    test('copies and compares by value', () {
      const spacing = StoredSpacing(
        spacing: Length(16 * inch, unit: Unit.inch),
        position: 0,
      );
      final stored = spacing.copyWith(id: 'oc-1', position: 1);
      expect(stored.id, 'oc-1');
      expect(stored.position, 1);
      expect(stored.spacing, spacing.spacing);
      expect(
        spacing
            .copyWith(spacing: const Length(1, unit: Unit.inch))
            .spacing
            .ticks,
        1,
      );
      final position = int.parse('0');
      expect(
        StoredSpacing(
          spacing: const Length(16 * inch, unit: Unit.inch),
          position: position,
        ),
        spacing,
      );
    });
  });

  group('FenceConfiguration', () {
    test('copies and compares by value', () {
      const fence = FenceConfiguration(
        onCentre: Length(8 * Length.ticksPerFoot, unit: Unit.foot),
        railsPerSection: 3,
      );
      expect(fence.copyWith(railsPerSection: 2).railsPerSection, 2);
      expect(
        fence
            .copyWith(onCentre: const Length(1, unit: Unit.foot))
            .onCentre
            .ticks,
        1,
      );
      expect(fence.copyWith(), fence);
      final rails = int.parse('3');
      expect(
        FenceConfiguration(
          onCentre: const Length(8 * Length.ticksPerFoot, unit: Unit.foot),
          railsPerSection: rails,
        ),
        fence,
      );
    });
  });

  group('StoredRate', () {
    test('starts with no waste and copies by value', () {
      const rate = StoredRate(unit: RateUnit.squareFoot, rate: 12.3);
      expect(rate.wastePercent, 0);
      final withWaste = rate.copyWith(
        wastePercent: 10,
        rate: 13,
        unit: RateUnit.squareYard,
      );
      expect(
        withWaste,
        const StoredRate(unit: RateUnit.squareYard, rate: 13, wastePercent: 10),
      );
      expect(rate.copyWith(), rate);
      expect(RateUnit.values, hasLength(9));
    });
  });

  group('StoredDensity', () {
    test('copies and compares by value', () {
      const concrete = StoredDensity(
        name: 'concrete',
        poundsPerCubicYard: 4050,
        position: 0,
      );
      final stored = concrete.copyWith(
        id: 'd-1',
        name: 'Concrete',
        poundsPerCubicYard: 4000,
        position: 2,
      );
      expect(
        stored,
        const StoredDensity(
          id: 'd-1',
          name: 'Concrete',
          poundsPerCubicYard: 4000,
          position: 2,
        ),
      );
      expect(concrete.copyWith(), concrete);
      final position = int.parse('0');
      expect(
        StoredDensity(
          name: 'concrete',
          poundsPerCubicYard: 4050,
          position: position,
        ),
        concrete,
      );
    });
  });
}
