import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';

// TODO: [CA-184] Implement edit project form.
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
