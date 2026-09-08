import 'package:construculator/features/project_settings/presentation/bloc/project_details_bloc/project_details_bloc.dart';
import 'package:construculator/features/project_settings/presentation/widgets/cost_files_section.dart';
import 'package:construculator/features/project_settings/presentation/widgets/export_settings_display.dart';
import 'package:construculator/features/project_settings/presentation/widgets/project_header_card.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Displays the details of a single project: header, export settings, and
/// attached cost files.
///
/// The screen owns its [ProjectDetailsBloc] for the lifetime of the route and
/// loads the project identified by [projectId] on first build.
///
/// Note: `ProjectRepositoryImpl.getProject` is still a stub that returns a
/// sample project for any id, so this screen renders placeholder data until
/// the real fetch lands. https://ripplearc.youtrack.cloud/issue/CA-162
class ProjectDetailScreen extends StatelessWidget {
  /// Key for the loading indicator, used by tests.
  static const Key loadingKey = Key('project_detail_loading');

  /// Key for the error view, used by tests.
  static const Key errorKey = Key('project_detail_error');

  /// Key for the retry button on the error view, used by tests.
  static const Key retryButtonKey = Key('project_detail_retry_button');

  /// Key for the scrollable loaded content, used by tests.
  static const Key contentKey = Key('project_detail_content');

  /// Identifier of the project to display.
  final String projectId;

  /// Factory producing a fresh [ProjectDetailsBloc] for this route.
  final ProjectDetailsBloc Function() blocFactory;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
    required this.blocFactory,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProjectDetailsBloc>(
      create: (_) => blocFactory()..add(ProjectDetailsStarted(projectId)),
      child: Scaffold(
        appBar: AppBar(title: Text(context.l10n.projectDetailScreenTitle)),
        body: SafeArea(
          child: BlocBuilder<ProjectDetailsBloc, ProjectDetailsState>(
            builder: (context, state) {
              return switch (state) {
                ProjectDetailsLoaded(:final project) => _LoadedView(
                  project: project,
                ),
                ProjectDetailsLoadFailure() => _ErrorView(
                  onRetry: () => context.read<ProjectDetailsBloc>().add(
                    ProjectDetailsRefreshed(projectId),
                  ),
                ),
                _ => const Center(
                  key: ProjectDetailScreen.loadingKey,
                  child: CoreLoadingIndicator(),
                ),
              };
            },
          ),
        ),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  final Project project;

  const _LoadedView({required this.project});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: ProjectDetailScreen.contentKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProjectHeaderCard(
            projectName: project.projectName,
            description: project.description,
            lastUpdatedAt: project.updatedAt,
            // TODO: [CA-269] Wire real cost estimation and member counts once
            // their data sources exist; the stat cards show 0 until then.
            estimationCount: 0,
            memberCount: 0,
          ),
          Padding(
            padding: const EdgeInsets.all(CoreSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExportSettingsDisplay(
                  storageProvider: project.exportStorageProvider,
                  folderName: project.exportFolderLink,
                ),
                const SizedBox(height: CoreSpacing.space6),
                // TODO: [CA-269] Supply attached cost files once the cost_files
                // table and its data source exist; the section shows its empty
                // state until then.
                const CostFilesSection(files: []),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;

    return Center(
      key: ProjectDetailScreen.errorKey,
      child: Padding(
        padding: const EdgeInsets.all(CoreSpacing.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.projectDetailsLoadError,
              textAlign: TextAlign.center,
              style: typography.bodyMediumRegular.copyWith(
                color: colors.statusError,
              ),
            ),
            const SizedBox(height: CoreSpacing.space4),
            CoreButton(
              key: ProjectDetailScreen.retryButtonKey,
              label: context.l10n.projectDetailsRetryButton,
              variant: CoreButtonVariant.secondary,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
