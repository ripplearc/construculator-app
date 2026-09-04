import 'dart:convert';
import 'dart:io';

import 'test_config.dart';

/// A minimal client for Mailpit's REST API.
///
/// Registration (CUJ-2) goes through Supabase's passwordless OTP flow, which
/// unconditionally emails a 6-digit code — there is no static test code to
/// substitute, so the suite has to read it out of the real mail round trip.
/// The backend's Supabase config still calls this service `[inbucket]`
/// (the `[local_smtp]` rename lands in a later CLI release than the one
/// pinned here), but the pinned CLI already serves it as Mailpit, and
/// `GET /api/v1/search` / `GET /api/v1/message/{ID}` are Mailpit's endpoints.
///
/// Static-only, mirroring [TestConfig]: it carries no instance state of its
/// own — `baseUrl` is threaded through each call rather than held on an
/// instance — so there is nothing to construct.
class MailpitClient {
  MailpitClient._();

  /// Polls Mailpit for the OTP email sent to [email] and returns the 6-digit
  /// code inside it.
  ///
  /// Bounded by [timeout], measured against the wall clock rather than
  /// `Future.timeout`. Each attempt is a real, awaited HTTP round trip to
  /// Mailpit — there is no `Future.delayed`/`Timer` pacing between attempts,
  /// so the loop never sleeps: it is exactly as fast as the mail actually
  /// arrives, and gives up only once [timeout] has genuinely elapsed.
  static Future<String> waitForOtp(
    String email, {
    String? baseUrl,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final url = baseUrl ?? TestConfig.mailpitUrl;
    final deadline = DateTime.now().add(timeout);
    Object? lastFailure;
    while (DateTime.now().isBefore(deadline)) {
      try {
        final messageId = await _findLatestMessageId(url, email);
        if (messageId != null) {
          final otp = await _extractOtp(url, messageId);
          if (otp != null) return otp;
        }
      } catch (e) {
        lastFailure = e;
      }
    }
    throw StateError(
      'No OTP email arrived for $email within $timeout.'
      '${lastFailure != null ? ' Last polling error: $lastFailure' : ''}',
    );
  }

  static Future<String?> _findLatestMessageId(
    String baseUrl,
    String email,
  ) async {
    final uri = Uri.parse(
      '$baseUrl/api/v1/search',
    ).replace(queryParameters: {'query': 'to:"$email"'});
    final result = await _getJson(uri);
    final messages = result['messages'] as List?;
    if (messages == null || messages.isEmpty) return null;
    return (messages.first as Map<String, dynamic>)['ID'] as String?;
  }

  static Future<String?> _extractOtp(String baseUrl, String messageId) async {
    final uri = Uri.parse('$baseUrl/api/v1/message/$messageId');
    final message = await _getJson(uri);
    final text = message['Text'] as String? ?? '';
    final html = message['HTML'] as String? ?? '';
    final source = text.isNotEmpty
        ? text
        : html.replaceAll(RegExp('<[^>]+>'), ' ');
    return RegExp(r'\b\d{6}\b').firstMatch(source)?.group(0);
  }

  static Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) {
        throw HttpException(
          'Mailpit returned ${response.statusCode} for $uri: $body',
        );
      }
      return jsonDecode(body) as Map<String, dynamic>;
    } finally {
      client.close();
    }
  }
}
