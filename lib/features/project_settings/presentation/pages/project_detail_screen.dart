import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';

// TODO: [CA-180] Implement project details content. https://ripplearc.youtrack.cloud/issue/CA-180
class ProjectDetailScreen extends StatelessWidget {
  const ProjectDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.projectDetailScreenTitle)),
      body: const SizedBox.shrink(),
    );
  }
}
