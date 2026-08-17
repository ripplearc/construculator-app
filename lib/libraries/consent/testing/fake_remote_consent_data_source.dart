import 'package:construculator/libraries/consent/data/data_source/interfaces/remote_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/models/consent_version_dto.dart';

/// Fake [RemoteConsentDataSource] for testing verification and its retries.
class FakeRemoteConsentDataSource implements RemoteConsentDataSource {
  /// Versions returned once the fake stops throwing.
  List<ConsentVersionDto> publishedVersionsToReturn = [];

  /// Thrown on every call while set.
  ///
  /// Use with [failuresBeforeSuccess] to model a connection that recovers.
  Object? error;

  /// How many calls throw [error] before the fake starts succeeding.
  ///
  /// Null means every call throws, which is how retry exhaustion is exercised.
  int? failuresBeforeSuccess;

  /// Errors to throw on successive calls, one per call, in order.
  ///
  /// Takes priority over [error]/[failuresBeforeSuccess] for as many calls as
  /// it has entries; once exhausted, later calls fall back to that pair. Use
  /// this to model a transient failure followed by a different, non-transient
  /// one — something a single [error] can't express.
  final List<Object> errorSequence = [];

  /// Delay before each successive call resolves (or throws), one per call.
  ///
  /// Once exhausted, later calls resolve immediately. Use this to model an
  /// attempt that stalls past a caller's timeout.
  final List<Duration> delaySequence = [];

  /// Number of times [fetchPublishedVersions] has been called.
  var callCount = 0;

  @override
  Future<List<ConsentVersionDto>> fetchPublishedVersions() async {
    final index = callCount;
    callCount++;

    if (index < delaySequence.length) {
      await Future<void>.delayed(delaySequence[index]);
    }

    if (index < errorSequence.length) {
      throw errorSequence[index];
    }

    final thrown = error;
    if (thrown != null) {
      final limit = failuresBeforeSuccess;
      if (limit == null || callCount <= limit) throw thrown;
    }

    return publishedVersionsToReturn;
  }
}
