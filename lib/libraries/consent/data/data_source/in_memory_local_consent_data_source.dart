import 'dart:async';

import 'package:construculator/libraries/consent/data/data_source/interfaces/local_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/models/consent_version_dto.dart';
import 'package:construculator/libraries/consent/data/models/user_consent_dto.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';

/// Holds consent data in memory for the lifetime of the process.
///
/// **Temporary.** This is a stand-in for the offline-first local store that
/// CA-971 will provide; when that lands, this class is deleted and its binding
/// in `ConsentLibraryModule` points at the real implementation instead.
/// No caller of [LocalConsentDataSource] changes, but the deletion is not a
/// pure rebind: `FakeLocalConsentDataSource` wraps an instance of this class
/// as its storage rather than reimplementing it, so CA-971 must rewrite that
/// shipped test fake too. Those two are the only consumers.
///
/// It is production code rather than a test double — the app genuinely runs on
/// it while the gate is disabled — but it does not persist. Acceptances are
/// lost on restart, which is why the gate stays behind `CONSENT_GATE_ENABLED`
/// until the real store exists: with this source live and the gate on, a user
/// would be re-prompted on every cold start. That direction is the safe one —
/// a lost acceptance resolves to `ConsentNeverGiven`, which gates access.
///
/// The seeded published versions let the whole flow be exercised end to end
/// without a backend, which is what makes the gate demoable before CA-971.
/// Two consequences of seeding, neither of them obvious:
///
/// - **The seeded version is the local answer for the whole process.**
///   [LocalConsentDataSource] has no write path for published versions, so the
///   local published version stays at the fabricated version 1 and can never
///   learn what the backend actually publishes. An in-session acceptance is
///   also version 1, so the local read path — what `CheckConsentStatusUseCase`
///   renders the first frame from — cannot report `ConsentOutdated` at all.
///   Only the network `VerifyConsentStatusUseCase` can surface a newer
///   requirement until CA-971 lands.
/// - **The seeded document URLs are deliberately not live.** They are built on
///   an `.invalid` host (RFC 2606, guaranteed never to resolve) so that a seed
///   can never be mistaken for a real legal document. Pointing them at a
///   plausible-looking real host would mean that, should the flag flip before
///   CA-971, the gate presents a 404 as the terms being agreed to.
///
/// Records accumulate for the lifetime of the process and are never pruned:
/// the list is bounded by session length, which is acceptable for a store
/// whose whole point is that it dies with the process. CA-971's store keeps
/// history in PowerSync instead.
///
/// The newest record for a (userId, type) pair is resolved by insertion order
/// rather than by comparing [UserConsentDto.recordedAt] directly. This source
/// is a single process appending through one clock, so insertion order and
/// `recordedAt` order coincide, and insertion order additionally resolves two
/// records written in the same instant deterministically — together, the
/// `recordedAt`-ordered contract [LocalConsentDataSource] states. CA-971's
/// store gets the same two properties from `order by recorded_at desc` plus a
/// tiebreak, per CA-963 §3.
class InMemoryLocalConsentDataSource implements LocalConsentDataSource {
  final Map<ConsentType, ConsentVersionDto> _publishedVersions;

  final List<UserConsentDto> _records = [];

  final StreamController<void> _changes = StreamController<void>.broadcast();

  var _nextId = 0;

  /// Creates a store seeded with a published version for every [ConsentType].
  ///
  /// [seedVersions] *replaces* those defaults rather than adding to them: a
  /// type absent from an explicit seed reads back as null, not as the default
  /// version 1. Seeding rather than starting empty is what lets the gate
  /// resolve to a real requirement instead of `ConsentIndeterminate` for
  /// every user.
  ///
  /// The map is **aliased, not copied.** A caller that keeps a reference can
  /// add published versions after construction and reads will see them, which
  /// is how `FakeLocalConsentDataSource` exposes a mutable `publishedVersions`
  /// map without needing a setter. Copying defensively here would silently
  /// break it, so the aliasing is a contract rather than an oversight and is
  /// pinned by a test.
  InMemoryLocalConsentDataSource({
    Map<ConsentType, ConsentVersionDto>? seedVersions,
  }) : _publishedVersions = seedVersions ?? _defaultSeed();

  static Map<ConsentType, ConsentVersionDto> _defaultSeed() {
    // UTC rather than local: publishedAt reaches ConsentVersion's props,
    // so a local epoch would compare differently by machine. Same reason
    // as parseTimestampOrEpoch in consent_wire_values.dart.
    final publishedAt = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    return {
      for (final type in ConsentType.values)
        type: ConsentVersionDto(
          id: 'seed-${type.name}',
          consentType: type,
          version: 1,
          documentUrl: 'https://consent-seed.invalid/legal/${type.name}',
          publishedAt: publishedAt,
        ),
    };
  }

  @override
  Future<ConsentVersionDto?> fetchPublishedVersion(ConsentType type) async =>
      _publishedVersions[type];

  @override
  Future<UserConsentDto?> fetchLatestUserConsent(
    String userId,
    ConsentType type,
  ) async => _latest(userId, type);

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
    return Stream<UserConsentDto?>.multi((controller) {
      controller.add(_latest(userId, type));
      final subscription = _changes.stream.listen(
        (_) => controller.add(_latest(userId, type)),
        onDone: controller.close,
      );
      controller.onCancel = subscription.cancel;
    }).distinct();
  }

  @override
  Future<UserConsentDto> insertUserConsent(UserConsentDto dto) async {
    final stored = UserConsentDto.stored(
      id: 'in-memory-${_nextId++}',
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

  UserConsentDto? _latest(String userId, ConsentType type) {
    for (final record in _records.reversed) {
      if (record.userId == userId && record.consentType == type) return record;
    }
    return null;
  }

  @override
  Future<void> dispose() => _changes.close();
}
