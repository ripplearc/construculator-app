import 'package:construculator/features/estimation/presentation/helpers/cost_file_changed_item_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CostFileChangedItemParser.singleFrom', () {
    test('reads the name and both rates of a single change', () {
      final change = CostFileChangedItemParser.singleFrom({
        'changedItems': [
          {'itemName': 'Drywall sheets', 'oldRate': 14, 'newRate': 14.5},
        ],
      });

      expect(
        change,
        isA<CostFileChangedItem>()
            .having((c) => c.itemName, 'itemName', 'Drywall sheets')
            .having((c) => c.oldRate, 'oldRate', 14)
            .having((c) => c.newRate, 'newRate', 14.5),
      );
    });

    test('leaves out a name or rate that has the wrong type', () {
      final change = CostFileChangedItemParser.singleFrom({
        'changedItems': [
          {'itemName': 7, 'oldRate': '14', 'newRate': 14.5},
        ],
      });

      expect(
        change,
        isA<CostFileChangedItem>()
            .having((c) => c.itemName, 'itemName', isNull)
            .having((c) => c.oldRate, 'oldRate', isNull)
            .having((c) => c.newRate, 'newRate', 14.5),
      );
    });

    final shapesWithoutOneChange = <String, Map<String, dynamic>>{
      'no changedItems': {},
      'changedItems that is not a list': {'changedItems': 'Drywall sheets'},
      'an empty changedItems': {'changedItems': <dynamic>[]},
      'several changes': {
        'changedItems': [
          {'itemName': 'Drywall sheets', 'oldRate': 14, 'newRate': 14.5},
          {'itemName': 'Seam tape', 'oldRate': 8.5, 'newRate': 9},
        ],
      },
      'a change that is not a map': {
        'changedItems': ['Drywall sheets'],
      },
    };
    for (final shape in shapesWithoutOneChange.entries) {
      test('returns null for ${shape.key}', () {
        expect(CostFileChangedItemParser.singleFrom(shape.value), isNull);
      });
    }
  });
}
