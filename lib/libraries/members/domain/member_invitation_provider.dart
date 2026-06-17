import 'package:flutter/widgets.dart';

/// Provides member invitation UI components to any consumer.
///
/// Library consumers depend only on this contract; the concrete widgets are
/// owned by the members feature and resolved at runtime through Modular.
abstract class MemberInvitationProvider {
  /// Builds the member invitation widget with email input and invite action.
  ///
  /// Parameters:
  /// - [title]: Heading displayed at the top of the widget.
  /// - [subtitle]: Supporting text shown below the title.
  /// - [onInvite]: Called with the final list of email addresses when the
  ///   user taps the Invite button. Null means no callback is wired.
  Widget buildMemberInvitationWidget({
    required String title,
    required String subtitle,
    void Function(List<String> emails)? onInvite,
  });

  /// Builds the list of already-invited members.
  ///
  /// Parameters:
  /// - [emails]: Emails to display as invited member tiles.
  /// - [onRemove]: Called with the email to remove when the user taps the
  ///   remove icon on a tile. Null makes tiles non-removable.
  Widget buildInvitedMembersList({
    required List<String> emails,
    void Function(String email)? onRemove,
  });
}
