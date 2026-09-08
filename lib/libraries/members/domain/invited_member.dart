import 'package:flutter/foundation.dart';

/// Represents a member who has been invited to a project.
@immutable
class InvitedMember {
  /// The email address used to send the invitation.
  final String email;

  /// The display name of the invited person, if known.
  ///
  /// When null, callers should fall back to [email] for display purposes.
  final String? name;

  const InvitedMember({required this.email, this.name});

  InvitedMember copyWith({String? email, String? name}) =>
      InvitedMember(email: email ?? this.email, name: name ?? this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvitedMember &&
          runtimeType == other.runtimeType &&
          email == other.email;

  @override
  int get hashCode => email.hashCode;
}
