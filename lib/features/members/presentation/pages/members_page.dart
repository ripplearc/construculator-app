import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';

class MembersPage extends StatelessWidget {
  const MembersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      //TODO:change the hardcoded members to use through localization
      child: Text('Members', style: context.textTheme.headlineMediumSemiBold),
    );
  }
}
