import 'dart:async';

import 'package:construculator/libraries/consent/data/data_source/interfaces/local_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/models/consent_version_dto.dart';
import 'package:construculator/libraries/consent/data/models/user_consent_dto.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';

/// Fake [LocalConsentDataSource] for testing the consent repository.
///
/// Holds its own records rather than delegating to a second in-memory store.
/// It used to wrap `InMemoryLocalConsentDataSource`, which was production
/// code standing in for the real store until CA-971 landed
/// `PowerSyncLocalConsentDataSource`. Once that binding changed, the wrapped
/// class had exactly one caller left — this one — and its remaining half was
/// published-version seeding this fake never used, since
/// [fetchPublishedVersion] has always read [publishedVersions] directly.
/// Keeping it alive as an indirection nothing else reached would have been
/// two classes' worth of storage in one place.
///
/// This is not the duplication that wrapping avoided. There is one in-memory
/// consent store in the repo now, and it is here, where test doubles live.
/// The real store keeps its history in PowerSync and shares no code with it.
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
  /// the store's own events.
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

  /// Every record held, in insertion order. Never pruned: the list is bounded
  /// by the length of one test.
  final List<UserConsentDto> _records = [];

  final StreamController<void> _changes = StreamController<void>.broadcast();

  var _nextId = 0;

  /// Stores [record] as if it were already on file, without counting as a
  /// write in [insertedRecords].
  ///
  /// Goes through the same append as a write, so it also drives
  /// [watchLatestUserConsent] the way a real prior write would.
  Future<void> seedLatestConsent(UserConsentDto record) async {
    _append(record);
  }

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
    return _latest(userId, type);
  }

  @override
  Stream<UserConsentDto?> watchLatestUserConsent(
    String userId,
    ConsentType type,
  ) {
    // `async*`'s `yield` followed by `yield* _changes.stream...` left a
    // one-turn window after listen() where nobody was subscribed to
    // `_changes` yet: a write landing in that window fired into a broadcast
    // controller with no listener and was discarded permanently, with
    // nothing above this class re-polling to recover it. `Stream.multi`
    // attaches the listener to `_changes` synchronously inside the listen()
    // call, closing that window. `.distinct()` then collapses redundant
    // re-emissions from writes that don't change this (userId, type)'s
    // latest record -- e.g. another user's write -- back down to the single
    // emission callers expect.
    //
    // PowerSyncLocalConsentDataSource needs only the second half of that:
    // sqlite_async's own watch() already subscribes inside listen(), so it
    // has no window to close.
    final error = watchError;
    final records = Stream<UserConsentDto?>.multi((controller) {
      controller.add(_latest(userId, type));
      final subscription = _changes.stream.listen(
        (_) => controller.add(_latest(userId, type)),
        onDone: controller.close,
      );
      controller.onCancel = subscription.cancel;
    }).distinct();

    if (error == null) return records;

    // Emitted ahead of the store's own events rather than replacing them, so
    // a test can assert the repository survives the error and still resolves
    // the ticks that follow it.
    return Stream<UserConsentDto?>.multi((controller) {
      controller.addError(error);
      final subscription = records.listen(
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
    return _append(dto);
  }

  @override
  Future<void> dispose() async {
    final error = disposeError;
    if (error != null) throw error;
    return _changes.close();
  }

  UserConsentDto _append(UserConsentDto dto) {
    final stored = UserConsentDto.stored(
      id: 'fake-local-${_nextId++}',
      userId: dto.userId,
      consentType: dto.consentType,
      version: dto.version,
      action: dto.action,
      recordedAt: dto.recordedAt,
      appVersion: dto.appVersion,
      platform: dto.platform,
    );

    _records.add(stored);
    // A write can still be in flight when the module tears down and calls
    // dispose, and adding to a closed controller throws. The record is kept
    // either way; only the notification is dropped, and there is no listener
    // left to receive it.
    if (!_changes.isClosed) _changes.add(null);
    return stored;
  }

  // The newest record for the pair, resolved by insertion order rather than
  // by comparing recordedAt. One process appending through one clock, so
  // insertion order and recordedAt order coincide, and insertion order
  // additionally resolves two records written in the same instant --
  // together, the recordedAt-ordered contract LocalConsentDataSource states.
  // The real store gets the same two properties from a recordedAt comparison
  // with the primary key as tie-break.
  UserConsentDto? _latest(String userId, ConsentType type) {
    for (final record in _records.reversed) {
      if (record.userId == userId && record.consentType == type) return record;
    }
    return null;
  }
}
