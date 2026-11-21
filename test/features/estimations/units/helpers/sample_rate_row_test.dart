import 'package:construculator/features/estimation/presentation/helpers/sample_rate_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('noSampleRates finds nothing until the cost file is read', () {
    expect(noSampleRates('paint'), isEmpty);
  });
}
