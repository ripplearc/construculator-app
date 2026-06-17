import 'package:construculator/libraries/members/domain/member_invitation_provider.dart';
import 'package:construculator/libraries/members/presentation/widgets/invited_members_list.dart';
import 'package:construculator/libraries/members/presentation/widgets/member_invitation_widget.dart';
import 'package:flutter/widgets.dart';

/// A test double for [MemberInvitationProvider] that renders the real widgets,
/// so screenshot and widget tests see the actual UI without importing the
/// concrete [MemberInvitationProviderImpl].
class FakeMemberInvitationProvider implements MemberInvitationProvider {
  /// Creates a [FakeMemberInvitationProvider].
  const FakeMemberInvitationProvider();

  /// Builds and returns a [MemberInvitationWidget] with the given parameters.
  ///
  /// The [onInvite] callback is invoked when the user taps the Invite button.
  @override
  Widget buildMemberInvitationWidget({
    required String title,
    required String subtitle,
    void Function(List<String> emails)? onInvite,
  }) {
    return MemberInvitationWidget(
      title: title,
      subtitle: subtitle,
      onInvite: onInvite,
    );
  }

  /// Builds and returns an [InvitedMembersList] with the given [emails].
  ///
  /// The optional [onRemove] callback is invoked when the user taps the
  /// remove icon on a tile.
  @override
  Widget buildInvitedMembersList({
    required List<String> emails,
    void Function(String email)? onRemove,
  }) {
    return InvitedMembersList(
      emails: emails,
      onRemove: onRemove,
    );
  }
}
