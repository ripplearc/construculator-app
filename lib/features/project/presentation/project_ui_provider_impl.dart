import 'package:construculator/features/project/presentation/widgets/project_header_app_bar.dart';
import 'package:construculator/libraries/project/presentation/project_ui_provider.dart';
import 'package:flutter/material.dart';

class ProjectUIProviderImpl extends ProjectUIProvider {
  @override
  PreferredSizeWidget buildProjectHeaderAppbar({
    required String projectId,
    VoidCallback? onProjectTap,
    VoidCallback? onSearchTap,
    VoidCallback? onNotificationTap,
    ImageProvider<Object>? avatarImage,
  }) {
    return ProjectHeaderAppBar(
      projectName: projectId,
      onProjectTap: onProjectTap,
      onSearchTap: onSearchTap,
      onNotificationTap: onNotificationTap,
      avatarImage: avatarImage,
    );
  }
}
