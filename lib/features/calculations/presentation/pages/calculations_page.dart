import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';

class CalculationsPage extends StatelessWidget {
  const CalculationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        context.l10n.navCalculations,
        style: context.textTheme.headlineMediumSemiBold,
      ),
    );
  }
}
