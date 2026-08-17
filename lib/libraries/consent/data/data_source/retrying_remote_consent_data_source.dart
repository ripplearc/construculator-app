import 'package:construculator/libraries/consent/data/consent_error_mapper.dart';
import 'package:construculator/libraries/consent/data/data_source/interfaces/remote_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/models/consent_version_dto.dart';

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
/// Retries only conditions that can plausibly clear on their own, per
/// [ConsentErrorMapper.isTransient]. A parse failure or a permission denial
/// fails identically every time, so retrying them only delays the answer the
/// caller is waiting on. Borrowed rather than reimplemented here so this
/// decorator's retry policy and the mapper's failure taxonomy classify every
/// exception the same way.
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
        if (!ConsentErrorMapper.isTransient(error)) rethrow;
        await Future<void>.delayed(delay);
      }
    }
    return await _inner.fetchPublishedVersions().timeout(_attemptTimeout);
  }
}
