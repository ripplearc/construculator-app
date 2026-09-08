import 'package:construculator/libraries/router/routes/calculator_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculator_routes', () {
    test('calculatorBaseRoute resolves to expected path', () {
      expect(calculatorBaseRoute, equals('/calculator'));
    });
  });
}
