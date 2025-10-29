import 'package:intl/intl.dart';

/// Utility class for formatting various data types consistently across the application.
/// 
/// This helper provides static formatters for currency, dates, and times to ensure
/// consistent formatting throughout the app. All formatters are created as static
/// final instances to avoid recreating them on every use.
class FormattingHelper {
  // Private constructor to prevent instantiation
  FormattingHelper._();

  /// Currency formatter for US dollars with 2 decimal places.
  /// 
  /// Example: 15000.50 -> $15,000.50
  static final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  /// Date formatter for displaying dates in a user-friendly format.
  /// 
  /// Example: DateTime(2024, 1, 15) -> "Jan 15, 2024"
  static final date = DateFormat('MMM dd, yyyy');

  /// Time formatter for displaying times in 12-hour format with AM/PM.
  /// 
  /// Example: DateTime(2024, 1, 15, 14, 30) -> "2:30 PM"
  static final time = DateFormat('h:mm a');

  /// Formats a currency value as a string.
  /// 
  /// Returns '-' if the value is null, otherwise formats it as currency.
  /// 
  /// [value] The currency value to format
  /// [symbol] Optional currency symbol (defaults to '$')
  /// [decimalDigits] Number of decimal places (defaults to 2)
  /// [locale] Optional locale for formatting (defaults to 'en_US')
  /// [nullValue] String to return when value is null (defaults to '-')
  static String formatCurrency(
    double? value, {
    String? symbol,
    int? decimalDigits,
    String? locale,
    String? nullValue,
  }) {
    if (value == null) return nullValue ?? '-';
    
    final formatter = NumberFormat.currency(
      symbol: symbol ?? '\$',
      decimalDigits: decimalDigits ?? 2,
      locale: locale ?? 'en_US',
    );
    
    return formatter.format(value);
  }

  /// Formats a date as a string.
  /// 
  /// [date] The date to format
  /// [pattern] Optional date pattern (defaults to 'MMM dd, yyyy')
  /// [locale] Optional locale for formatting (defaults to 'en_US')
  static String formatDate(
    DateTime date, {
    String? pattern,
    String? locale,
  }) {
    final formatter = DateFormat(
      pattern ?? 'MMM dd, yyyy',
      locale ?? 'en_US',
    );
    return formatter.format(date);
  }

  /// Formats a time as a string.
  /// 
  /// [time] The time to format
  /// [pattern] Optional time pattern (defaults to 'h:mm a')
  /// [locale] Optional locale for formatting (defaults to 'en_US')
  static String formatTime(
    DateTime time, {
    String? pattern,
    String? locale,
  }) {
    final formatter = DateFormat(
      pattern ?? 'h:mm a',
      locale ?? 'en_US',
    );
    return formatter.format(time);
  }
}
