import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';

class MembersPage extends StatelessWidget {
  const MembersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        context.l10n.navMembers,
        style: context.textTheme.headlineMediumSemiBold,
      ),
    );
  }
}
