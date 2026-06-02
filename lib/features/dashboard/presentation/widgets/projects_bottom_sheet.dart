import 'package:construculator/features/dashboard/presentation/bloc/project_dropdown_bloc/project_dropdown_bloc.dart';
import 'package:construculator/features/dashboard/presentation/widgets/project_list_item.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

const int _kProjectsSkeletonItemCount = 4;
const double _kProjectsSkeletonItemHeight = CoreSpacing.space20;
const double _kProjectsListMaxHeight = CoreSpacing.space64 * 2;
const double _kProjectsSearchIconSize = CoreSpacing.space5;

/// A bottom sheet that lists the user's accessible projects, allowing them to
/// search, select, and start creating a project.
///
/// The list is driven by [ProjectDropdownBloc]; selecting a project dispatches
/// [ProjectDropdownSelected] and dismisses the sheet. Loading, error (with a
/// cached fallback), and empty states are all rendered inline.
class ProjectsBottomSheet extends StatefulWidget {
  const ProjectsBottomSheet({super.key});

  /// Shows the projects bottom sheet using [CoreQuickSheet].
  static Future<void> show(BuildContext context) {
    return CoreQuickSheet.show<void>(
      context: context,
      useSafeArea: true,
      child: const ProjectsBottomSheet(),
    );
  }

  @override
  State<ProjectsBottomSheet> createState() => _ProjectsBottomSheetState();
}

class _ProjectsBottomSheetState extends State<ProjectsBottomSheet> {
  late final ProjectDropdownBloc _bloc;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bloc = Modular.get<ProjectDropdownBloc>();
    _bloc.add(const ProjectDropdownStarted());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _bloc.add(ProjectDropdownSearchChanged(query.trim()));
  }

  Future<void> _onRefresh() async {
    _bloc.add(const ProjectDropdownStarted());
    await _bloc.stream.firstWhere(
      (state) =>
          state is ProjectDropdownLoadSuccess ||
          state is ProjectDropdownLoadFailure,
    );
  }

  void _onProjectSelected(Project project) {
    _bloc.add(ProjectDropdownSelected(project.id));
    Navigator.of(context).pop();
  }

  void _onCreateProject() {
    // TODO: Wire to the create-project flow once it exists.
    // https://ripplearc.youtrack.cloud/issue/CA-116
  }

  void _onProjectSettings(Project project) {
    // TODO: Navigate to project settings once the route exists.
    // https://ripplearc.youtrack.cloud/issue/CA-116
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(CoreSpacing.space6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.projectsSheetTitle,
            style: typography.titleLargeSemiBold.copyWith(
              color: colors.textHeadline,
            ),
          ),
          const SizedBox(height: CoreSpacing.space4),
          CoreTextField(
            key: const Key('projects_search_field'),
            controller: _searchController,
            hintText: l10n.searchProjectsHint,
            onChanged: _onSearchChanged,
            prefix: CoreIconWidget(
              icon: CoreIcons.search,
              size: _kProjectsSearchIconSize,
              color: colors.iconGrayMid,
            ),
          ),
          const SizedBox(height: CoreSpacing.space4),
          BlocBuilder<ProjectDropdownBloc, ProjectDropdownState>(
            bloc: _bloc,
            builder: (context, state) => _buildBody(context, state),
          ),
          const SizedBox(height: CoreSpacing.space4),
          CoreButton(
            label: l10n.createProjectButton,
            onPressed: _onCreateProject,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProjectDropdownState state) {
    if (state is ProjectDropdownLoadInProgress) {
      return _buildSkeleton(context);
    }

    if (state is ProjectDropdownLoadSuccess) {
      return _buildList(
        context,
        projects: state.visibleProjects,
        selectedProjectId: state.selectedProject?.id,
      );
    }

    if (state is ProjectDropdownLoadFailure) {
      if (state.cachedProjects.isNotEmpty) {
        return _buildList(
          context,
          projects: state.visibleProjects,
          selectedProjectId: null,
          errorBanner: true,
        );
      }
      return _buildError(context);
    }

    return _buildSkeleton(context);
  }

  Widget _buildSkeleton(BuildContext context) {
    final colors = context.colorTheme;
    return Column(
      children: List.generate(
        _kProjectsSkeletonItemCount,
        (_) => Container(
          height: _kProjectsSkeletonItemHeight,
          margin: const EdgeInsets.only(bottom: CoreSpacing.space3),
          decoration: BoxDecoration(
            color: colors.backgroundGrayLight,
            borderRadius: BorderRadius.circular(CoreSpacing.space3),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CoreSpacing.space8),
      child: Center(
        child: Text(
          context.l10n.projectsLoadError,
          textAlign: TextAlign.center,
          style: typography.bodyMediumRegular.copyWith(
            color: colors.statusError,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CoreSpacing.space8),
      child: Center(
        child: Text(
          context.l10n.projectsEmptyState,
          textAlign: TextAlign.center,
          style: typography.bodyMediumRegular.copyWith(color: colors.textBody),
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context, {
    required List<Project> projects,
    required String? selectedProjectId,
    bool errorBanner = false,
  }) {
    final colors = context.colorTheme;
    final typography = context.textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: _kProjectsListMaxHeight),
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (errorBanner)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: CoreSpacing.space3),
                  child: Text(
                    context.l10n.projectsLoadError,
                    style: typography.bodySmallRegular.copyWith(
                      color: colors.statusError,
                    ),
                  ),
                ),
              ),
            if (projects.isEmpty)
              SliverToBoxAdapter(child: _buildEmpty(context))
            else
              SliverList.builder(
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == projects.length - 1
                          ? 0
                          : CoreSpacing.space3,
                    ),
                    child: ProjectListItem(
                      key: ValueKey<String>(project.id),
                      project: project,
                      isSelected: project.id == selectedProjectId,
                      onTap: () => _onProjectSelected(project),
                      onSettingsTap: () => _onProjectSettings(project),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
