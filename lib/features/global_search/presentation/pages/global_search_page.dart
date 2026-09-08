import 'package:construculator/features/dashboard/presentation/bloc/project_dropdown_bloc/project_dropdown_bloc.dart';
import 'package:construculator/features/global_search/domain/entities/search_scope_entity.dart';
import 'package:construculator/features/global_search/presentation/bloc/global_search_bloc/global_search_bloc.dart';
import 'package:construculator/features/global_search/presentation/widgets/global_search_empty_recent_widget.dart';
import 'package:construculator/features/global_search/presentation/widgets/global_search_recent_searches_list.dart';
import 'package:construculator/features/global_search/presentation/widgets/global_search_suggestions_list.dart';
import 'package:construculator/features/global_search/presentation/widgets/global_search_tags_filter_sheet.dart';
import 'package:construculator/features/global_search/presentation/widgets/global_search_type_filter_sheet.dart';
import 'package:construculator/features/global_search/presentation/widgets/search_results_views.dart';
import 'package:construculator/libraries/estimation/domain/estimation_tile_provider.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:construculator/libraries/global_search/presentation/widgets/search_load_failure_widget.dart';
import 'package:construculator/libraries/global_search/presentation/widgets/search_results_views.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/estimation_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// The Global Search screen.
///
/// Provides a search input field, filter chips (Tags, Modified, Type),
/// a recent searches section, and an empty state when no recent searches exist.
class GlobalSearchPage extends StatefulWidget {
  /// Router used for navigation (e.g. popping this page).
  final AppRouter router;

  /// Factory that produces a fresh [GlobalSearchBloc] instance for each navigation.
  final GlobalSearchBloc Function() blocFactory;

  /// Supplies display data for the estimation result cards.
  final EstimationTileProvider estimationTileProvider;

  /// The shell-owned selection bloc; tapping a project result dispatches
  /// [ProjectDropdownSelected] on it, mirroring ProjectSearchPage.
  final ProjectDropdownBloc projectDropdownBloc;

  const GlobalSearchPage({
    super.key,
    required this.router,
    required this.blocFactory,
    required this.estimationTileProvider,
    required this.projectDropdownBloc,
  });

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  late final TextEditingController _searchController = TextEditingController();
  GlobalSearchReady? _lastReady;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onItemTap(BuildContext context, String term) {
    _searchController.text = term;
    BlocProvider.of<GlobalSearchBloc>(
      context,
    ).add(GlobalSearchPerformed(query: term));
  }

  void _onTrailingTap(BuildContext context, String term) {
    _searchController.text = term;
    BlocProvider.of<GlobalSearchBloc>(
      context,
    ).add(GlobalSearchQueryUpdated(query: term));
  }

  Future<void> _showTagsSheet(BuildContext context, Set<String> selectedTags) {
    BlocProvider.of<GlobalSearchBloc>(
      context,
    ).add(const GlobalSearchAvailableTagsRequested());
    return CoreQuickSheet.show(
      context: context,
      child: BlocProvider.value(
        value: BlocProvider.of<GlobalSearchBloc>(context),
        child: GlobalSearchTagsFilterSheet(initialSelectedTags: selectedTags),
      ),
    );
  }

  Future<void> _showTypeSheet(BuildContext context, SearchScope selectedScope) {
    final bloc = BlocProvider.of<GlobalSearchBloc>(context);
    return CoreQuickSheet.show(
      context: context,
      child: GlobalSearchTypeFilterSheet(
        selectedScope: selectedScope,
        onApply: (scope) => bloc.add(GlobalSearchScopeChanged(scope: scope)),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    final colors = context.colorTheme;
    final l10n = context.l10n;

    return Semantics(
      label: l10n.globalSearchBackSemanticLabel,
      button: true,
      child: GestureDetector(
        key: const Key('global_search_back_button'),
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

  Widget _buildTagsFilterChips(BuildContext context, Set<String> selectedTags) {
    final l10n = context.l10n;

    if (selectedTags.isEmpty) {
      return Semantics(
        label: l10n.globalSearchFilterTagsSemanticLabel,
        child: CoreFilterChip(
          key: const Key('global_search_tags_filter_chip'),
          label: l10n.globalSearchFilterTags,
          onTap: () => _showTagsSheet(context, selectedTags),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final tag in selectedTags) ...[
          _ActiveFilterPill(
            key: Key('active_tag_chip_$tag'),
            label: tag,
            semanticLabel: l10n.globalSearchClearTagFilterSemanticLabel(tag),
            onTap: () => BlocProvider.of<GlobalSearchBloc>(
              context,
            ).add(GlobalSearchTagFilterCleared(tag: tag)),
          ),
          const SizedBox(width: CoreSpacing.space2),
        ],
        CoreFilterChip(
          key: const Key('global_search_tags_filter_chip_active'),
          label: l10n.globalSearchFilterTags,
          onTap: () => _showTagsSheet(context, selectedTags),
        ),
      ],
    );
  }

  Widget _buildTypeFilterChip(BuildContext context, SearchScope selectedScope) {
    final l10n = context.l10n;

    if (selectedScope == SearchScope.dashboard) {
      return Semantics(
        label: l10n.globalSearchFilterTypeSemanticLabel,
        child: CoreFilterChip(
          key: const Key('global_search_type_filter_chip'),
          label: l10n.globalSearchFilterType,
          onTap: () => _showTypeSheet(context, selectedScope),
        ),
      );
    }

    final typeLabel = _typeLabel(context, selectedScope);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActiveFilterPill(
          key: Key('active_type_chip_${selectedScope.name}'),
          label: typeLabel,
          semanticLabel: l10n.globalSearchClearTypeFilterSemanticLabel(
            typeLabel,
          ),
          onTap: () => BlocProvider.of<GlobalSearchBloc>(context).add(
            const GlobalSearchScopeChanged(scope: SearchScope.dashboard),
          ),
        ),
        const SizedBox(width: CoreSpacing.space2),
        CoreFilterChip(
          key: const Key('global_search_type_filter_chip_active'),
          label: l10n.globalSearchFilterType,
          onTap: () => _showTypeSheet(context, selectedScope),
        ),
      ],
    );
  }

  // Maps a scope to its user-facing Type label.
  String _typeLabel(BuildContext context, SearchScope scope) {
    final l10n = context.l10n;
    return switch (scope) {
      SearchScope.estimation => l10n.globalSearchTypeCostLabel,
      SearchScope.calculation => l10n.globalSearchTypeCalculationLabel,
      // dashboard is unreachable (no pill renders for the default scope);
      // member is not offered by the Type sheet — fail loudly rather than
      // silently mislabelling the pill if a future caller reaches here.
      SearchScope.dashboard || SearchScope.member => throw StateError(
          'unreachable: _typeLabel called for scope $scope',
        ),
    };
  }

  // Dispatches the deletion and resolves the Dismissible's confirmDismiss
  // on this term's own outcome ack: true on the success state (the row's
  // data is already gone), false on the delete-failure state (the row
  // slides back while the toast surfaces the failure). Matching on the
  // echoed term keeps concurrent swipes from resolving each other.
  Future<bool> _onRecentDismissRequested(
    BuildContext context,
    String term,
    SearchScope scope,
  ) async {
    final bloc = context.read<GlobalSearchBloc>();
    final outcome = bloc.stream.firstWhere(
      (state) =>
          (state is GlobalSearchRecentDeleteSuccess &&
              state.searchTerm == term) ||
          (state is GlobalSearchRecentDeleteFailure &&
              state.searchTerm == term),
    );
    bloc.add(GlobalSearchRecentRemoved(searchTerm: term, scope: scope));
    try {
      final state = await outcome;
      return state is GlobalSearchRecentDeleteSuccess;
    } catch (_) {
      // The bloc closed with the outcome unobserved (page disposed, or the
      // surface changed before it landed); the row is unmounted either way.
      return false;
    }
  }

  GlobalSearchReady? _effectiveReady(GlobalSearchState state) {
    if (state is GlobalSearchReady) {
      _lastReady = state;
    }
    final effectiveReady = state is GlobalSearchReady ? state : _lastReady;
    if (state is GlobalSearchSuggestionsLoadFailure) {
      return effectiveReady?.copyWith(suggestionsLoading: false);
    }
    return effectiveReady;
  }

  Widget _buildBody(BuildContext context, GlobalSearchState state) {
    if (state is GlobalSearchInitial) {
      return const Center(child: CoreLoadingIndicator());
    }
    if (state is GlobalSearchLoadFailure) {
      return SearchLoadFailureWidget(
        onRetry: () => context.read<GlobalSearchBloc>().add(
              GlobalSearchPerformed(query: state.query),
            ),
      );
    }
    if (state is GlobalSearchLoadInProgress) {
      return const SearchResultsLoadingView();
    }
    if (state is GlobalSearchLoadSuccess) {
      return SearchResultsList(
        results: state.results,
        // Mirrors ProjectSearchPage: selection stays owned by the shell's
        // ProjectDropdownBloc, and popping returns to the shell showing
        // the newly selected project.
        onProjectTap: (project) {
          widget.projectDropdownBloc.add(
            ProjectDropdownSelected(project.id),
          );
          widget.router.pop();
        },
        onEstimationTap: (estimation) => widget.router.pushNamed(
          '$fullEstimationDetailsRoute/${estimation.id}',
        ),
        hasMore: state.hasMoreEstimations,
        isLoadingMore:
            state.loadMoreStatus == GlobalSearchLoadMoreStatus.inProgress,
        loadMoreFailed:
            state.loadMoreStatus == GlobalSearchLoadMoreStatus.failure,
        onLoadMore: () => context.read<GlobalSearchBloc>().add(
              const GlobalSearchLoadMoreRequested(),
            ),
        onRetryLoadMore: () => context.read<GlobalSearchBloc>().add(
              const GlobalSearchLoadMoreRequested(),
            ),
        estimationTileProvider: widget.estimationTileProvider,
      );
    }
    if (state is GlobalSearchLoadEmpty) {
      return SearchResultsEmptyView(query: state.query);
    }
    final effectiveReady = _effectiveReady(state);
    if (effectiveReady == null) {
      return const GlobalSearchEmptyRecentWidget();
    }
    if (effectiveReady.query.isNotEmpty) {
      if (effectiveReady.suggestionsLoading) {
        return const Center(child: CoreLoadingIndicator());
      }
      if (effectiveReady.suggestions.isNotEmpty) {
        return GlobalSearchSuggestionsList(
          suggestions: effectiveReady.suggestions,
          query: effectiveReady.query,
          onItemTap: (term) => _onItemTap(context, term),
          onTrailingTap: (term) => _onTrailingTap(context, term),
        );
      }
      return const SizedBox.shrink();
    }
    if (effectiveReady.recentSearches.isNotEmpty) {
      return GlobalSearchRecentSearchesList(
        recentSearches: effectiveReady.recentSearches,
        onItemTap: (term) => _onItemTap(context, term),
        onTrailingTap: (term) => _onTrailingTap(context, term),
        onItemDismissRequested: (term) => _onRecentDismissRequested(
          context,
          term,
          // The scope owning the DISPLAYED history, which lags selectedScope
          // while a scope change's reload is in flight — the swiped row
          // belongs to it, not to the newly selected scope.
          effectiveReady.recentsScope,
        ),
      );
    }
    return const GlobalSearchEmptyRecentWidget();
  }

  Widget _buildSectionTitle(BuildContext context, GlobalSearchState state) {
    // Result states render their own header inside the results surface
    // ("Most relevant") or none at all, so the recents/suggestions title
    // must not linger above them.
    if (state is GlobalSearchLoadFailure ||
        state is GlobalSearchLoadInProgress ||
        state is GlobalSearchLoadSuccess ||
        state is GlobalSearchLoadEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final typography = context.textTheme;
    final effectiveReady = _effectiveReady(state);
    final query = effectiveReady?.query ?? '';
    final hasQuery = query.isNotEmpty;
    final hasSuggestions = effectiveReady?.suggestions.isNotEmpty ?? false;
    final loading = effectiveReady?.suggestionsLoading ?? false;
    if (hasQuery && !hasSuggestions && !loading) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CoreSpacing.space4,
        vertical: CoreSpacing.space3,
      ),
      child: Text(
        hasQuery
            ? l10n.globalSearchSuggestionsTitle
            : l10n.globalSearchRecentSearchesTitle,
        style: typography.bodyLargeSemiBold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final l10n = context.l10n;

    return BlocProvider(
      create: (_) => widget.blocFactory()..add(const GlobalSearchStarted()),
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
                    hintText: l10n.globalSearchHint,
                    clearSemanticLabel:
                        l10n.globalSearchClearSearchSemanticLabel,
                    onChanged: (query) => BlocProvider.of<GlobalSearchBloc>(
                      innerContext,
                    ).add(GlobalSearchQueryUpdated(query: query)),
                    onSearch: () => BlocProvider.of<GlobalSearchBloc>(
                      innerContext,
                    ).add(GlobalSearchPerformed(query: _searchController.text)),
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: CoreSpacing.space4,
                  vertical: CoreSpacing.space3,
                ),
                child: BlocBuilder<GlobalSearchBloc, GlobalSearchState>(
                  buildWhen: (prev, curr) {
                    // Reference equality is sufficient: each emit creates a new Set.unmodifiable.
                    final prevReady = prev is GlobalSearchReady ? prev : null;
                    final currReady = curr is GlobalSearchReady ? curr : null;
                    return prevReady?.selectedTags != currReady?.selectedTags ||
                        prevReady?.selectedDateRange !=
                            currReady?.selectedDateRange ||
                        prevReady?.selectedScope != currReady?.selectedScope;
                  },
                  builder: (context, state) {
                    final ready = state is GlobalSearchReady
                        ? state
                        : _lastReady;
                    final effectiveTags = ready?.selectedTags ?? const {};
                    final effectiveDateRange = ready?.selectedDateRange;
                    final effectiveScope =
                        ready?.selectedScope ?? SearchScope.dashboard;
                    return Row(
                      children: [
                        _buildTagsFilterChips(context, effectiveTags),
                        const SizedBox(width: CoreSpacing.space2),
                        CoreDateFilterChip(
                          selectedDateRange: effectiveDateRange,
                          label: l10n.globalSearchFilterModified,
                          semanticLabel:
                              l10n.globalSearchFilterModifiedSemanticLabel,
                          clearSemanticLabel:
                              l10n.globalSearchClearDateFilterSemanticLabel,
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
                            'global_search_date_filter_chip',
                          ),
                          activeChipKey: const Key('active_date_filter_chip'),
                          onApply: (range) => context
                              .read<GlobalSearchBloc>()
                              .add(GlobalSearchDateFilterApplied(range: range)),
                          onClear: () => context
                              .read<GlobalSearchBloc>()
                              .add(const GlobalSearchDateFilterCleared()),
                        ),
                        const SizedBox(width: CoreSpacing.space2),
                        _buildTypeFilterChip(context, effectiveScope),
                      ],
                    );
                  },
                ),
              ),
              BlocBuilder<GlobalSearchBloc, GlobalSearchState>(
                builder: (context, state) => _buildSectionTitle(context, state),
              ),
              Expanded(
                child: BlocConsumer<GlobalSearchBloc, GlobalSearchState>(
                  listenWhen: (prev, curr) =>
                      curr is GlobalSearchLoadFailure ||
                      curr is GlobalSearchRecentsLoadFailure ||
                      curr is GlobalSearchRecentDeleteFailure ||
                      curr is GlobalSearchSuggestionsLoadFailure ||
                      curr is GlobalSearchTagsLoadFailure ||
                      curr is GlobalSearchEmptyQuery,
                  listener: (context, state) {
                    final l10n = context.l10n;
                    if (state is GlobalSearchLoadFailure) {
                      CoreToast.showError(
                        context,
                        l10n.searchPerformErrorMessage,
                        l10n.closeLabel,
                      );
                    } else if (state is GlobalSearchRecentsLoadFailure) {
                      CoreToast.showError(
                        context,
                        l10n.globalSearchLoadErrorMessage,
                        l10n.closeLabel,
                      );
                    } else if (state is GlobalSearchRecentDeleteFailure) {
                      CoreToast.showError(
                        context,
                        l10n.globalSearchDeleteErrorMessage,
                        l10n.closeLabel,
                      );
                    } else if (state is GlobalSearchSuggestionsLoadFailure) {
                      CoreToast.showWarning(
                        context,
                        l10n.globalSearchSuggestionsErrorMessage,
                        l10n.closeLabel,
                      );
                    } else if (state is GlobalSearchTagsLoadFailure) {
                      CoreToast.showWarning(
                        context,
                        l10n.globalSearchTagsLoadErrorMessage,
                        l10n.closeLabel,
                      );
                    } else if (state is GlobalSearchEmptyQuery) {
                      CoreToast.showWarning(
                        context,
                        l10n.globalSearchEmptyQueryMessage,
                        l10n.closeLabel,
                      );
                    }
                  },
                  builder: (context, state) => _buildBody(context, state),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dismissible pill representing one active filter value (tag or type).
/// Tapping the pill clears that filter via [onTap].
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
