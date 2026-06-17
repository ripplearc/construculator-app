import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/members/domain/invited_member.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Displays a list of invited member tiles.
///
/// Each tile shows an avatar (first letter of the member's name or email),
/// the member's name (or email when no name is available), a Contributor role
/// badge with a dropdown indicator, and an optional remove button.
class InvitedMembersList extends StatelessWidget {
  final List<InvitedMember> members;
  final void Function(String email)? onRemove;

  const InvitedMembersList({
    super.key,
    required this.members,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final remove = onRemove;
    return ListView.builder(
      key: const Key('invited_members_list'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return _MemberTile(
          key: Key('invited_member_${member.email}'),
          member: member,
          onRemove: remove != null ? () => remove(member.email) : null,
        );
      },
    );
  }
}

class _MemberTile extends StatelessWidget {
  final InvitedMember member;
  final VoidCallback? onRemove;

  const _MemberTile({
    super.key,
    required this.member,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;
    final display = member.name ?? member.email;
    final initial = display.isNotEmpty ? display[0].toUpperCase() : '?';

    return Container(
      height: CoreSpacing.space16,
      padding: const EdgeInsets.all(CoreSpacing.space4),
      decoration: BoxDecoration(
        color: colors.textInverse,
        borderRadius: BorderRadius.circular(CoreSpacing.space1),
        boxShadow: CoreShadows.small,
      ),
      child: Row(
        children: [
          Container(
            width: CoreSpacing.space8,
            height: CoreSpacing.space8,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.backgroundGrayMid,
              shape: BoxShape.circle,
            ),
            child: Text(
              initial,
              style: typography.bodyLargeMedium.copyWith(color: colors.textDark),
            ),
          ),
          const SizedBox(width: CoreSpacing.space2),
          Expanded(
            child: Text(
              display,
              style: typography.bodyLargeMedium.copyWith(color: colors.textDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const _ContributorBadge(),
          if (onRemove != null)
            IconButton(
              key: Key('remove_member_${member.email}'),
              tooltip: context.l10n.removeAction,
              icon: CoreIconWidget(
                icon: CoreIcons.close,
                color: colors.iconGrayMid,
                size: CoreIconSize.size20,
              ),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}

class _ContributorBadge extends StatelessWidget {
  const _ContributorBadge();

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;

    return Container(
      padding: const EdgeInsets.only(
        top: CoreSpacing.space1,
        bottom: CoreSpacing.space1,
        left: CoreSpacing.space2,
        right: CoreSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: colors.backgroundGrayLight,
        borderRadius: BorderRadius.circular(CoreSpacing.space1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.contributorRole,
            style: typography.bodyMediumRegular.copyWith(color: colors.textDark),
          ),
          const SizedBox(width: CoreSpacing.space1),
          CoreIconWidget(
            icon: CoreIcons.arrowDown,
            color: colors.textDark,
            size: CoreIconSize.size16,
          ),
        ],
      ),
    );
  }
}
