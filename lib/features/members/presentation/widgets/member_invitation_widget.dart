import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/auth/domain/validation/auth_validation.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// A widget that lets users invite collaborators by email address.
///
/// Present via [CoreQuickSheet.show] — do not wrap in ClipRRect.
///
/// Manages its own invitation list. Added emails appear as removable chips
/// inside the input field. Calls [onInvite] with the final list when the
/// user taps the Invite button.
class MemberInvitationWidget extends StatefulWidget {
  final String title;
  final String subtitle;

  /// Callback invoked when the user taps Invite.
  /// May be null in tests; must be non-null in production call sites.
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

    return Container(
      key: const Key('member_invitation_widget'),
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
                    hasError: _errorText != null,
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
        boxShadow: CoreShadows.small,
      ),
      padding: const EdgeInsets.only(
        top: CoreSpacing.space3,
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
    );
  }
}

class _EmailInputRow extends StatelessWidget {
  final TextEditingController controller;
  final List<String> emails;
  final void Function(String email) onRemove;
  final VoidCallback onSubmit;
  final bool hasError;

  const _EmailInputRow({
    required this.controller,
    required this.emails,
    required this.onRemove,
    required this.onSubmit,
    required this.hasError,
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
        color: colors.textInverse,
        border: Border.all(
          color: hasError ? colors.statusError : colors.lineDarkOutline,
        ),
        borderRadius: BorderRadius.circular(CoreSpacing.space2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: CoreSpacing.space20),
              child: SingleChildScrollView(
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
            ),
          ),
          const SizedBox(width: CoreSpacing.space3),
          const _ContributorBadge(),
        ],
      ),
    );
  }
}

// TODO: [CA-XXX] Contribute _EmailChip to CoreUI as CoreInputChip (non-toggleable
//   chip with remove button). https://ripplearc.youtrack.cloud/issue/CA-XXX
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
            style: typography.bodyMediumRegular.copyWith(
              color: colors.textDark,
            ),
          ),
          const SizedBox(width: CoreSpacing.space1),
          CoreIconWidget(
            icon: CoreIcons.arrowDropDown,
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
