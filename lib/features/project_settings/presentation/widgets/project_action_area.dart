import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Two-button row shown below the project name field on the creation screen.
///
/// Both actions are pending implementation in their own tickets.
class ProjectActionArea extends StatelessWidget {
  const ProjectActionArea({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final l10n = context.l10n;

    return Row(
      children: [
        Flexible(
          child: CoreButton(
            key: const Key('add_description_button'),
            variant: CoreButtonVariant.secondary,
            size: CoreButtonSize.medium,
            fullWidth: false,
            icon: CoreIconWidget(
              icon: CoreIcons.add,
              size: CoreIconSize.size20,
              color: colors.buttonSurface,
            ),
            label: l10n.addDescriptionButton,
            onPressed: () {
              // TODO: [CA-175] Wire AddDescriptionSheet
            },
          ),
        ),
        const SizedBox(width: CoreSpacing.space2),
        Flexible(
          child: CoreButton(
            key: const Key('invite_member_button'),
            variant: CoreButtonVariant.secondary,
            size: CoreButtonSize.medium,
            fullWidth: false,
            icon: CoreIconWidget(
              icon: CoreIcons.personAdd,
              size: CoreIconSize.size20,
              color: colors.buttonSurface,
            ),
            label: l10n.inviteMemberButton,
            onPressed: () {
              // TODO: [CA-176] Wire MemberInvitationProvider.buildMemberInvitationWidget()
            },
          ),
        ),
      ],
    );
  }
}
