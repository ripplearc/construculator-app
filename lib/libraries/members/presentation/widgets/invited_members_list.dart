import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Displays a list of invited member tiles.
///
/// Each tile shows an avatar (first letter of the email), the email address,
/// a static "Contributor" role badge, and an optional remove button.
class InvitedMembersList extends StatelessWidget {
  final List<String> emails;
  final void Function(String email)? onRemove;

  const InvitedMembersList({
    super.key,
    required this.emails,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final remove = onRemove;
    return ListView.builder(
      key: const Key('invited_members_list'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: emails.length,
      itemBuilder: (context, index) {
        final email = emails[index];
        return _MemberTile(
          key: Key('invited_member_$email'),
          email: email,
          onRemove: remove != null ? () => remove(email) : null,
        );
      },
    );
  }
}

class _MemberTile extends StatelessWidget {
  final String email;
  final VoidCallback? onRemove;

  const _MemberTile({
    super.key,
    required this.email,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return Container(
      height: 76,
      padding: const EdgeInsets.all(CoreSpacing.space4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CoreSpacing.space1),
      ),
      child: Row(
        children: [
          Container(
            width: CoreSpacing.space10,
            height: CoreSpacing.space10,
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
          const SizedBox(width: CoreSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  email,
                  style: typography.bodyLargeMedium.copyWith(color: colors.textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: CoreSpacing.space1),
                Text(
                  context.l10n.contributorRole,
                  style: typography.bodySmallRegular.copyWith(color: colors.textBody),
                ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              key: Key('remove_member_$email'),
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
