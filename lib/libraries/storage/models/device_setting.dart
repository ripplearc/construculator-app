// coverage:ignore-file
/// The settings the phone keeps for itself, with no user's data in them.
///
/// Sign-out and a change of user never delete these. The list is short on
/// purpose: a value that is tied to an account belongs in the user space of
/// `StorageService`, and a reviewer checks every new entry here.
///
/// The name of an entry is the key it is stored under, so renaming an entry
/// loses the value saved on phones under the old name.
enum DeviceSetting {
  /// The user has seen the onboarding screens on this phone.
  onboardingSeen,

  /// How many times a different user signed in on this phone.
  ownerChangeCount,

  /// How many sign-outs happened with no owner record on the phone.
  noOwnerRecordSignOutCount,

  /// How many unsent edits a delete of local-only data removed.
  unsentEditsDeletedCount,

  /// The date of the last app start, used to doubt a wrong phone clock.
  lastOpenedDate,

  /// How many runs of the sign-in check hung, so the erase option survives a
  /// restart.
  hungRunCount,
}
