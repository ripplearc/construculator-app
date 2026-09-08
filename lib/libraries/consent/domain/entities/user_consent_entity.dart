import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:equatable/equatable.dart';

/// One record in a user's consent history.
///
/// Records are append-only — see [ConsentAction] for why withdrawing appends
/// rather than deletes. Only the newest record for a given [consentType]
/// decides the user's current position; `ConsentStatus.resolve` defines how a
/// newest withdrawal is read as "no acceptance on file".
class UserConsent extends Equatable {
  /// Unique identifier for this record.
  final String id;

  /// The user this record belongs to.
  final String userId;

  /// Which document this record refers to.
  final ConsentType consentType;

  /// The document version this record refers to.
  ///
  /// For a withdrawal this is the version being revoked, which is what makes
  /// the audit trail readable after the fact.
  final int version;

  /// Whether this record grants or revokes consent.
  final ConsentAction action;

  /// When the user took the action.
  final DateTime recordedAt;

  /// The app version in use when the action was taken, when known.
  ///
  /// Audit metadata: it never informs the gate decision, but it is part of the
  /// record's identity so that a mapper dropping it is something equality can
  /// notice.
  final String? appVersion;

  /// The platform the action was taken on, when known.
  ///
  /// Audit metadata, on the same terms as [appVersion].
  final String? platform;

  const UserConsent({
    required this.id,
    required this.userId,
    required this.consentType,
    required this.version,
    required this.action,
    required this.recordedAt,
    this.appVersion,
    this.platform,
  });

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
