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
  /// Unique identifier for this record.
  final String id;

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

  /// Builds a DTO from a raw user consents row.
  ///
  /// Throws [FormatException] when the row cannot be read as a usable consent
  /// record.
  factory UserConsentDto.fromJson(Map<String, dynamic> json) {
    final consentType = ConsentTypeWireValue.fromJson(
      json[DatabaseConstants.consentTypeColumn],
    );
    final action = ConsentActionWireValue.fromJson(
      json[DatabaseConstants.actionColumn],
    );
    final version = json[DatabaseConstants.versionColumn];
    final id = json[DatabaseConstants.idColumn];
    final userId = json[DatabaseConstants.userIdColumn];

    if (consentType == null ||
        action == null ||
        version is! int ||
        id is! String ||
        userId is! String) {
      throw const FormatException('Unreadable user consent row');
    }

    return UserConsentDto(
      id: id,
      userId: userId,
      consentType: consentType,
      version: version,
      action: action,
      recordedAt: parseTimestampOrEpoch(
        json[DatabaseConstants.recordedAtColumn],
      ),
      appVersion: json[DatabaseConstants.appVersionColumn] as String?,
      platform: json[DatabaseConstants.platformColumn] as String?,
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
    DatabaseConstants.recordedAtColumn: recordedAt.toIso8601String(),
    if (appVersion != null) DatabaseConstants.appVersionColumn: appVersion,
    if (platform != null) DatabaseConstants.platformColumn: platform,
  };

  /// Converts to the domain [UserConsent] entity.
  UserConsent toDomain() => UserConsent(
    id: id,
    userId: userId,
    consentType: consentType,
    version: version,
    action: action,
    recordedAt: recordedAt,
    appVersion: appVersion,
    platform: platform,
  );

  @override
  List<Object?> get props => [
    id,
    userId,
    consentType,
    version,
    action,
    recordedAt,
  ];
}
