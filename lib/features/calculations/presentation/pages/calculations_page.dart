import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';

/// Placeholder page for the Calculations tab.
///
/// Displays a centered label until the full Calculations feature is implemented.
class CalculationsPage extends StatelessWidget {
  const CalculationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        context.l10n.calculations,
        style: context.textTheme.headlineMediumSemiBold,
      ),
    );
  }
}
