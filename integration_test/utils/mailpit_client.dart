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
    var sawMessageWithoutCode = false;
    while (DateTime.now().isBefore(deadline)) {
      try {
        final messageId = await _findLatestMessageId(url, email);
        if (messageId != null) {
          final otp = await _extractOtp(url, messageId);
          if (otp != null) return otp;
          sawMessageWithoutCode = true;
        }
      } catch (e) {
        lastFailure = e;
      }
    }
    // "No OTP email arrived" is ambiguous on its own: it reads the same whether
    // the mailbox was empty the whole time or an email showed up that simply
    // had no 6-digit code in it. Dump what Mailpit actually holds now so a CI
    // failure says which of the two happened, rather than leaving it to a guess.
    final mailboxState = await _describeMailboxState(url, email);
    throw StateError(
      'No OTP email arrived for $email within $timeout '
      '(saw a message for this address but no code in it: $sawMessageWithoutCode).'
      '${lastFailure != null ? ' Last polling error: $lastFailure.' : ''}'
      ' Mailpit state at timeout: $mailboxState',
    );
  }

  // A one-line summary of everything Mailpit is holding, plus the full text of
  // any message addressed to the target address. Diagnostic only — called once,
  // on the waitForOtp timeout path, to say whether the mailbox was empty or
  // just held an email with no code in it.
  static Future<String> _describeMailboxState(
    String baseUrl,
    String email,
  ) async {
    try {
      final all = await _getJson(Uri.parse('$baseUrl/api/v1/messages'));
      final messages = (all['messages'] as List?) ?? const [];
      if (messages.isEmpty) return 'mailbox empty (0 messages)';

      final lines = <String>['${messages.length} message(s):'];
      for (final raw in messages) {
        final m = raw as Map<String, dynamic>;
        final to = (m['To'] as List?)
            ?.map((t) => (t as Map<String, dynamic>)['Address'])
            .join(', ');
        lines.add('  - "${m['Subject']}" to $to');
      }

      final mine = await _findLatestMessageId(baseUrl, email);
      if (mine != null) {
        final message = await _getJson(
          Uri.parse('$baseUrl/api/v1/message/$mine'),
        );
        final text = message['Text'] as String? ?? '';
        final html = message['HTML'] as String? ?? '';
        lines.add(
          'body for $email: ${text.isNotEmpty ? text : html.replaceAll(RegExp('<[^>]+>'), ' ')}',
        );
      }
      return lines.join('\n');
    } catch (e) {
      return 'could not read Mailpit state: $e';
    }
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
