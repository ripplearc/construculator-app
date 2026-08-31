import 'package:construculator/libraries/consent/data/models/consent_wire_values.dart';
import 'package:construculator/libraries/consent/domain/entities/consent_version_entity.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:equatable/equatable.dart';

/// Data Transfer Object for the [ConsentVersion] entity.
///
/// Represents a row of the consent versions table as it arrives from the
/// server or from local storage. Unlike most DTOs here, the four fields the
/// gate decides on — type, version, document URL and id — get no fallback:
/// [fromJson] throws instead. [publishedAt] is audit metadata and does fall
/// back, since it feeds no decision.
///
/// That split is deliberate. The version number is compared against the user's
/// acceptance, and the document URL is what the consent page asks the user to
/// read. A row defaulted to version `0` would compare as satisfied against
/// every acceptance on file and silently mark every user current; one
/// defaulted to an unusable URL would present a consent page with nothing to
/// review. Throwing lets the repository resolve the failure to a status that
/// blocks, which is the honest outcome when the requirement cannot be read.
class ConsentVersionDto extends Equatable {
  /// Unique identifier for this published version.
  final String id;

  /// Which document this version belongs to.
  final ConsentType consentType;

  /// The published version number.
  final int version;

  /// Where the user can read the document.
  final String documentUrl;

  /// When this version became the published one.
  final DateTime publishedAt;

  const ConsentVersionDto({
    required this.id,
    required this.consentType,
    required this.version,
    required this.documentUrl,
    required this.publishedAt,
  });

  /// Builds a DTO from a raw consent versions row.
  ///
  /// Throws [FormatException] naming the field that could not be read — see
  /// the class doc for why the gate-deciding fields do not fall back.
  factory ConsentVersionDto.fromJson(Map<String, dynamic> json) {
    final consentType = ConsentTypeWireValue.fromJson(
      json[DatabaseConstants.consentTypeColumn],
    );
    final version = _parseVersionAcceptingNumericString(
      json[DatabaseConstants.versionColumn],
    );
    final documentUrl = json[DatabaseConstants.documentUrlColumn];
    final id = json[DatabaseConstants.idColumn];

    final unreadable = switch (null) {
      _ when consentType == null => DatabaseConstants.consentTypeColumn,
      // Zero mirrors the backend's check (version > 0); see the class doc.
      _ when version == null || version <= 0 => DatabaseConstants.versionColumn,
      _ when !_isPresentableUrl(documentUrl) =>
        DatabaseConstants.documentUrlColumn,
      _ when id is! String => DatabaseConstants.idColumn,
      _ => null,
    };
    if (unreadable != null) {
      throw FormatException('Unreadable consent version row: $unreadable');
    }

    return ConsentVersionDto(
      id: id as String,
      consentType: consentType!,
      version: version!,
      documentUrl: documentUrl as String,
      publishedAt: parseTimestampOrEpoch(
        json[DatabaseConstants.publishedAtColumn],
      ),
    );
  }

  /// Builds a DTO from a row, or returns null when the row cannot be read.
  ///
  /// For callers reading a batch, where one bad row must not discard the good
  /// ones beside it — a consent type this build does not recognise means a
  /// newer server, not a reason to block the user.
  static ConsentVersionDto? tryFromJson(Map<String, dynamic> json) {
    try {
      return ConsentVersionDto.fromJson(json);
    } on FormatException {
      return null;
    }
  }

  /// Converts to the domain [ConsentVersion] entity.
  ConsentVersion toDomain() => ConsentVersion(
    id: id,
    consentType: consentType,
    version: version,
    documentUrl: documentUrl,
    publishedAt: publishedAt,
  );

  static int? _parseVersionAcceptingNumericString(Object? value) =>
      switch (value) {
        final num n when n == n.truncate() => n.toInt(),
        final String s => int.tryParse(s),
        _ => null,
      };

  static bool _isPresentableUrl(Object? value) {
    if (value is! String || value.isEmpty) return false;
    final uri = Uri.tryParse(value);
    return uri != null && (uri.isScheme('https') || uri.isScheme('http'));
  }

  @override
  List<Object?> get props => [
    id,
    consentType,
    version,
    documentUrl,
    publishedAt,
  ];
}
