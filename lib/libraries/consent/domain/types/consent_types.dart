// coverage:ignore-file

/// The kinds of consent the app tracks, versioned independently of each other.
///
/// The independence is the point: publishing a new privacy policy must be able
/// to re-gate the app without invalidating the user's analytics opt-in, and
/// withdrawing analytics must not sign anyone out.
enum ConsentType {
  /// Terms of service and privacy policy, accepted together as one unit.
  ///
  /// The only type that gates access to the app shell.
  termsAndPrivacy,

  /// Product analytics capture.
  ///
  /// Gates analytics capture only. A stale or withdrawn analytics consent
  /// disables capture and never blocks the app — blocking a calculator over an
  /// analytics opt-in would be disproportionate.
  analytics,
}

/// What a single consent record states.
///
/// Consent is an append-only log rather than a mutable flag: withdrawing
/// appends a [withdrawn] record instead of deleting the [accepted] one, so the
/// trail shows that consent was given and later revoked rather than never
/// given at all. Only the newest record for a type is therefore meaningful.
enum ConsentAction {
  /// The user agreed to the version named on the record.
  accepted,

  /// The user revoked a consent they had previously given.
  ///
  /// A newest record of this action means there is no acceptance on file,
  /// which is the same position as a user who never accepted anything.
  withdrawn,
}
