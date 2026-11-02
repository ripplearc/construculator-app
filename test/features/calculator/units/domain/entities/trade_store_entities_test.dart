import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const inch = Length.ticksPerInch;
  const sheet = StoredSize(
    id: 'sheet-1',
    store: SizeStore.sheet,
    width: Length(48 * inch, unit: Unit.inch),
    height: Length(96 * inch, unit: Unit.inch),
    position: 0,
  );

  group('StoredSize', () {
    test('copies with fields replaced and keeps the rest', () {
      final metric = sheet.copyWith(
        id: 'sheet-2',
        store: SizeStore.masonry,
        width: const Length(1, unit: Unit.millimetre),
        height: const Length(2, unit: Unit.millimetre),
        position: 3,
        seed: 'masonry_8x16in',
      );
      expect(
        metric,
        const StoredSize(
          id: 'sheet-2',
          store: SizeStore.masonry,
          width: Length(1, unit: Unit.millimetre),
          height: Length(2, unit: Unit.millimetre),
          position: 3,
          seed: 'masonry_8x16in',
        ),
      );
      expect(sheet.copyWith(), sheet);
    });

    test('is equal by value', () {
      final position = int.parse('0');
      expect(
        StoredSize(
          id: 'sheet-1',
          store: SizeStore.sheet,
          width: const Length(48 * inch, unit: Unit.inch),
          height: const Length(96 * inch, unit: Unit.inch),
          position: position,
        ),
        sheet,
      );
      expect(sheet.copyWith(id: null).id, 'sheet-1');
    });

    test('has no id until stored and no seed unless it is a default', () {
      const added = StoredSize(
        store: SizeStore.sheet,
        width: Length(48 * inch, unit: Unit.inch),
        height: Length(96 * inch, unit: Unit.inch),
        position: 0,
      );
      expect(added.id, isNull);
      expect(added.seed, isNull);
      expect(sheet.copyWith(seed: 'sheet_48x96in').seed, 'sheet_48x96in');
    });

    test('a size spelled in millimetres keeps its unit', () {
      const metric = StoredSize(
        store: SizeStore.sheet,
        width: Length(3024, unit: Unit.millimetre),
        height: Length(6047, unit: Unit.millimetre),
        position: 0,
        seed: 'sheet_1200x2400mm',
      );
      expect(metric.width.unit, Unit.millimetre);
      expect(
        metric,
        isNot(metric.copyWith(width: const Length(3024, unit: Unit.inch))),
      );
    });
  });

  group('StoredSpacing', () {
    test('copies and compares by value', () {
      const spacing = StoredSpacing(
        spacing: Length(16 * inch, unit: Unit.inch),
        position: 0,
      );
      final stored = spacing.copyWith(
        id: 'oc-1',
        position: 1,
        seed: 'spacing_16in',
      );
      expect(stored.id, 'oc-1');
      expect(stored.position, 1);
      expect(stored.seed, 'spacing_16in');
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
      expect(spacing.id, isNull);
      expect(spacing.seed, isNull);
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

  group('StoredWaste', () {
    test('starts at 0% and copies by value', () {
      const waste = StoredWaste(unit: RateUnit.squareFoot);
      expect(waste.percent, 0);
      final edited = waste.copyWith(percent: 10, unit: RateUnit.squareYard);
      expect(edited, const StoredWaste(unit: RateUnit.squareYard, percent: 10));
      expect(waste.copyWith(), waste);
      expect(RateUnit.values, hasLength(9));
    });
  });

  group('StoredDensity', () {
    test('copies and compares by value', () {
      const concrete = StoredDensity(
        name: 'concrete',
        poundsPerCubicYard: 4050,
        position: 0,
        seed: 'density_concrete',
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
          seed: 'density_concrete',
        ),
      );
      expect(concrete.copyWith(), concrete);
      final position = int.parse('0');
      expect(
        StoredDensity(
          name: 'concrete',
          poundsPerCubicYard: 4050,
          position: position,
          seed: 'density_concrete',
        ),
        concrete,
      );
      expect(concrete.id, isNull);
    });
  });
}
