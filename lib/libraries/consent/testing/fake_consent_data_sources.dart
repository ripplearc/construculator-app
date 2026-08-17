import 'dart:async';

import 'package:construculator/libraries/consent/data/data_source/interfaces/local_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/data_source/interfaces/remote_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/models/consent_version_dto.dart';
import 'package:construculator/libraries/consent/data/models/user_consent_dto.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';

/// Fake [LocalConsentDataSource] for testing the consent repository.
///
/// Fakes at the storage boundary rather than at the repository, so the
/// repository's own comparison and failure-mapping logic stays under test.
class FakeLocalConsentDataSource implements LocalConsentDataSource {
  /// Published versions keyed by type. Absent means the requirement is unknown.
  final Map<ConsentType, ConsentVersionDto> publishedVersions = {};

  /// Newest consent record keyed by type. Absent means nothing on file.
  final Map<ConsentType, UserConsentDto> latestConsents = {};

  /// Error thrown by [fetchPublishedVersion] and [fetchLatestUserConsent].
  Object? readError;

  /// Error thrown by [insertUserConsent].
  Object? writeError;

  /// Records passed to [insertUserConsent], in call order.
  final List<UserConsentDto> insertedRecords = [];

  final StreamController<UserConsentDto?> _watchController =
      StreamController<UserConsentDto?>.broadcast();

  /// Pushes [record] to listeners of [watchLatestUserConsent].
  void emitLatestConsent(UserConsentDto? record) =>
      _watchController.add(record);

  /// Pushes an error to listeners of [watchLatestUserConsent].
  void emitWatchError(Object error) => _watchController.addError(error);

  @override
  Future<ConsentVersionDto?> fetchPublishedVersion(ConsentType type) async {
    final error = readError;
    if (error != null) throw error;
    return publishedVersions[type];
  }

  @override
  Future<UserConsentDto?> fetchLatestUserConsent(
    String userId,
    ConsentType type,
  ) async {
    final error = readError;
    if (error != null) throw error;
    return latestConsents[type];
  }

  @override
  Stream<UserConsentDto?> watchLatestUserConsent(
    String userId,
    ConsentType type,
  ) => Stream.multi((controller) {
    // Stream.multi's callback runs synchronously on listen, unlike an
    // async* generator's first yield, which resumes on a later microtask.
    // A synchronous emit right after subscribing must land on this
    // listener rather than being lost to a broadcast stream it hasn't
    // subscribed to yet.
    controller.add(latestConsents[type]);
    final subscription = _watchController.stream.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = subscription.cancel;
  });

  @override
  Future<UserConsentDto> insertUserConsent(UserConsentDto dto) async {
    final error = writeError;
    if (error != null) throw error;

    insertedRecords.add(dto);
    final stored = UserConsentDto(
      id: 'stored-${insertedRecords.length}',
      userId: dto.userId,
      consentType: dto.consentType,
      version: dto.version,
      action: dto.action,
      recordedAt: dto.recordedAt,
      appVersion: dto.appVersion,
      platform: dto.platform,
    );
    latestConsents[dto.consentType] = stored;
    return stored;
  }

  @override
  Future<void> dispose() => _watchController.close();
}

/// Fake [RemoteConsentDataSource] for testing verification and its retries.
class FakeRemoteConsentDataSource implements RemoteConsentDataSource {
  /// Versions returned once the fake stops throwing.
  List<ConsentVersionDto> publishedVersions = [];

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

    return publishedVersions;
  }
}
