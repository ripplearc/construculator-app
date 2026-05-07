import 'dart:convert';

import 'package:construculator/libraries/logging/app_logger.dart';

/// Utility class for parsing JWT tokens
class JwtParser {
  static final _logger = AppLogger().tag('JwtParser');

  /// Parse JWT token and extract payload
  ///
  /// Returns the decoded payload as a Map, or null if parsing fails.
  /// Handles base64 URL decoding with proper padding normalization.
  ///
  /// Example:
  /// ```dart
  /// final payload = JwtParser.parsePayload(token);
  /// if (payload != null) {
  ///   final userId = payload['user_id'];
  /// }
  /// ```
  static Map<String, dynamic>? parsePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        _logger.warning(
          'Invalid JWT format: expected 3 parts, got ${parts.length}',
        );
        return null;
      }

      final payload = parts[1];
      var normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      _logger.warning('Failed to parse JWT: $e');
      return null;
    }
  }
}
