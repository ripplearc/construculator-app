import 'package:construculator/features/dashboard/presentation/widgets/project_list_item.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Scrollable list of project search results grouped under a
/// "Most relevant" header.
///
/// Renders one [ProjectListItem] per project in [results]; taps are forwarded
/// to [onProjectTap]. The per-project settings affordance stays
/// non-interactive here — settings navigation remains a projects-sheet
/// concern.
class ProjectSearchResultsList extends StatelessWidget {
  /// The projects returned by the search.
  final List<Project> results;

  /// Called when a project result is tapped.
  final void Function(Project) onProjectTap;

  /// Creates a [ProjectSearchResultsList].
  const ProjectSearchResultsList({
    super.key,
    required this.results,
    required this.onProjectTap,
  });

  @override
  Widget build(BuildContext context) {
    final typography = context.textTheme;
    final appColors = context.colorTheme;

    return CustomScrollView(
      key: const Key('projectSearchResultsListView'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: CoreSpacing.space4),
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                top: CoreSpacing.space4,
                bottom: CoreSpacing.space2,
              ),
              child: Text(
                context.l10n.searchResultsMostRelevant,
                key: const Key('projectSearchMostRelevantHeader'),
                style: typography.bodyLargeSemiBold.copyWith(
                  color: appColors.textDark,
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: CoreSpacing.space4),
          sliver: SliverList.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final project = results[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: CoreSpacing.space3),
                child: ProjectListItem(
                  key: ValueKey('projectSearchResult_${project.id}'),
                  project: project,
                  onTap: () => onProjectTap(project),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
