import 'package:construculator/features/estimation/presentation/helpers/trimmed_number_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatTrimmedNumber', () {
    test('shows a whole number without decimals', () {
      expect(formatTrimmedNumber(3), '3');
    });

    test('shows zero without decimals', () {
      expect(formatTrimmedNumber(0), '0');
    });

    test('keeps every decimal a number has', () {
      expect(formatTrimmedNumber(2.55), '2.55');
    });
  });
}
