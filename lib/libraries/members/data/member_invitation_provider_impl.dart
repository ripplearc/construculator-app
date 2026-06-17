import 'package:construculator/libraries/members/domain/invited_member.dart';
import 'package:construculator/libraries/members/domain/member_invitation_provider.dart';
import 'package:construculator/libraries/members/presentation/widgets/invited_members_list.dart';
import 'package:construculator/libraries/members/presentation/widgets/member_invitation_widget.dart';
import 'package:flutter/widgets.dart';

/// Concrete [MemberInvitationProvider] that renders [MemberInvitationWidget]
/// and [InvitedMembersList].
///
/// Lives in the members library so any consumer module can bind it through DI
/// without depending on widget implementations directly.
class MemberInvitationProviderImpl implements MemberInvitationProvider {
  /// Creates a [MemberInvitationProviderImpl].
  const MemberInvitationProviderImpl();

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
    void Function(String email)? onRemove,
  }) {
    return InvitedMembersList(
      members: members,
      onRemove: onRemove,
    );
  }
}
