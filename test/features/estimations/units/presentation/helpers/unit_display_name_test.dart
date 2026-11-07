import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/helpers/unit_display_name.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  const expectedNames = {
    Unit.pieces: 'Single units — fixtures',
    Unit.meters: 'Meters',
    Unit.squareMeters: 'Square meters',
    Unit.cubicMeters: 'Cubic meters',
    Unit.kilograms: 'Kilogram',
    Unit.tons: 'Tons',
    Unit.liters: 'Liters',
    Unit.hours: 'Hours',
    Unit.days: 'Days',
    Unit.boxes: 'Box',
    Unit.bags: 'Bag',
    Unit.rolls: 'Roll',
    Unit.sheets: 'Sheet — 4×8 panel goods',
    Unit.feet: 'Foot',
    Unit.inches: 'Inch',
    Unit.yards: 'Yard',
    Unit.linearFeet: 'Linear foot',
    Unit.squareFeet: 'Square foot',
    Unit.squareYards: 'Square yard',
    Unit.squares: 'Square — 100 sq ft',
    Unit.cubicFeet: 'Cubic foot',
    Unit.cubicYards: 'Cubic yard',
    Unit.gallons: 'Gallon — paint, adhesive',
    Unit.pounds: 'Pound — fasteners, compound',
    Unit.shortTons: 'Ton — 2,000 lb',
    Unit.pairs: 'Pair',
    Unit.dozens: 'Dozen',
    Unit.bundles: 'Bundle',
    Unit.pallets: 'Pallet',
    Unit.tubes: 'Tube',
  };

  test('names every unit', () {
    expect(expectedNames.keys, unorderedEquals(Unit.values));
  });

  for (final entry in expectedNames.entries) {
    test('names ${entry.key.name} as ${entry.value}', () {
      expect(entry.key.displayName(l10n), entry.value);
    });
  }

  group('symbol', () {
    test('gives every unit a symbol of its own', () {
      final symbols = {for (final unit in Unit.values) unit.symbol(l10n)};

      expect(symbols, hasLength(Unit.values.length));
    });
  });
}
