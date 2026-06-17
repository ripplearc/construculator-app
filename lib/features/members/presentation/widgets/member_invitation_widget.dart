import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/auth/domain/validation/auth_validation.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// A widget that lets users invite collaborators by email address.
///
/// Manages its own invitation list. Added emails appear as removable chips
/// inside the input field. Calls [onInvite] with the final list when the
/// user taps the Invite button.
class MemberInvitationWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final void Function(List<String> emails)? onInvite;

  const MemberInvitationWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.onInvite,
  });

  @override
  State<MemberInvitationWidget> createState() => _MemberInvitationWidgetState();
}

class _MemberInvitationWidgetState extends State<MemberInvitationWidget> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _emails = [];
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onAdd() {
    final email = _controller.text.trim();
    final validationError = AuthValidation.validateEmail(email);

    if (validationError != null) {
      setState(() {
        _errorText = validationError == AuthErrorType.emailRequired
            ? context.l10n.emailRequiredError
            : context.l10n.invalidEmailError;
      });
      return;
    }

    if (_emails.contains(email)) {
      setState(() => _errorText = context.l10n.emailDuplicateErrorMessage);
      return;
    }

    setState(() {
      _emails.add(email);
      _controller.clear();
      _errorText = null;
    });
  }

  void _onRemove(String email) {
    setState(() => _emails.remove(email));
  }

  void _onInvite() {
    widget.onInvite?.call(List.unmodifiable(_emails));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;

    return ClipRRect(
      key: const Key('member_invitation_widget'),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(CoreSpacing.space7),
        topRight: Radius.circular(CoreSpacing.space7),
      ),
      child: Container(
        color: colors.pageBackground,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              title: widget.title,
              subtitle: widget.subtitle,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CoreSpacing.space4,
                vertical: CoreSpacing.space3,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EmailInputRow(
                    controller: _controller,
                    emails: _emails,
                    onRemove: _onRemove,
                    onSubmit: _onAdd,
                  ),
                  if (_errorText case final error?) ...[
                    const SizedBox(height: CoreSpacing.space1),
                    Text(
                      error,
                      style: typography.bodySmallRegular.copyWith(
                        color: colors.textError,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _InviteButtonRow(
              isDisabled: _emails.isEmpty,
              onPressed: _onInvite,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;

  const _Header({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.textInverse,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(CoreSpacing.space7),
          topRight: Radius.circular(CoreSpacing.space7),
        ),
        boxShadow: CoreShadows.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: CoreSpacing.space3),
              child: Container(
                width: CoreSpacing.space8,
                height: CoreSpacing.space1,
                decoration: BoxDecoration(
                  color: colors.lineDarkOutline,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: CoreSpacing.space4,
              right: CoreSpacing.space4,
              bottom: CoreSpacing.space3,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: typography.titleMediumSemiBold.copyWith(
                    color: colors.textHeadline,
                  ),
                ),
                const SizedBox(height: CoreSpacing.space1),
                Text(
                  subtitle,
                  style: typography.bodyMediumRegular.copyWith(
                    color: colors.textBody,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailInputRow extends StatelessWidget {
  final TextEditingController controller;
  final List<String> emails;
  final void Function(String email) onRemove;
  final VoidCallback onSubmit;

  const _EmailInputRow({
    required this.controller,
    required this.emails,
    required this.onRemove,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CoreSpacing.space3,
        vertical: CoreSpacing.space2,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: colors.lineLight),
        borderRadius: BorderRadius.circular(CoreSpacing.space2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Wrap(
              spacing: CoreSpacing.space2,
              runSpacing: CoreSpacing.space1,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final email in emails)
                  _EmailChip(
                    email: email,
                    onRemove: () => onRemove(email),
                  ),
                IntrinsicWidth(
                  child: TextField(
                    key: const Key('member_invitation_email_input'),
                    controller: controller,
                    style: typography.bodyLargeRegular.copyWith(
                      color: colors.textDark,
                    ),
                    decoration: InputDecoration.collapsed(
                      hintText: emails.isEmpty
                          ? context.l10n.assignByEmailHint
                          : null,
                      hintStyle: typography.bodyLargeRegular.copyWith(
                        color: colors.textBody,
                      ),
                    ),
                    onSubmitted: (_) => onSubmit(),
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: CoreSpacing.space3),
          const _ContributorBadge(),
        ],
      ),
    );
  }
}

class _EmailChip extends StatelessWidget {
  final String email;
  final VoidCallback onRemove;

  const _EmailChip({required this.email, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;

    return Container(
      key: Key('email_chip_$email'),
      padding: const EdgeInsets.symmetric(
        horizontal: CoreSpacing.space3,
        vertical: CoreSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: colors.chipGrey,
        borderRadius: BorderRadius.circular(CoreSpacing.space5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            email,
            style: typography.bodyMediumSemiBold.copyWith(
              color: colors.textDark,
            ),
          ),
          const SizedBox(width: CoreSpacing.space2),
          Semantics(
            label: context.l10n.removeAction,
            button: true,
            child: GestureDetector(
              key: Key('remove_chip_$email'),
              onTap: onRemove,
              child: CoreIconWidget(
                icon: CoreIcons.close,
                color: colors.iconGrayMid,
                size: CoreIconSize.size20,
              ),
            ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: CoreSpacing.space2,
        vertical: CoreSpacing.space2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CoreSpacing.space1),
        boxShadow: CoreShadows.extraSmall,
        color: colors.textInverse,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.contributorRole,
            style: typography.bodyMediumRegular.copyWith(
              color: colors.textDark,
            ),
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

class _InviteButtonRow extends StatelessWidget {
  final bool isDisabled;
  final VoidCallback onPressed;

  const _InviteButtonRow({
    required this.isDisabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CoreSpacing.space4,
        vertical: CoreSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: colors.textInverse,
        boxShadow: CoreShadows.sticky,
      ),
      child: CoreButton(
        key: const Key('member_invitation_invite_button'),
        label: context.l10n.inviteButton,
        isDisabled: isDisabled,
        onPressed: onPressed,
      ),
    );
  }
}
