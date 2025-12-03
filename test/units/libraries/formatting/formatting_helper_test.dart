import 'package:construculator/libraries/formatting/formatting_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('de_DE', null);
    await initializeDateFormatting('fr_FR', null);
    await initializeDateFormatting('es_ES', null);
  });

  group('FormattingHelper', () {
    group('formatCurrency', () {
      test('should format currency with default parameters', () {
        expect(FormattingHelper.formatCurrency(15000.50), equals('\$15,000.50'));
        expect(FormattingHelper.formatCurrency(0), equals('\$0.00'));
        expect(FormattingHelper.formatCurrency(1000000), equals('\$1,000,000.00'));
      });

      test('should return default null value when value is null', () {
        expect(FormattingHelper.formatCurrency(null), equals('-'));
      });

      test('should return custom null value when provided', () {
        expect(FormattingHelper.formatCurrency(null, nullValue: 'N/A'), equals('N/A'));
        expect(FormattingHelper.formatCurrency(null, nullValue: '--'), equals('--'));
      });

      test('should format currency with custom symbol', () {
        expect(FormattingHelper.formatCurrency(1000, symbol: '€'), equals('€1,000.00'));
        expect(FormattingHelper.formatCurrency(1000, symbol: '£'), equals('£1,000.00'));
        expect(FormattingHelper.formatCurrency(1000, symbol: '¥'), equals('¥1,000.00'));
      });

      test('should format currency with custom decimal digits', () {
        expect(FormattingHelper.formatCurrency(1000.123, decimalDigits: 0), equals('\$1,000'));
        expect(FormattingHelper.formatCurrency(1000.123, decimalDigits: 1), equals('\$1,000.1'));
        expect(FormattingHelper.formatCurrency(1000.123, decimalDigits: 3), equals('\$1,000.123'));
      });

      test('should format currency with custom locale', () {
        final deResult = FormattingHelper.formatCurrency(1000.50, locale: 'de_DE');
        final frResult = FormattingHelper.formatCurrency(1000.50, locale: 'fr_FR');
        
        expect(deResult, contains('1.000,50'));
        expect(frResult, contains(RegExp(r'1\s*000,50')));
      });

      test('should handle negative values', () {
        expect(FormattingHelper.formatCurrency(-1000.50), equals('-\$1,000.50'));
        expect(FormattingHelper.formatCurrency(-0.50), equals('-\$0.50'));
      });

      test('should combine multiple custom parameters', () {
        final result = FormattingHelper.formatCurrency(
          1000.123,
          symbol: '€',
          decimalDigits: 1,
          locale: 'de_DE',
        );
        expect(result, contains('1.000,1'));
        expect(result, contains('€'));
      });
    });

    group('formatDate', () {
      final testDate = DateTime(2024, 3, 15, 14, 30, 45);

      test('should format date with default pattern', () {
        expect(FormattingHelper.formatDate(testDate), equals('Mar 15, 2024'));
      });

      test('should format date with custom pattern', () {
        expect(FormattingHelper.formatDate(testDate, pattern: 'yyyy-MM-dd'), equals('2024-03-15'));
        expect(FormattingHelper.formatDate(testDate, pattern: 'dd/MM/yyyy'), equals('15/03/2024'));
        expect(FormattingHelper.formatDate(testDate, pattern: 'EEEE, MMMM d, yyyy'), equals('Friday, March 15, 2024'));
        expect(FormattingHelper.formatDate(testDate, pattern: 'MMM d'), equals('Mar 15'));
      });

      test('should format date with custom locale', () {
        final deResult = FormattingHelper.formatDate(testDate, locale: 'de_DE');
        final frResult = FormattingHelper.formatDate(testDate, locale: 'fr_FR');
        final esResult = FormattingHelper.formatDate(testDate, locale: 'es_ES');
        
        expect(deResult, contains('15'));
        expect(deResult, contains('2024'));
        expect(frResult, contains('15'));
        expect(frResult, contains('2024'));
        expect(esResult, contains('15'));
        expect(esResult, contains('2024'));
      });

      test('should combine custom pattern and locale', () {
        final result = FormattingHelper.formatDate(testDate, pattern: 'EEEE, d MMMM yyyy', locale: 'de_DE');
        expect(result, contains('15'));
        expect(result, contains('2024'));
      });

      test('should handle edge cases', () {
        final newYear = DateTime(2024, 1, 1);
        expect(FormattingHelper.formatDate(newYear), equals('Jan 01, 2024'));
        
        final leapYear = DateTime(2024, 2, 29);
        expect(FormattingHelper.formatDate(leapYear), equals('Feb 29, 2024'));
      });
    });

    group('formatTime', () {
      final testTime = DateTime(2024, 3, 15, 14, 30, 45);
      final morningTime = DateTime(2024, 3, 15, 9, 15, 30);
      final midnightTime = DateTime(2024, 3, 15, 0, 0, 0);
      final noonTime = DateTime(2024, 3, 15, 12, 0, 0);

      test('should format time with default pattern', () {
        expect(FormattingHelper.formatTime(testTime), equals('2:30 PM'));
        expect(FormattingHelper.formatTime(morningTime), equals('9:15 AM'));
        expect(FormattingHelper.formatTime(midnightTime), equals('12:00 AM'));
        expect(FormattingHelper.formatTime(noonTime), equals('12:00 PM'));
      });

      test('should format time with custom pattern', () {
        expect(FormattingHelper.formatTime(testTime, pattern: 'HH:mm:ss'), equals('14:30:45'));
        expect(FormattingHelper.formatTime(testTime, pattern: 'HH:mm'), equals('14:30'));
        expect(FormattingHelper.formatTime(testTime, pattern: 'h:mm a'), equals('2:30 PM'));
        expect(FormattingHelper.formatTime(testTime, pattern: 'HH:mm a'), equals('14:30 PM'));
      });

      test('should format time with custom locale', () {
        final deResult = FormattingHelper.formatTime(testTime, locale: 'de_DE');
        final frResult = FormattingHelper.formatTime(testTime, locale: 'fr_FR');
        
        expect(deResult, contains('2:30'));
        expect(frResult, contains('2:30'));
      });

      test('should combine custom pattern and locale', () {
        final result = FormattingHelper.formatTime(testTime, pattern: 'HH:mm', locale: 'de_DE');
        expect(result, equals('14:30'));
      });
    });

    group('Static formatters', () {
      test('should have consistent static formatters', () {
        expect(FormattingHelper.currency.decimalDigits, equals(2));
        
        expect(FormattingHelper.date.pattern, equals('MMM dd, yyyy'));
        
        expect(FormattingHelper.time.pattern, equals('h:mm a'));
      });
    });
  });
}
