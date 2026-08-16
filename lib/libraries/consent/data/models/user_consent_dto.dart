import 'package:construculator/libraries/consent/data/models/consent_wire_values.dart';
import 'package:construculator/libraries/consent/domain/entities/user_consent_entity.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:equatable/equatable.dart';

/// Data Transfer Object for the [UserConsent] entity.
///
/// Represents one row of the append-only user consents table. Like
/// [ConsentVersionDto] this throws rather than falling back on the fields that
/// decide the gate: a record whose action or version cannot be read must not
/// be treated as an acceptance the user never gave.
class UserConsentDto extends Equatable {
  /// Unique identifier for this record, or null on a record the store has
  /// not yet assigned one — see [UserConsentDto.draft].
  final String? id;

  /// The user this record belongs to.
  final String userId;

  /// Which document this record refers to.
  final ConsentType consentType;

  /// The document version this record refers to.
  final int version;

  /// Whether this record grants or revokes consent.
  ///
  /// Held as the domain enum rather than a raw string so callers cannot
  /// compare against a misspelled literal.
  final ConsentAction action;

  /// When the user took the action.
  final DateTime recordedAt;

  /// The app version in use at the time, when known. Audit metadata only.
  final String? appVersion;

  /// The platform the action was taken on, when known. Audit metadata only.
  final String? platform;

  const UserConsentDto({
    required this.id,
    required this.userId,
    required this.consentType,
    required this.version,
    required this.action,
    required this.recordedAt,
    this.appVersion,
    this.platform,
  });

  /// A record not yet written to the store, which assigns [id] on insert.
  ///
  /// Exists so the write path does not have to fabricate a sentinel id that
  /// [fromJson]'s own guard would reject.
  const UserConsentDto.draft({
    required this.userId,
    required this.consentType,
    required this.version,
    required this.action,
    required this.recordedAt,
    this.appVersion,
    this.platform,
  }) : id = null;

  /// Builds a DTO from a raw user consents row.
  ///
  /// Throws [FormatException] naming the field that could not be read when
  /// the row cannot be read as a usable consent record.
  factory UserConsentDto.fromJson(Map<String, dynamic> json) {
    final consentType = ConsentTypeWireValue.fromJson(
      json[DatabaseConstants.consentTypeColumn],
    );
    final action = ConsentActionWireValue.fromJson(
      json[DatabaseConstants.actionColumn],
    );
    final version = parseVersion(json[DatabaseConstants.versionColumn]);
    final id = json[DatabaseConstants.idColumn];
    final userId = json[DatabaseConstants.userIdColumn];
    final recordedAt = parseTimestamp(
      json[DatabaseConstants.recordedAtColumn],
    );
    final rawAppVersion = json[DatabaseConstants.appVersionColumn];
    final rawPlatform = json[DatabaseConstants.platformColumn];

    final unreadable = switch (null) {
      _ when consentType == null => DatabaseConstants.consentTypeColumn,
      _ when action == null => DatabaseConstants.actionColumn,
      // Zero mirrors the backend's check (version > 0); CA-963 §2.
      _ when version == null || version <= 0 => DatabaseConstants.versionColumn,
      _ when id is! String => DatabaseConstants.idColumn,
      _ when userId is! String => DatabaseConstants.userIdColumn,
      // Not audit metadata, unlike the sibling DTO's publishedAt: this orders
      // the history, and the newest record decides the gate. An epoch
      // fallback would sort a withdrawal below the acceptance it supersedes,
      // reading as consent the user revoked.
      _ when recordedAt == null => DatabaseConstants.recordedAtColumn,
      _ => null,
    };
    if (unreadable != null) {
      throw FormatException('Unreadable user consent row: $unreadable');
    }

    return UserConsentDto(
      id: id as String,
      userId: userId as String,
      consentType: consentType!,
      version: version!,
      action: action!,
      recordedAt: recordedAt!,
      // Audit metadata: an unreadable value is dropped rather than failing a
      // row the gate can otherwise decide on.
      appVersion: rawAppVersion is String ? rawAppVersion : null,
      platform: rawPlatform is String ? rawPlatform : null,
    );
  }

  /// Serializes for insertion into the user consents table.
  ///
  /// Omits [id] — the store assigns it — so the returned map is safe to pass
  /// straight to an insert.
  Map<String, dynamic> toInsertJson() => {
    DatabaseConstants.userIdColumn: userId,
    DatabaseConstants.consentTypeColumn: consentType.toJson(),
    DatabaseConstants.versionColumn: version,
    DatabaseConstants.actionColumn: action.toJson(),
    // UTC rather than a naive local timestamp: this column orders a history
    // across devices, so a local `DateTime` serialized without a `.toUtc()`
    // would read back skewed by the writer's timezone.
    DatabaseConstants.recordedAtColumn: recordedAt.toUtc().toIso8601String(),
    if (appVersion != null) DatabaseConstants.appVersionColumn: appVersion,
    if (platform != null) DatabaseConstants.platformColumn: platform,
  };

  /// Converts to the domain [UserConsent] entity.
  ///
  /// Throws [StateError] on a [draft] record — one that has not yet been
  /// written to the store and so has no [id] to give the entity.
  UserConsent toDomain() {
    final assignedId = id;
    if (assignedId == null) {
      throw StateError(
        'A draft consent record has no id until the store assigns one',
      );
    }
    return UserConsent(
      id: assignedId,
      userId: userId,
      consentType: consentType,
      version: version,
      action: action,
      recordedAt: recordedAt,
      appVersion: appVersion,
      platform: platform,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    consentType,
    version,
    action,
    recordedAt,
    appVersion,
    platform,
  ];
}
