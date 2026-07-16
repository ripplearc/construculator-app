import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';

// TODO: [CA-184] Implement edit project form. https://ripplearc.youtrack.cloud/issue/CA-184
/// Standalone stub screen for editing an existing project (DASH-032).
///
/// Uses [Scaffold] directly — this is a Tier-1 full-screen page navigated to
/// outside the shell chrome, not a shell-embedded tab.
class EditProjectScreen extends StatelessWidget {
  const EditProjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.editProjectScreenTitle)),
      body: const SizedBox.shrink(),
    );
  }
}
