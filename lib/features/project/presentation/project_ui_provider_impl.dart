import 'package:construculator/features/project/presentation/bloc/get_project_bloc/get_project_bloc.dart';
import 'package:construculator/features/project/presentation/widgets/project_header_app_bar.dart';
import 'package:construculator/libraries/project/presentation/project_ui_provider.dart';
import 'package:flutter/material.dart';

class ProjectUIProviderImpl extends ProjectUIProvider {
  /// A factory that creates a fresh [GetProjectBloc] for each header app bar instance.
  final GetProjectBloc Function() getProjectBlocBuilder;

  ProjectUIProviderImpl({required this.getProjectBlocBuilder});

  @override
  PreferredSizeWidget buildProjectHeaderAppbar({
    required String projectId,
    VoidCallback? onProjectTap,
    VoidCallback? onSearchTap,
    VoidCallback? onNotificationTap,
  }) {
    return ProjectHeaderAppBar(
      projectId: projectId,
      getProjectBloc: getProjectBlocBuilder(),
      onProjectTap: onProjectTap,
      onSearchTap: onSearchTap,
      onNotificationTap: onNotificationTap,
    );
  }
}
