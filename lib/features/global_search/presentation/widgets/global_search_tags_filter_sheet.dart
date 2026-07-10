import 'package:construculator/features/global_search/presentation/bloc/global_search_bloc/global_search_bloc.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/search_filters/presentation/widgets/multi_select_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A modal bottom sheet for selecting tag filters in the global search screen.
///
/// A thin wrapper around the shared [MultiSelectFilterSheet]: the available
/// tags and search filtering are owned by [GlobalSearchBloc]. The sheet
/// dispatches [GlobalSearchTagSearchQueryUpdated] as the user types and
/// renders [GlobalSearchReady.availableTags]. Tag selection is kept local
/// until the user taps Apply, at which point the sheet dispatches
/// [GlobalSearchTagFiltersApplied] and pops itself. Tapping Clear all
/// deselects all tags without dismissing the sheet.
class GlobalSearchTagsFilterSheet extends StatelessWidget {
  /// The tags already selected when the sheet opens.
  final Set<String> initialSelectedTags;

  /// Creates a [GlobalSearchTagsFilterSheet].
  const GlobalSearchTagsFilterSheet({
    super.key,
    required this.initialSelectedTags,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<GlobalSearchBloc, GlobalSearchState>(
      buildWhen: (prev, curr) => curr is GlobalSearchReady,
      builder: (context, state) {
        return MultiSelectFilterSheet(
          title: l10n.globalSearchTagsSheetTitle,
          searchHint: l10n.globalSearchTagsSheetSearchHint,
          emptyLabel: l10n.globalSearchTagsSheetEmpty,
          clearAllLabel: l10n.globalSearchTagsSheetClearAll,
          applyLabel: l10n.globalSearchTagsSheetApply,
          initialSelectedIds: initialSelectedTags,
          listData: state is GlobalSearchReady
              ? MultiSelectFilterListData(
                  isLoading: state.availableTagsLoading,
                  items: [
                    for (final tag in state.availableTags)
                      MultiSelectFilterItem(id: tag, label: tag),
                  ],
                )
              : null,
          onSearchQueryChanged: (query) => BlocProvider.of<GlobalSearchBloc>(
            context,
          ).add(GlobalSearchTagSearchQueryUpdated(query: query)),
          onApply: (tags) => BlocProvider.of<GlobalSearchBloc>(
            context,
          ).add(GlobalSearchTagFiltersApplied(tags: tags)),
          loadingIndicatorKey: const Key('tags_filter_loading_indicator'),
          emptyLabelKey: const Key('tags_filter_empty_label'),
          itemKeyOf: (tag) => Key('tag_filter_item_$tag'),
          clearAllButtonKey: const Key('tags_filter_clear_all_button'),
          applyButtonKey: const Key('tags_filter_apply_button'),
        );
      },
    );
  }
}
