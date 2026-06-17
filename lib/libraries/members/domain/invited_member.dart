/// Represents a member who has been invited to a project.
class InvitedMember {
  /// The email address used to send the invitation.
  final String email;

  /// The display name of the invited person, if known.
  ///
  /// When null, callers should fall back to [email] for display purposes.
  final String? name;

  const InvitedMember({required this.email, this.name});
}
