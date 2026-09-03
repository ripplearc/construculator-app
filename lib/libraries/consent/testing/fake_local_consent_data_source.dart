import 'dart:async';

import 'package:construculator/libraries/consent/data/data_source/in_memory_local_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/data_source/interfaces/local_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/models/consent_version_dto.dart';
import 'package:construculator/libraries/consent/data/models/user_consent_dto.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';

/// Fake [LocalConsentDataSource] for testing the consent repository.
///
/// Wraps [InMemoryLocalConsentDataSource] rather than reimplementing storage:
/// the two stores would otherwise diverge on filtering, history, and the
/// watch stream's emit-on-write behaviour, and only one of them would be
/// under test. This class contributes only what the real store has no
/// reason to expose — error injection and a record of what was written.
class FakeLocalConsentDataSource implements LocalConsentDataSource {
  /// Published versions keyed by type. Absent means the requirement is
  /// unknown. Read directly by [fetchPublishedVersion], so mutating this map
  /// is visible to reads without needing a setter.
  final Map<ConsentType, ConsentVersionDto> publishedVersions = {};

  /// Error thrown by [fetchPublishedVersion].
  Object? publishedVersionReadError;

  /// Errors thrown by successive [fetchPublishedVersion] calls, one per call,
  /// in order. A null entry lets that one call succeed.
  ///
  /// Takes priority over [publishedVersionReadError] for as many calls as it
  /// has entries; once exhausted, later calls fall back to it. The counter is
  /// shared by every caller of [fetchPublishedVersion] in call order — both
  /// the ticks behind [watchLatestUserConsent] and one-shot reads such as
  /// `ConsentRepositoryImpl.getCachedConsentStatus` consume the same
  /// sequence, so a test mixing both call styles must account for the
  /// combined order. For watch ticks specifically, this is the lever that
  /// fails one tick and then clears — the "superseded by the next successful
  /// one" half of `ConsentRepository.watchConsentStatus`'s contract, which
  /// the sticky field above cannot express because it also fails every later
  /// tick. Mirrors `FakeRemoteConsentDataSource`'s `errorSequence`, for the
  /// same reason.
  final List<Object?> publishedVersionReadErrorSequence = [];

  /// Error thrown by [fetchLatestUserConsent].
  ///
  /// Kept separate from [publishedVersionReadError] because
  /// `ConsentRepositoryImpl` reads both in the same call and maps failures at
  /// each site to its own log message: one field could not fail one read
  /// without also failing the other.
  Object? latestConsentReadError;

  /// Error thrown by [insertUserConsent].
  Object? writeError;

  /// Error emitted on the [watchLatestUserConsent] stream itself, ahead of
  /// the wrapped store's events.
  ///
  /// Distinct from [publishedVersionReadErrorSequence], which fails the read
  /// behind a tick while the stream stays healthy. This drives the stream
  /// error path instead — reached only by a genuine watch failure, and
  /// otherwise unreachable through this fake.
  Object? watchError;

  /// Error thrown by [dispose].
  Object? disposeError;

  /// Records passed to [insertUserConsent], in call order. Excludes records
  /// seeded through [seedLatestConsent].
  final List<UserConsentDto> insertedRecords = [];

  var _publishedVersionReadCount = 0;

  late final InMemoryLocalConsentDataSource _store =
      InMemoryLocalConsentDataSource();

  /// Stores [record] as if it were already on file, without counting as a
  /// write in [insertedRecords].
  ///
  /// Goes through the wrapped store rather than a separate map, so it also
  /// drives [watchLatestUserConsent] the way a real prior write would.
  Future<void> seedLatestConsent(UserConsentDto record) =>
      _store.insertUserConsent(record);

  @override
  Future<ConsentVersionDto?> fetchPublishedVersion(ConsentType type) async {
    final index = _publishedVersionReadCount++;
    final error = index < publishedVersionReadErrorSequence.length
        ? publishedVersionReadErrorSequence[index]
        : publishedVersionReadError;
    if (error != null) throw error;
    return publishedVersions[type];
  }

  @override
  Future<UserConsentDto?> fetchLatestUserConsent(
    String userId,
    ConsentType type,
  ) async {
    final error = latestConsentReadError;
    if (error != null) throw error;
    return _store.fetchLatestUserConsent(userId, type);
  }

  @override
  Stream<UserConsentDto?> watchLatestUserConsent(
    String userId,
    ConsentType type,
  ) {
    final error = watchError;
    if (error == null) return _store.watchLatestUserConsent(userId, type);

    // Emitted ahead of the store's own events rather than replacing them, so
    // a test can assert the repository survives the error and still resolves
    // the ticks that follow it.
    return Stream<UserConsentDto?>.multi((controller) {
      controller.addError(error);
      final subscription = _store
          .watchLatestUserConsent(userId, type)
          .listen(
            controller.add,
            onError: controller.addError,
            onDone: controller.close,
          );
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<UserConsentDto> insertUserConsent(UserConsentDto dto) async {
    final error = writeError;
    if (error != null) throw error;

    insertedRecords.add(dto);
    return _store.insertUserConsent(dto);
  }

  @override
  Future<void> dispose() async {
    final error = disposeError;
    if (error != null) throw error;
    return _store.dispose();
  }
}
