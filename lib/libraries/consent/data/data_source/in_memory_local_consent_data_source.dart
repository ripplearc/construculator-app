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
/// Nothing above [LocalConsentDataSource] changes.
///
/// It is production code rather than a test double — the app genuinely runs on
/// it while the gate is disabled — but it does not persist. Acceptances are
/// lost on restart, which is why the gate stays behind `CONSENT_GATE_ENABLED`
/// until the real store exists: with this source live and the gate on, a user
/// would be re-prompted on every cold start.
///
/// The seeded published versions let the whole flow be exercised end to end
/// without a backend, which is what makes the gate demoable before CA-971.
class InMemoryLocalConsentDataSource implements LocalConsentDataSource {
  /// The published version held for each consent type.
  ///
  /// Seeded rather than empty so the gate resolves to a real requirement
  /// instead of [ConsentIndeterminate] for every user.
  final Map<ConsentType, ConsentVersionDto> _publishedVersions;

  /// Consent records in insertion order, newest last.
  final List<UserConsentDto> _records = [];

  /// Broadcast so the repository can watch while the gate page also reads.
  final StreamController<void> _changes = StreamController<void>.broadcast();

  var _nextId = 0;

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
          documentUrl: 'https://ripplearc.com/legal/${type.name}',
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
    _changes.add(null);
    return stored;
  }

  // The newest record for [userId] and [type], or null when there is none.
  //
  // Satisfies LocalConsentDataSource's recordedAt-ordered contract by
  // insertion order rather than by comparing [UserConsentDto.recordedAt]
  // directly: this source is a single process appending through one clock,
  // so insertion order and recordedAt order coincide, and insertion order
  // additionally resolves two records written in the same instant
  // deterministically. CA-971's store gets the same two properties from
  // `order by recorded_at desc` plus a tiebreak, per CA-963 §3.
  UserConsentDto? _latest(String userId, ConsentType type) {
    for (final record in _records.reversed) {
      if (record.userId == userId && record.consentType == type) return record;
    }
    return null;
  }

  @override
  Future<void> dispose() => _changes.close();
}
