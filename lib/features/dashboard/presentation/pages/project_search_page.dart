import 'package:construculator/features/dashboard/presentation/bloc/project_search_bloc/project_search_bloc.dart';
import 'package:construculator/features/dashboard/presentation/widgets/project_search_empty_recent_widget.dart';
import 'package:construculator/features/dashboard/presentation/widgets/project_search_recent_searches_list.dart';
import 'package:construculator/features/dashboard/presentation/widgets/project_search_suggestions_list.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
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

  const ProjectSearchPage({
    super.key,
    required this.router,
    required this.blocFactory,
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
    if (state is! ProjectSearchInitial) {
      // Loading/results/failure surfaces are not part of CA-690/CA-689 scope
      // (history + suggestions only); render nothing rather than the last
      // history view.
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
                    clearSemanticLabel: l10n.projectSearchClearSearchSemanticLabel,
                    onChanged: (query) => BlocProvider.of<ProjectSearchBloc>(
                      innerContext,
                    ).add(ProjectSearchQueryUpdatedEvent(query: query)),
                    onSearch: () => BlocProvider.of<ProjectSearchBloc>(
                      innerContext,
                    ).add(
                      ProjectSearchPerformedEvent(
                        query: _searchController.text,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CoreSpacing.space4,
                  vertical: CoreSpacing.space3,
                ),
                child: Row(
                  children: [
                    // TODO: [CA-771] Wire Tags + Modified filter chips to
                    // ProjectSearchBloc.
                    // https://ripplearc.youtrack.cloud/issue/CA-771
                    Semantics(
                      label: l10n.projectSearchFilterTagsSemanticLabel,
                      child: CoreFilterChip(
                        key: const Key('project_search_tags_filter_chip'),
                        label: l10n.projectSearchFilterTags,
                      ),
                    ),
                    const SizedBox(width: CoreSpacing.space2),
                    Semantics(
                      label: l10n.projectSearchFilterModifiedSemanticLabel,
                      child: CoreFilterChip(
                        key: const Key('project_search_modified_filter_chip'),
                        label: l10n.projectSearchFilterModified,
                      ),
                    ),
                  ],
                ),
              ),
              BlocBuilder<ProjectSearchBloc, ProjectSearchState>(
                builder: (context, state) => _buildSectionTitle(context, state),
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
    );
  }
}
