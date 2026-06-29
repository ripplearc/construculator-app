import 'package:construculator/features/members/presentation/widgets/invited_members_list.dart';
import 'package:construculator/features/members/presentation/widgets/member_invitation_widget.dart';
import 'package:construculator/libraries/members/domain/invited_member.dart';
import 'package:construculator/libraries/members/domain/member_invitation_provider.dart';
import 'package:flutter/widgets.dart';

/// A test double for [MemberInvitationProvider] that renders the real widgets,
/// so screenshot and widget tests see the actual UI without importing the
/// concrete [MemberInvitationProviderImpl].
class FakeMemberInvitationProvider implements MemberInvitationProvider {
  /// Creates a [FakeMemberInvitationProvider].
  const FakeMemberInvitationProvider();

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

  @override
  Widget buildInvitedMembersList({
    required List<InvitedMember> members,
  }) {
    return InvitedMembersList(members: members);
  }
}
