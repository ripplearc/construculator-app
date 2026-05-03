import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';

/// Placeholder page for the Members tab.
class MembersPage extends StatelessWidget {
  const MembersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(context.l10n.members, style: context.textTheme.headlineMediumSemiBold),
    );
  }
}
