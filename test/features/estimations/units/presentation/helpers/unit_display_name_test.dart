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
    const expectedSymbols = {
      Unit.pieces: 'ea',
      Unit.meters: 'm',
      Unit.squareMeters: 'sqm',
      Unit.cubicMeters: 'cbm',
      Unit.kilograms: 'kg',
      Unit.tons: 't',
      Unit.liters: 'l',
      Unit.hours: 'hr',
      Unit.days: 'day',
      Unit.boxes: 'bx',
      Unit.bags: 'bag',
      Unit.rolls: 'rl',
      Unit.sheets: 'sht',
      Unit.feet: 'ft',
      Unit.inches: 'in',
      Unit.yards: 'yd',
      Unit.linearFeet: 'lf',
      Unit.squareFeet: 'sf',
      Unit.squareYards: 'sy',
      Unit.squares: 'sq',
      Unit.cubicFeet: 'cf',
      Unit.cubicYards: 'cy',
      Unit.gallons: 'gal',
      Unit.pounds: 'lb',
      Unit.shortTons: 'tn',
      Unit.pairs: 'pr',
      Unit.dozens: 'dz',
      Unit.bundles: 'bdl',
      Unit.pallets: 'plt',
      Unit.tubes: 'tb',
    };

    test('gives every unit a symbol', () {
      expect(expectedSymbols.keys, unorderedEquals(Unit.values));
    });

    for (final entry in expectedSymbols.entries) {
      test('writes ${entry.key.name} as ${entry.value}', () {
        expect(entry.key.symbol(l10n), entry.value);
      });
    }
  });
}
