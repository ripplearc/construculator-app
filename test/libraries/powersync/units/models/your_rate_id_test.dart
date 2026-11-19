import 'dart:convert';
import 'dart:io';

import 'package:construculator/libraries/powersync/models/your_rate_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final examples =
      (jsonDecode(
                File(
                  'test/libraries/powersync/units/models/your_rate_id_examples.json',
                ).readAsStringSync(),
              )
              as List<dynamic>)
          .cast<Map<String, dynamic>>();

  group('YourRateId', () {
    for (final example in examples) {
      test('gives the shared example "${example['case']}" its expected id', () {
        expect(
          YourRateId.of(
            companyId: example['companyId'] as String,
            category: example['category'] as String,
            itemName: example['itemName'] as String,
            equipmentMethod: example['equipmentMethod'] as String?,
            entryLabel: example['entryLabel'] as String?,
          ),
          example['id'],
        );
      });
    }

    test(
      'is the same for a name in a different case and with extra spaces',
      () {
        String idOf(String name) => YourRateId.of(
          companyId: 'c1',
          category: 'material',
          itemName: name,
        );

        expect(idOf('  Mini   EXCAVATOR '), idOf('mini excavator'));
      },
    );

    test(
      'differs for two rates whose name and label run together the same',
      () {
        final first = YourRateId.of(
          companyId: 'c1',
          category: 'equipment',
          itemName: 'Scissor lift',
          equipmentMethod: 'day',
          entryLabel: 'a|job|b',
        );
        final second = YourRateId.of(
          companyId: 'c1',
          category: 'equipment',
          itemName: 'Scissor lift|day|a',
          equipmentMethod: 'job',
          entryLabel: 'b',
        );

        expect(first, isNot(second));
      },
    );

    test('differs for a day rate and a job price of the same name', () {
      String idOf(String method) => YourRateId.of(
        companyId: 'c1',
        category: 'equipment',
        itemName: 'Scissor lift',
        equipmentMethod: method,
      );

      expect(idOf('day'), isNot(idOf('job')));
    });
  });
}
