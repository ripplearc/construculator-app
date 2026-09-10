import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';

/// Defensive fallback shown when navigation reaches a feature that this build
/// does not include.
///
/// `FeatureUnavailableModule` renders this at an excluded feature's base path.
/// It is not a designed surface: an excluded feature has no tab and no
/// entry-point button, so a user reaches this only through a stale deep link
/// or an external link.
class FeatureUnavailablePage extends StatelessWidget {
  /// Creates a [FeatureUnavailablePage].
  const FeatureUnavailablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorTheme.pageBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.l10n.featureUnavailableMessage,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyLargeRegular,
          ),
        ),
      ),
    );
  }
}
