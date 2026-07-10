import 'package:construculator/features/dashboard/presentation/bloc/project_search_bloc/project_search_bloc.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/search_filters/presentation/widgets/multi_select_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A modal bottom sheet for selecting tag filters on the project search screen.
///
/// A thin wrapper around the shared [MultiSelectFilterSheet]: the available
/// tags and search filtering are owned by [ProjectSearchBloc]. The sheet
/// dispatches [ProjectSearchTagSearchQueryUpdatedEvent] as the user types and
/// renders [ProjectSearchInitial.availableTags]. Tag selection is kept local
/// until the user taps Apply, at which point the sheet dispatches
/// [ProjectSearchTagFiltersAppliedEvent] and pops itself. Tapping Clear all
/// deselects all tags without dismissing the sheet.
class ProjectSearchTagsFilterSheet extends StatelessWidget {
  /// The tags already selected when the sheet opens.
  final Set<String> initialSelectedTags;

  /// Creates a [ProjectSearchTagsFilterSheet].
  const ProjectSearchTagsFilterSheet({
    super.key,
    required this.initialSelectedTags,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<ProjectSearchBloc, ProjectSearchState>(
      buildWhen: (prev, curr) => curr is ProjectSearchInitial,
      builder: (context, state) {
        return MultiSelectFilterSheet(
          title: l10n.projectSearchTagsSheetTitle,
          searchHint: l10n.projectSearchTagsSheetSearchHint,
          emptyLabel: l10n.projectSearchTagsSheetEmpty,
          clearAllLabel: l10n.projectSearchTagsSheetClearAll,
          applyLabel: l10n.projectSearchTagsSheetApply,
          initialSelectedIds: initialSelectedTags,
          listData: state is ProjectSearchInitial
              ? MultiSelectFilterListData(
                  isLoading: state.availableTagsLoading,
                  items: [
                    for (final tag in state.availableTags)
                      MultiSelectFilterItem(id: tag, label: tag),
                  ],
                )
              : null,
          onSearchQueryChanged: (query) => BlocProvider.of<ProjectSearchBloc>(
            context,
          ).add(ProjectSearchTagSearchQueryUpdatedEvent(query: query)),
          onApply: (tags) => BlocProvider.of<ProjectSearchBloc>(
            context,
          ).add(ProjectSearchTagFiltersAppliedEvent(tags: tags)),
          loadingIndicatorKey: const Key(
            'project_search_tags_filter_loading_indicator',
          ),
          emptyLabelKey: const Key('project_search_tags_filter_empty_label'),
          itemKeyOf: (tag) => Key('project_search_tag_filter_item_$tag'),
          clearAllButtonKey: const Key(
            'project_search_tags_filter_clear_all_button',
          ),
          applyButtonKey: const Key('project_search_tags_filter_apply_button'),
        );
      },
    );
  }
}
