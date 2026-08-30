import 'package:construculator/libraries/consent/domain/types/consent_types.dart';

/// Wire representation of [ConsentType].
///
/// Lives in the data layer rather than beside the enum so the domain stays
/// unaware of how consent is persisted. Both DTOs and the repository's log
/// messages share this one mapping instead of restating it.
extension ConsentTypeWireValue on ConsentType {
  /// The value stored in the consent type column.
  String toJson() => switch (this) {
    ConsentType.termsAndPrivacy => 'terms_and_privacy',
    ConsentType.analytics => 'analytics',
  };

  /// Resolves a consent type wire value, or null when unrecognised.
  ///
  /// Returns null rather than defaulting to a type: guessing here would
  /// attach a consent record to the wrong document. Null does not by itself
  /// license dropping the row — it covers a corrupt column as well as a newer
  /// server's document. Use [isUnrecognisedWireValue] to tell those apart.
  static ConsentType? fromJson(Object? value) => switch (value) {
    'terms_and_privacy' => ConsentType.termsAndPrivacy,
    'analytics' => ConsentType.analytics,
    _ => null,
  };

  /// Whether [value] names a document this build has no gate for.
  ///
  /// True only for a non-empty string matching no known type — what a newer
  /// server publishing a third document looks like from here, and the one
  /// case a reader may skip. A missing, null, empty or non-string column is a
  /// corrupt row instead: skipping it would hand the gate a list that reads
  /// as "nothing required" for a requirement the user never satisfied, so it
  /// must be allowed to fail the read.
  static bool isUnrecognisedWireValue(Object? value) =>
      value is String && value.isNotEmpty && fromJson(value) == null;
}

/// Wire representation of [ConsentAction].
extension ConsentActionWireValue on ConsentAction {
  /// The value stored in the action column.
  String toJson() => switch (this) {
    ConsentAction.accepted => 'accepted',
    ConsentAction.withdrawn => 'withdrawn',
  };

  /// Resolves a consent action wire value, or null when unrecognised.
  ///
  /// Null is deliberately not treated as [ConsentAction.accepted]. An
  /// unreadable action must never be read as consent the user did not give.
  static ConsentAction? fromJson(Object? value) => switch (value) {
    'accepted' => ConsentAction.accepted,
    'withdrawn' => ConsentAction.withdrawn,
    _ => null,
  };
}

/// Reads a `timestamptz` column, or null when it cannot be read.
DateTime? parseTimestamp(Object? value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Reads a `timestamptz` column, falling back to the UTC epoch.
///
/// For timestamps that are audit metadata rather than gate input — currently
/// only `ConsentVersionDto.publishedAt`. `UserConsentDto.recordedAt` orders
/// the consent history and deliberately does not use this: see its own guard.
///
/// Deliberately quieter than `ProjectDto._parseDateTime`, which logs a warning
/// first: the consent data sources rethrow silently and the repository is the
/// module's single logging boundary.
DateTime parseTimestampOrEpoch(Object? value) =>
    parseTimestamp(value) ??
    // UTC rather than local: this value sits in props, so the flag
    // participates in equality and a local epoch would compare differently by
    // machine.
    DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

/// Reads a version column delivered as a number or a numeric string.
///
/// Accepts either shape: the repo's convention for numeric columns is `as
/// num` rather than an int type test, and whether a local store hands this
/// back as text is each store's choice to make, not something a DTO should
/// silently depend on. A whole-number double is accepted; a fractional one
/// is rejected rather than silently truncated.
int? parseVersion(Object? value) => switch (value) {
  final int n => n,
  final double n when n.truncateToDouble() == n => n.toInt(),
  final String s => int.tryParse(s),
  _ => null,
};
