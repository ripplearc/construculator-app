import 'package:construculator/features/global_search/presentation/bloc/global_search_bloc/global_search_bloc.dart';
import 'package:construculator/features/global_search/presentation/widgets/global_search_empty_recent_widget.dart';
import 'package:construculator/features/global_search/presentation/widgets/global_search_recent_searches_list.dart';
import 'package:construculator/features/global_search/presentation/widgets/global_search_tags_filter_sheet.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// The Global Search screen.
///
/// Provides a search input field, filter chips (Tags, Modified, Type),
/// a recent searches section, and an empty state when no recent searches exist.
class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  late final TextEditingController _searchController = TextEditingController();
  late final AppRouter _router = Modular.get<AppRouter>();
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
    return CoreQuickSheet.show(
      context: context,
      child: BlocProvider.value(
        value: BlocProvider.of<GlobalSearchBloc>(context),
        child: GlobalSearchTagsFilterSheet(initialSelectedTags: selectedTags),
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
        onTap: () => _router.pop(),
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
    final colors = context.colorTheme;
    final typography = context.textTheme;
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
          Semantics(
            label: l10n.globalSearchClearTagFilterSemanticLabel(tag),
            button: true,
            child: InkWell(
              key: Key('active_tag_chip_$tag'),
              onTap: () => BlocProvider.of<GlobalSearchBloc>(
                context,
              ).add(GlobalSearchTagFilterCleared(tag: tag)),
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
                        tag,
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

  Widget _buildBody(BuildContext context, GlobalSearchState state) {
    if (state is GlobalSearchInitial) {
      return const Center(child: CoreLoadingIndicator());
    }
    if (state is GlobalSearchReady) {
      _lastReady = state;
    }
    final effectiveReady = state is GlobalSearchReady ? state : _lastReady;
    if (effectiveReady != null && effectiveReady.recentSearches.isNotEmpty) {
      return GlobalSearchRecentSearchesList(
        recentSearches: effectiveReady.recentSearches,
        onItemTap: (term) => _onItemTap(context, term),
        onTrailingTap: (term) => _onTrailingTap(context, term),
      );
    }
    return const GlobalSearchEmptyRecentWidget();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;
    final l10n = context.l10n;

    return BlocProvider(
      create: (_) =>
          Modular.get<GlobalSearchBloc>()..add(const GlobalSearchStarted()),
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
                    final p = prev is GlobalSearchReady
                        ? prev.selectedTags
                        : null;
                    final c = curr is GlobalSearchReady
                        ? curr.selectedTags
                        : null;
                    return p != c;
                  },
                  builder: (context, state) {
                    final effectiveTags = state is GlobalSearchReady
                        ? state.selectedTags
                        : _lastReady?.selectedTags ?? const {};
                    return Row(
                      children: [
                        _buildTagsFilterChips(context, effectiveTags),
                        const SizedBox(width: CoreSpacing.space2),
                        // TODO: [CA-638] Wire Modified and Type chips. https://ripplearc.youtrack.cloud/issue/CA-638/DashboardGlobalSearch-Wire-CoreFilterChip.onTap-to-GlobalSearchBloc-filter-state
                        CoreFilterChip(label: l10n.globalSearchFilterModified),
                        const SizedBox(width: CoreSpacing.space2),
                        CoreFilterChip(label: l10n.globalSearchFilterType),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CoreSpacing.space4,
                  vertical: CoreSpacing.space3,
                ),
                child: Text(
                  l10n.globalSearchRecentSearchesTitle,
                  style: typography.bodyLargeSemiBold,
                ),
              ),
              Expanded(
                child: BlocConsumer<GlobalSearchBloc, GlobalSearchState>(
                  listener: (context, state) {
                    final l10n = context.l10n;
                    if (state is GlobalSearchLoadFailure) {
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
