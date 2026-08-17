import 'dart:async';
import 'dart:io';

import 'package:construculator/libraries/consent/data/data_source/interfaces/remote_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/models/consent_version_dto.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

/// Adds bounded retry to another [RemoteConsentDataSource].
///
/// A decorator rather than logic inside the repository: how many times to
/// re-ask the network is a property of the transport, while the repository's
/// job is deciding what an answer *means*. Keeping them apart means the retry
/// policy can change without touching the gate decision, and the repository's
/// failure handling can be read without stepping through a backoff loop.
///
/// The single owner of retry for this query: `SupabaseConsentDataSource`
/// disables PostgREST's own retry (`retry: false`) so the two budgets don't
/// compound into up to 16 requests for one version check.
///
/// Retries only conditions that can plausibly clear on their own. A parse
/// failure or a permission denial fails identically every time, so retrying
/// them only delays the answer the caller is waiting on.
///
/// Exhausted retries rethrow. The caller decides what an unreachable server
/// means — for consent it is an expected condition on a mobile network, not an
/// error to surface.
class RetryingRemoteConsentDataSource implements RemoteConsentDataSource {
  final RemoteConsentDataSource _inner;
  final List<Duration> _backoff;
  final Duration _attemptTimeout;

  /// Delay before each retry. Short enough that a user opening the app on a
  /// flaky connection still gets an answer within roughly
  /// `attemptTimeout * (backoff.length + 1) + sum(backoff)`.
  static const _defaultBackoff = [
    Duration(milliseconds: 250),
    Duration(seconds: 1),
    Duration(seconds: 2),
  ];

  /// How long a single attempt is given before it counts as a failure worth
  /// retrying. Nothing downstream imposes one on its own: `selectMatch` has
  /// no `.timeout()` of its own, so a stalled connection would otherwise hang
  /// instead of failing.
  static const _defaultAttemptTimeout = Duration(seconds: 3);

  const RetryingRemoteConsentDataSource(
    this._inner, {
    this._backoff = _defaultBackoff,
    this._attemptTimeout = _defaultAttemptTimeout,
  });

  @override
  Future<List<ConsentVersionDto>> fetchPublishedVersions() async {
    for (final delay in _backoff) {
      try {
        return await _inner.fetchPublishedVersions().timeout(_attemptTimeout);
      } catch (error) {
        if (!_isTransient(error)) rethrow;
        await Future<void>.delayed(delay);
      }
    }
    return await _inner.fetchPublishedVersions().timeout(_attemptTimeout);
  }

  /// Postgres connection-level codes: cannot connect, cannot establish, and
  /// unable to connect now. All three describe the server, not the request.
  static const _transientPostgrestCodes = {'08000', '08003', '08006'};

  // Whether [error] is worth another attempt.
  //
  // http.ClientException, not HttpException: IOClient converts dart:io's
  // HttpException into a plain ClientException before it ever escapes the
  // HTTP layer, so the mid-flight-drop case ("Connection closed before full
  // header was received") only matches this type. SocketException still
  // matches directly — IOClient's _ClientSocketException implements it.
  bool _isTransient(Object error) =>
      error is TimeoutException ||
      error is SocketException ||
      error is http.ClientException ||
      (error is PostgrestException &&
          _transientPostgrestCodes.contains(error.code));
}
