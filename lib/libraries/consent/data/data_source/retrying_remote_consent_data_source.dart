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
/// them only delays the answer the caller is waiting on. Transient means a
/// timeout, a socket failure, an [http.ClientException], or one of the
/// Postgres connection-level codes 08000, 08003 and 08006 — all three
/// describe the server rather than the request.
///
/// The HTTP arm matches [http.ClientException] rather than `HttpException`:
/// `IOClient` converts `dart:io`'s `HttpException` into a plain
/// `ClientException` before it ever escapes the HTTP layer, so a mid-flight
/// drop ("Connection closed before full header was received") only surfaces
/// under that type. [SocketException] still matches directly, because
/// `IOClient`'s `_ClientSocketException` implements it.
///
/// The default budget is four attempts, delayed 250ms, 1s and 2s and each
/// capped at 3s, so a user opening the app on a flaky connection still gets an
/// answer within roughly `attemptTimeout * (backoff.length + 1) +
/// sum(backoff)`. The cap has to live here because nothing downstream imposes
/// one: `selectMatch` carries no `.timeout()`, so a stalled connection would
/// hang instead of failing.
///
/// That cap stops the decorator *waiting* on an attempt; it does not cancel
/// it. A genuinely hung request keeps running while the next attempt goes out,
/// so exhausting the budget can leave several requests in flight at once.
///
/// Exhausted retries rethrow. The caller decides what an unreachable server
/// means — for consent it is an expected condition on a mobile network, not an
/// error to surface.
class RetryingRemoteConsentDataSource implements RemoteConsentDataSource {
  final RemoteConsentDataSource _inner;
  final List<Duration> _backoff;
  final Duration _attemptTimeout;

  static const _defaultBackoff = [
    Duration(milliseconds: 250),
    Duration(seconds: 1),
    Duration(seconds: 2),
  ];

  static const _defaultAttemptTimeout = Duration(seconds: 3);

  static const _transientPostgrestCodes = {'08000', '08003', '08006'};

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

  bool _isTransient(Object error) =>
      error is TimeoutException ||
      error is SocketException ||
      error is http.ClientException ||
      (error is PostgrestException &&
          _transientPostgrestCodes.contains(error.code));
}
