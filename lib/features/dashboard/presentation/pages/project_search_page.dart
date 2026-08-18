import 'package:construculator/features/dashboard/presentation/bloc/project_dropdown_bloc/project_dropdown_bloc.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_search_bloc/project_search_bloc.dart';
import 'package:construculator/features/dashboard/presentation/widgets/project_search_empty_recent_widget.dart';
import 'package:construculator/features/dashboard/presentation/widgets/project_search_owner_filter_sheet.dart';
import 'package:construculator/features/dashboard/presentation/widgets/project_search_recent_searches_list.dart';
import 'package:construculator/features/dashboard/presentation/widgets/project_search_results_views.dart';
import 'package:construculator/features/dashboard/presentation/widgets/project_search_suggestions_list.dart';
import 'package:construculator/features/dashboard/presentation/widgets/project_search_tags_filter_sheet.dart';
import 'package:construculator/libraries/auth/domain/entities/user_profile_entity.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:construculator/libraries/global_search/presentation/widgets/search_load_failure_widget.dart';
import 'package:construculator/libraries/global_search/presentation/widgets/search_results_views.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// The Project Search screen.
///
/// Mirrors the Global Search page's app bar (back button + search box) and
/// body scaffold, wired to [ProjectSearchBloc] instead of `GlobalSearchBloc`.
/// Reached from [ProjectsBottomSheet]'s search field.
class ProjectSearchPage extends StatefulWidget {
  /// Router used for navigation (e.g. popping this page).
  final AppRouter router;

  /// Factory that produces a fresh [ProjectSearchBloc] instance for each
  /// navigation.
  final ProjectSearchBloc Function() blocFactory;

  /// Shell-scoped dropdown bloc that owns project selection; tapping a
  /// search result dispatches [ProjectDropdownSelected] on it, mirroring
  /// the projects sheet.
  final ProjectDropdownBloc projectDropdownBloc;

  const ProjectSearchPage({
    super.key,
    required this.router,
    required this.blocFactory,
    required this.projectDropdownBloc,
  });

  @override
  State<ProjectSearchPage> createState() => _ProjectSearchPageState();
}

/// Derived view flags shared by [_ProjectSearchPageState._buildBody] and
/// [_ProjectSearchPageState._buildSectionTitle] so both read the same
/// `ProjectSearchInitial` fields instead of re-deriving them independently.
class _ProjectSearchViewState {
  final bool hasQuery;
  final bool hasSuggestions;
  final bool suggestionsLoading;

  const _ProjectSearchViewState({
    required this.hasQuery,
    required this.hasSuggestions,
    required this.suggestionsLoading,
  });

  factory _ProjectSearchViewState.from(ProjectSearchState state) {
    if (state is! ProjectSearchInitial) {
      return const _ProjectSearchViewState(
        hasQuery: false,
        hasSuggestions: false,
        suggestionsLoading: false,
      );
    }
    return _ProjectSearchViewState(
      hasQuery: state.query.isNotEmpty,
      hasSuggestions: state.suggestions.isNotEmpty,
      suggestionsLoading: state.suggestionsLoading,
    );
  }
}

class _ProjectSearchPageState extends State<ProjectSearchPage> {
  late final TextEditingController _searchController = TextEditingController();

  // The most recent [ProjectSearchInitial] seen. The filter chip row must keep
  // rendering the active selections while the body shows a non-initial state
  // (loading / results / failure), so we cache the last idle state to read the
  // selected filters from.
  ProjectSearchInitial? _lastInitial;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onItemTap(BuildContext context, String term) {
    _searchController.text = term;
    BlocProvider.of<ProjectSearchBloc>(
      context,
    ).add(ProjectSearchPerformedEvent(query: term));
  }

  void _onTrailingTap(BuildContext context, String term) {
    _searchController.text = term;
    BlocProvider.of<ProjectSearchBloc>(
      context,
    ).add(ProjectSearchQueryUpdatedEvent(query: term));
  }

  // Dispatches the deletion and resolves the Dismissible's confirmDismiss
  // on this term's own outcome ack: true on the success state (the row's
  // data is already gone), false on the delete-failure state (the row
  // slides back while the toast surfaces the failure). Matching on the
  // echoed term keeps concurrent swipes from resolving each other.
  Future<bool> _onHistoryDismissRequested(
    BuildContext context,
    String term,
  ) async {
    final bloc = BlocProvider.of<ProjectSearchBloc>(context);
    final outcome = bloc.stream.firstWhere(
      (state) =>
          (state is ProjectSearchHistoryDeleteSuccess &&
              state.searchTerm == term) ||
          (state is ProjectSearchHistoryDeleteFailure &&
              state.searchTerm == term),
    );
    bloc.add(ProjectSearchHistoryItemDismissedEvent(searchTerm: term));
    try {
      final state = await outcome;
      return state is ProjectSearchHistoryDeleteSuccess;
    } catch (_) {
      // The bloc closed with the outcome unobserved (page disposed, or the
      // surface changed before it landed); the row is unmounted either way.
      return false;
    }
  }

  void _onProjectResultTap(Project project) {
    widget.projectDropdownBloc.add(ProjectDropdownSelected(project.id));
    widget.router.pop();
  }

  Future<void> _showTagsSheet(BuildContext context, Set<String> selectedTags) {
    BlocProvider.of<ProjectSearchBloc>(
      context,
    ).add(const ProjectSearchAvailableTagsRequestedEvent());
    return CoreQuickSheet.show(
      context: context,
      child: BlocProvider.value(
        value: BlocProvider.of<ProjectSearchBloc>(context),
        child: ProjectSearchTagsFilterSheet(initialSelectedTags: selectedTags),
      ),
    );
  }

  Future<void> _showOwnerSheet(
    BuildContext context,
    Set<String> selectedOwnerIds,
  ) {
    BlocProvider.of<ProjectSearchBloc>(
      context,
    ).add(const ProjectSearchAvailableOwnersRequestedEvent());
    return CoreQuickSheet.show(
      context: context,
      child: BlocProvider.value(
        value: BlocProvider.of<ProjectSearchBloc>(context),
        child: ProjectSearchOwnerFilterSheet(
          initialSelectedOwnerIds: selectedOwnerIds,
        ),
      ),
    );
  }

  Widget _buildTagsFilterChip(BuildContext context, Set<String> selectedTags) {
    final l10n = context.l10n;

    if (selectedTags.isEmpty) {
      return Semantics(
        label: l10n.projectSearchFilterTagsSemanticLabel,
        child: CoreFilterChip(
          key: const Key('project_search_tags_filter_chip'),
          label: l10n.projectSearchFilterTags,
          onTap: () => _showTagsSheet(context, selectedTags),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final tag in selectedTags) ...[
          _ActiveFilterPill(
            key: Key('project_search_active_tag_chip_$tag'),
            label: tag,
            semanticLabel: l10n.projectSearchClearTagFilterSemanticLabel(tag),
            onTap: () => context.read<ProjectSearchBloc>().add(
              ProjectSearchTagFilterClearedEvent(tag: tag),
            ),
          ),
          const SizedBox(width: CoreSpacing.space2),
        ],
        Semantics(
          label: l10n.projectSearchFilterTagsSemanticLabel,
          child: CoreFilterChip(
            key: const Key('project_search_tags_filter_chip_active'),
            label: l10n.projectSearchFilterTags,
            onTap: () => _showTagsSheet(context, selectedTags),
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerFilterChip(
    BuildContext context,
    Set<String> selectedOwnerIds,
    List<UserProfile> availableOwners,
  ) {
    final l10n = context.l10n;

    if (selectedOwnerIds.isEmpty) {
      return Semantics(
        label: l10n.projectSearchFilterOwnerSemanticLabel,
        child: CoreFilterChip(
          key: const Key('project_search_owner_filter_chip'),
          label: l10n.projectSearchFilterOwner,
          onTap: () => _showOwnerSheet(context, selectedOwnerIds),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final ownerId in selectedOwnerIds) ...[
          _ActiveFilterPill(
            key: Key('project_search_active_owner_chip_$ownerId'),
            label: _ownerLabel(ownerId, availableOwners),
            semanticLabel: l10n.projectSearchClearOwnerFilterSemanticLabel(
              _ownerLabel(ownerId, availableOwners),
            ),
            onTap: () => context.read<ProjectSearchBloc>().add(
              ProjectSearchOwnerFilterClearedEvent(ownerId: ownerId),
            ),
          ),
          const SizedBox(width: CoreSpacing.space2),
        ],
        Semantics(
          label: l10n.projectSearchFilterOwnerSemanticLabel,
          child: CoreFilterChip(
            key: const Key('project_search_owner_filter_chip_active'),
            label: l10n.projectSearchFilterOwner,
            onTap: () => _showOwnerSheet(context, selectedOwnerIds),
          ),
        ),
      ],
    );
  }

  // Resolves an owner id to its display name, falling back to the id when the
  // available-owners list has not been fetched yet (e.g. a filter restored
  // before the sheet was opened this session).
  String _ownerLabel(String ownerId, List<UserProfile> availableOwners) {
    for (final owner in availableOwners) {
      if (owner.id == ownerId) return owner.fullName;
    }
    return ownerId;
  }

  Widget _buildBackButton(BuildContext context) {
    final colors = context.colorTheme;
    final l10n = context.l10n;

    return Semantics(
      label: l10n.projectSearchBackSemanticLabel,
      button: true,
      child: GestureDetector(
        key: const Key('project_search_back_button'),
        onTap: () => widget.router.pop(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: CoreSpacing.space12,
            minHeight: CoreSpacing.space12,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CoreSpacing.space4,
              ),
              child: CoreIconWidget(
                icon: CoreIcons.arrowLeft,
                color: colors.iconDark,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProjectSearchState state) {
    if (state is ProjectSearchFailureState) {
      return SearchLoadFailureWidget(
        onRetry: () => BlocProvider.of<ProjectSearchBloc>(
          context,
        ).add(ProjectSearchPerformedEvent(query: state.query)),
      );
    }
    if (state is ProjectSearchLoading) {
      return const SearchResultsLoadingView();
    }
    if (state is ProjectSearchResultsLoaded) {
      if (state.results.isEmpty) {
        return SearchResultsEmptyView(query: state.query);
      }
      return ProjectSearchResultsList(
        results: state.results,
        onProjectTap: _onProjectResultTap,
      );
    }
    if (state is! ProjectSearchInitial) {
      return const SizedBox.shrink();
    }
    final viewState = _ProjectSearchViewState.from(state);
    if (viewState.hasQuery) {
      if (viewState.suggestionsLoading) {
        return const Center(child: CoreLoadingIndicator());
      }
      if (viewState.hasSuggestions) {
        return ProjectSearchSuggestionsList(
          suggestions: state.suggestions,
          query: state.query,
          onItemTap: (term) => _onItemTap(context, term),
          onTrailingTap: (term) => _onTrailingTap(context, term),
        );
      }
      return const SizedBox.shrink();
    }
    if (state.isLoadingHistory) {
      return const Center(child: CoreLoadingIndicator());
    }
    if (state.recentSearches.isEmpty) {
      return const ProjectSearchEmptyRecentWidget();
    }
    return ProjectSearchRecentSearchesList(
      recentSearches: state.recentSearches,
      onItemTap: (term) => _onItemTap(context, term),
      onTrailingTap: (term) => _onTrailingTap(context, term),
      onItemDismissRequested: (term) =>
          _onHistoryDismissRequested(context, term),
    );
  }

  Widget _buildSectionTitle(BuildContext context, ProjectSearchState state) {
    final l10n = context.l10n;
    final typography = context.textTheme;
    if (state is! ProjectSearchInitial) return const SizedBox.shrink();
    final viewState = _ProjectSearchViewState.from(state);
    if (viewState.hasQuery &&
        !viewState.hasSuggestions &&
        !viewState.suggestionsLoading) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CoreSpacing.space4,
        vertical: CoreSpacing.space3,
      ),
      child: Text(
        viewState.hasQuery
            ? l10n.projectSearchSuggestionsTitle
            : l10n.projectSearchRecentSearchesTitle,
        style: typography.bodyLargeSemiBold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final l10n = context.l10n;

    return BlocProvider(
      create: (_) =>
          widget.blocFactory()..add(const ProjectSearchHistoryRequestedEvent()),
      child: Builder(
        builder: (innerContext) => Scaffold(
          backgroundColor: colors.pageBackground,
          appBar: AppBar(
            backgroundColor: colors.pageBackground,
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            title: Row(
              children: [
                _buildBackButton(innerContext),
                Expanded(
                  child: CoreSearchBox(
                    controller: _searchController,
                    hintText: l10n.searchProjectsHint,
                    clearSemanticLabel:
                        l10n.projectSearchClearSearchSemanticLabel,
                    onChanged: (query) => BlocProvider.of<ProjectSearchBloc>(
                      innerContext,
                    ).add(ProjectSearchQueryUpdatedEvent(query: query)),
                    onSearch: () =>
                        BlocProvider.of<ProjectSearchBloc>(innerContext).add(
                          ProjectSearchPerformedEvent(
                            query: _searchController.text,
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
          body: BlocListener<ProjectSearchBloc, ProjectSearchState>(
            listenWhen: (prev, curr) =>
                curr is ProjectSearchFailureState ||
                curr is ProjectSearchTagsLoadFailure ||
                curr is ProjectSearchOwnersLoadFailure ||
                curr is ProjectSearchHistoryDeleteFailure,
            listener: (context, state) {
              final l10n = context.l10n;
              if (state is ProjectSearchFailureState) {
                CoreToast.showError(
                  context,
                  l10n.searchPerformErrorMessage,
                  l10n.closeLabel,
                );
              } else if (state is ProjectSearchTagsLoadFailure) {
                CoreToast.showWarning(
                  context,
                  l10n.projectSearchTagsLoadErrorMessage,
                  l10n.closeLabel,
                );
              } else if (state is ProjectSearchOwnersLoadFailure) {
                CoreToast.showWarning(
                  context,
                  l10n.projectSearchOwnersLoadErrorMessage,
                  l10n.closeLabel,
                );
              } else if (state is ProjectSearchHistoryDeleteFailure) {
                CoreToast.showError(
                  context,
                  l10n.projectSearchDeleteErrorMessage,
                  l10n.closeLabel,
                );
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: CoreSpacing.space4,
                    vertical: CoreSpacing.space3,
                  ),
                  child: BlocBuilder<ProjectSearchBloc, ProjectSearchState>(
                    buildWhen: (prev, curr) {
                      // Only rebuild the chip row when the active filters change.
                      if (curr is! ProjectSearchInitial) return false;
                      final prevInitial = _lastInitial;
                      return prevInitial == null ||
                          prevInitial.selectedTags != curr.selectedTags ||
                          prevInitial.selectedOwnerIds !=
                              curr.selectedOwnerIds ||
                          prevInitial.selectedDateRange !=
                              curr.selectedDateRange ||
                          prevInitial.availableOwners != curr.availableOwners;
                    },
                    builder: (context, state) {
                      if (state is ProjectSearchInitial) {
                        _lastInitial = state;
                      }
                      final effective = _lastInitial;
                      final selectedTags =
                          effective?.selectedTags ?? const <String>{};
                      final selectedOwnerIds =
                          effective?.selectedOwnerIds ?? const <String>{};
                      final availableOwners =
                          effective?.availableOwners ?? const <UserProfile>[];
                      final selectedDateRange = effective?.selectedDateRange;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTagsFilterChip(context, selectedTags),
                          const SizedBox(width: CoreSpacing.space2),
                          _buildOwnerFilterChip(
                            context,
                            selectedOwnerIds,
                            availableOwners,
                          ),
                          const SizedBox(width: CoreSpacing.space2),
                          CoreDateFilterChip(
                            selectedDateRange: selectedDateRange,
                            label: l10n.projectSearchFilterModified,
                            semanticLabel:
                                l10n.projectSearchFilterModifiedSemanticLabel,
                            clearSemanticLabel:
                                l10n.projectSearchClearDateFilterSemanticLabel,
                            dateLabelBuilder: DisplayFormatter.formatDate,
                            sheetTitle: l10n.dateRangeSheetTitle,
                            todayLabel: l10n.dateRangeSheetToday,
                            last7DaysLabel: l10n.dateRangeSheetLast7Days,
                            last30DaysLabel: l10n.dateRangeSheetLast30Days,
                            thisMonthLabel: l10n.dateRangeSheetThisMonth,
                            customRangeLabel: l10n.dateRangeSheetCustomRange,
                            startDateLabel: l10n.dateRangeSheetStartDateLabel,
                            endDateLabel: l10n.dateRangeSheetEndDateLabel,
                            cancelLabel: l10n.dateRangeSheetCancel,
                            applyLabel: l10n.dateRangeSheetApply,
                            confirmLabel: l10n.dateRangeSheetConfirm,
                            inactiveChipKey: const Key(
                              'project_search_modified_filter_chip',
                            ),
                            activeChipKey: const Key(
                              'project_search_active_modified_filter_chip',
                            ),
                            onApply: (range) =>
                                context.read<ProjectSearchBloc>().add(
                                  ProjectSearchDateFilterAppliedEvent(
                                    range: range,
                                  ),
                                ),
                            onClear: () =>
                                context.read<ProjectSearchBloc>().add(
                                  const ProjectSearchDateFilterClearedEvent(),
                                ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                BlocBuilder<ProjectSearchBloc, ProjectSearchState>(
                  builder: (context, state) =>
                      _buildSectionTitle(context, state),
                ),
                Expanded(
                  child: BlocBuilder<ProjectSearchBloc, ProjectSearchState>(
                    builder: (context, state) => _buildBody(context, state),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// An active filter pill showing a selected [label] with a trailing × that
/// clears the filter on tap.
///
/// Used for both the active tag and owner filter chips on the project search
/// screen so the two share identical layout and accessibility behavior.
class _ActiveFilterPill extends StatelessWidget {
  final String label;
  final String semanticLabel;
  final VoidCallback onTap;

  const _ActiveFilterPill({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;

    return Semantics(
      label: semanticLabel,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CoreSpacing.space3),
        child: Container(
          // Guarantee a 48dp-tall tap target to meet the minimum tap-target
          // accessibility guideline.
          constraints: const BoxConstraints(minHeight: CoreSpacing.space12),
          padding: const EdgeInsets.symmetric(
            horizontal: CoreSpacing.space3,
            vertical: CoreSpacing.space2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CoreSpacing.space3),
            color: colors.backgroundGrayMid,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Text(
                  label,
                  style: typography.bodyMediumRegular.copyWith(
                    color: colors.textDark,
                  ),
                ),
              ),
              const SizedBox(width: CoreSpacing.space2),
              ExcludeSemantics(
                child: CoreIconWidget(
                  icon: CoreIcons.close,
                  color: colors.iconDark,
                  size: CoreSpacing.space4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
