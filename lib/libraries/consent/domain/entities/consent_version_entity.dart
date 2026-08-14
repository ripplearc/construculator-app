import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:equatable/equatable.dart';

/// A published version of a consent document.
///
/// This is the server's side of the comparison the gate performs: the version
/// the product currently requires, against the version the user last accepted.
/// Exactly one version per [ConsentType] is published at a time.
///
/// [version] is a monotonically increasing integer rather than a timestamp or
/// a semantic version string, because the only question ever asked of it is
/// whether the accepted number is at least the published one. Comparing
/// integers keeps that decision unambiguous and keeps it off the network.
///
/// The fields mirror a published row faithfully, including the two the gate
/// never branches on, because `ConsentVersionDto` round-trips the entity back
/// to that row. There is deliberately no `effectiveFrom`: which version is
/// currently in force is decided by the database's `current_consent_versions`
/// view, so the client never has a date to compare and cannot disagree with
/// the server about what it is being asked to accept.
class ConsentVersion extends Equatable {
  /// Unique identifier for this published version.
  final String id;

  /// Which document this version belongs to.
  final ConsentType consentType;

  /// The published version number.
  ///
  /// A user is current when their accepted version is greater than or equal to
  /// this value, and outdated when it is strictly less.
  final int version;

  /// Where the user can read the document this version refers to.
  ///
  /// Required rather than optional: asking someone to accept a document the
  /// app cannot show them would not be consent, so a version is only publish-
  /// able once there is something to read.
  final String documentUrl;

  /// When this version became the published one.
  final DateTime publishedAt;

  const ConsentVersion({
    required this.id,
    required this.consentType,
    required this.version,
    required this.documentUrl,
    required this.publishedAt,
  });

  @override
  List<Object?> get props => [
    id,
    consentType,
    version,
    documentUrl,
    publishedAt,
  ];
}
