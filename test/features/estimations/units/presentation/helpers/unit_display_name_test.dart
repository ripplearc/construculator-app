import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/helpers/unit_display_name.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  const expectedNames = {
    Unit.pieces: 'Pieces',
    Unit.meters: 'Meters',
    Unit.squareMeters: 'Square meters',
    Unit.cubicMeters: 'Cubic meters',
    Unit.kilograms: 'Kilograms',
    Unit.tons: 'Tons',
    Unit.liters: 'Liters',
    Unit.hours: 'Hours',
    Unit.days: 'Days',
    Unit.boxes: 'Boxes',
    Unit.bags: 'Bags',
    Unit.rolls: 'Rolls',
    Unit.sheets: 'Sheets',
  };

  test('names every unit', () {
    expect(expectedNames.keys, unorderedEquals(Unit.values));
  });

  for (final entry in expectedNames.entries) {
    test('names ${entry.key.name} as ${entry.value}', () {
      expect(entry.key.displayName(l10n), entry.value);
    });
  }
}
