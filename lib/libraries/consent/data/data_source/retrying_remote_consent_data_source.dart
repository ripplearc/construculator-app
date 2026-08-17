import 'dart:async';
import 'dart:io';

import 'package:construculator/libraries/consent/data/data_source/interfaces/remote_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/models/consent_version_dto.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

/// Adds bounded retry to another [RemoteConsentDataSource].
///
/// A decorator rather than logic inside the repository: how many times to
/// re-ask the network is a property of the transport, while the repository's
/// job is deciding what an answer *means*. Keeping them apart means the retry
/// policy can change without touching the gate decision, and the repository's
/// failure handling can be read without stepping through a backoff loop.
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

  /// Attempts after the first before giving up.
  static const _maxRetries = 3;

  /// Delay before each retry. Short enough that a user opening the app on a
  /// flaky connection still gets a verified answer within a few seconds.
  static const _backoff = [
    Duration(milliseconds: 250),
    Duration(seconds: 1),
    Duration(seconds: 2),
  ];

  const RetryingRemoteConsentDataSource(this._inner);

  @override
  Future<List<ConsentVersionDto>> fetchPublishedVersions() async {
    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        return await _inner.fetchPublishedVersions();
      } catch (error) {
        if (!_isTransient(error) || attempt == _maxRetries) rethrow;
        await Future<void>.delayed(_backoff[attempt]);
      }
    }

    throw StateError(
      'unreachable: the loop returns or rethrows on the final attempt',
    );
  }

  /// Postgres connection-level codes: cannot connect, cannot establish, and
  /// unable to connect now. All three describe the server, not the request.
  static const _transientPostgrestCodes = {'08000', '08003', '08006'};

  // Whether [error] is worth another attempt.
  bool _isTransient(Object error) =>
      error is TimeoutException ||
      error is SocketException ||
      error is HttpException ||
      (error is PostgrestException &&
          _transientPostgrestCodes.contains(error.code));
}
