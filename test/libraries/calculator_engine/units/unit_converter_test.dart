import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const converter = UnitConverter();

  List<Unit> unitsOf(List<Quantity> offers) => [
    for (final offer in offers)
      switch (offer) {
        Length() => offer.unit,
        Area() => offer.unit,
        Volume() => offer.unit,
        Weight() => offer.unit,
        Angle() || Scalar() => throw StateError('no unit'),
      },
  ];

  group('UnitConverter', () {
    group('offersFor a length', () {
      test('offers 22ft as inches, yards and metres with the same ticks', () {
        const length = Length(16896, unit: Unit.foot);
        final offers = converter.offersFor(length);
        expect(unitsOf(offers), [Unit.inch, Unit.yard, Unit.metre]);
        expect(
          offers,
          everyElement(isA<Length>().having((l) => l.ticks, 'ticks', 16896)),
        );
      });

      test('offers a ft-in compound as inches and metres', () {
        final offers = converter.offersFor(
          const Length(14336, unit: Unit.footInch),
        );
        expect(unitsOf(offers), [Unit.inch, Unit.metre]);
      });

      test('offers inches as the compound first, then millimetres', () {
        final offers = converter.offersFor(
          const Length(16896, unit: Unit.inch),
        );
        expect(unitsOf(offers), [Unit.footInch, Unit.millimetre]);
      });

      test('offers yards as the compound and metres', () {
        final offers = converter.offersFor(const Length(2304, unit: Unit.yard));
        expect(unitsOf(offers), [Unit.footInch, Unit.metre]);
      });

      test('offers metres as the compound and inches', () {
        final offers = converter.offersFor(
          const Length(2520, unit: Unit.metre),
        );
        expect(unitsOf(offers), [Unit.footInch, Unit.inch]);
      });

      test('offers nothing for centimetres and millimetres', () {
        expect(
          converter.offersFor(const Length(25, unit: Unit.centimetre)),
          isEmpty,
        );
        expect(
          converter.offersFor(const Length(3, unit: Unit.millimetre)),
          isEmpty,
        );
      });
    });

    group('offersFor an area', () {
      const squareTicksPerSquareFoot =
          Area.squareTicksPerSquareInch * Area.squareInchesPerSquareFoot;

      test('offers 16,000ft² in yd², in², m² and, being a lot, acres', () {
        const area = Area(16000.0 * squareTicksPerSquareFoot);
        final offers = converter.offersFor(area);
        expect(unitsOf(offers), [Unit.yard, Unit.inch, Unit.metre, Unit.acre]);
        expect(
          offers,
          everyElement(
            isA<Area>().having(
              (a) => a.squareTicks,
              'squareTicks',
              area.squareTicks,
            ),
          ),
        );
      });

      test('leaves acres out of a 180ft² wall', () {
        const area = Area(180.0 * squareTicksPerSquareFoot);
        expect(unitsOf(converter.offersFor(area)), [
          Unit.yard,
          Unit.inch,
          Unit.metre,
        ]);
      });

      test('offers acres from exactly 0.005 acre', () {
        const area = Area(
          0.005 * Area.squareFeetPerAcre * squareTicksPerSquareFoot,
        );
        expect(unitsOf(converter.offersFor(area)), contains(Unit.acre));
      });

      test('leaves the typed unit out: 2in² is offered in ft², yd², m²', () {
        const area = Area(2.0 * Area.squareTicksPerSquareInch, unit: Unit.inch);
        expect(unitsOf(converter.offersFor(area)), [
          Unit.foot,
          Unit.yard,
          Unit.metre,
        ]);
      });

      test('offers an area in acres back in the four square units', () {
        const area = Area(
          1.0 * Area.squareFeetPerAcre * squareTicksPerSquareFoot,
          unit: Unit.acre,
        );
        expect(unitsOf(converter.offersFor(area)), [
          Unit.foot,
          Unit.yard,
          Unit.inch,
          Unit.metre,
        ]);
      });
    });

    group('offersFor a volume', () {
      test('offers ft³ in yd³, m³ and board feet with the same cubic feet', () {
        const volume = Volume(2106);
        final offers = converter.offersFor(volume);
        expect(unitsOf(offers), [Unit.yard, Unit.metre, Unit.boardFoot]);
        expect(
          offers,
          everyElement(
            isA<Volume>().having((v) => v.cubicFeet, 'cubicFeet', 2106),
          ),
        );
      });

      test('leaves out the spelling the value already wears', () {
        const volume = Volume(500 / 12, unit: Unit.boardFoot);
        expect(unitsOf(converter.offersFor(volume)), [
          Unit.foot,
          Unit.yard,
          Unit.metre,
        ]);
      });
    });

    group('offersFor a weight', () {
      test('offers each weight unit the readings Section 6 lists', () {
        const expected = {
          Unit.pound: [Unit.kilogram, Unit.ton],
          Unit.kilogram: [Unit.pound, Unit.metricTon],
          Unit.ton: [Unit.pound, Unit.kilogram, Unit.metricTon],
          Unit.metricTon: [Unit.ton, Unit.kilogram, Unit.pound],
        };
        for (final entry in expected.entries) {
          final offers = converter.offersFor(Weight(7800, unit: entry.key));
          expect(unitsOf(offers), entry.value, reason: entry.key.name);
          expect(
            offers,
            everyElement(
              isA<Weight>().having(
                (w) => w.hundredthsOfPound,
                'hundredthsOfPound',
                7800,
              ),
            ),
          );
        }
      });
    });

    test('offers nothing for an angle or a scalar', () {
      expect(converter.offersFor(const Angle(26.57)), isEmpty);
      expect(converter.offersFor(const Scalar(78)), isEmpty);
    });
  });
}
