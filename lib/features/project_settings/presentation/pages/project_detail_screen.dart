import 'package:flutter/material.dart';

// TODO: [DASH-029] Implement project details content.
class ProjectDetailScreen extends StatelessWidget {
  const ProjectDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Project Details')),
      body: const SizedBox.shrink(),
    );
  }
}
