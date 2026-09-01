import 'dart:async';

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

  /// Number of times [fetchPublishedVersions] has been called.
  var callCount = 0;

  @override
  Future<List<ConsentVersionDto>> fetchPublishedVersions() async {
    callCount++;

    final thrown = error;
    if (thrown != null) {
      final limit = failuresBeforeSuccess;
      if (limit == null || callCount <= limit) throw thrown;
    }

    return publishedVersionsToReturn;
  }
}
