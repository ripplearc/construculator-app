import 'package:construculator/features/dashboard/presentation/bloc/project_search_bloc/project_search_bloc.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/search_filters/presentation/widgets/multi_select_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A modal bottom sheet for selecting owner filters on the project search
/// screen.
///
/// A thin wrapper around the shared [MultiSelectFilterSheet]: the available
/// owners and search filtering are owned by [ProjectSearchBloc]. The sheet
/// dispatches [ProjectSearchOwnerSearchQueryUpdatedEvent] as the user types
/// and renders [ProjectSearchInitial.availableOwners]. Owner selection is kept
/// local (by owner id) until the user taps Apply, at which point the sheet
/// dispatches [ProjectSearchOwnerFiltersAppliedEvent] and pops itself. Tapping
/// Clear all deselects all owners without dismissing the sheet.
class ProjectSearchOwnerFilterSheet extends StatelessWidget {
  /// The owner ids already selected when the sheet opens.
  final Set<String> initialSelectedOwnerIds;

  /// Creates a [ProjectSearchOwnerFilterSheet].
  const ProjectSearchOwnerFilterSheet({
    super.key,
    required this.initialSelectedOwnerIds,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<ProjectSearchBloc, ProjectSearchState>(
      buildWhen: (prev, curr) => curr is ProjectSearchInitial,
      builder: (context, state) {
        return MultiSelectFilterSheet(
          title: l10n.projectSearchOwnerSheetTitle,
          searchHint: l10n.projectSearchOwnerSheetSearchHint,
          emptyLabel: l10n.projectSearchOwnerSheetEmpty,
          clearAllLabel: l10n.projectSearchOwnerSheetClearAll,
          applyLabel: l10n.projectSearchOwnerSheetApply,
          initialSelectedIds: initialSelectedOwnerIds,
          listData: state is ProjectSearchInitial
              ? MultiSelectFilterListData(
                  isLoading: state.availableOwnersLoading,
                  items: [
                    for (final owner in state.availableOwners)
                      MultiSelectFilterItem(
                        id: owner.id,
                        label: owner.fullName,
                      ),
                  ],
                )
              : null,
          onSearchQueryChanged: (query) => BlocProvider.of<ProjectSearchBloc>(
            context,
          ).add(ProjectSearchOwnerSearchQueryUpdatedEvent(query: query)),
          onApply: (ownerIds) => BlocProvider.of<ProjectSearchBloc>(
            context,
          ).add(ProjectSearchOwnerFiltersAppliedEvent(ownerIds: ownerIds)),
          loadingIndicatorKey: const Key(
            'project_search_owner_filter_loading_indicator',
          ),
          emptyLabelKey: const Key('project_search_owner_filter_empty_label'),
          itemKeyOf: (ownerId) =>
              Key('project_search_owner_filter_item_$ownerId'),
          clearAllButtonKey: const Key(
            'project_search_owner_filter_clear_all_button',
          ),
          applyButtonKey: const Key(
            'project_search_owner_filter_apply_button',
          ),
        );
      },
    );
  }
}
