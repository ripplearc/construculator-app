import 'package:construculator/features/dashboard/presentation/bloc/project_search_bloc/project_search_bloc.dart';
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

class _ProjectSearchPageState extends State<ProjectSearchPage> {
  late final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildBackButton(BuildContext context) {
    final colors = context.colorTheme;
    final l10n = context.l10n;

    return Semantics(
      label: l10n.globalSearchBackSemanticLabel,
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
    // Recent-history (CA-690) and suggestions (CA-689) bodies land in
    // follow-up PRs hosted inside this page's scaffold.
    return const SizedBox.shrink();
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
                    clearSemanticLabel: l10n.globalSearchClearSearchSemanticLabel,
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
                    // TODO: [CA-771] Wire Owner + Modified filter chips to
                    // ProjectSearchBloc.
                    // https://ripplearc.youtrack.cloud/issue/CA-771
                    Semantics(
                      label: l10n.globalSearchFilterTagsSemanticLabel,
                      child: CoreFilterChip(
                        key: const Key('project_search_owner_filter_chip'),
                        label: l10n.globalSearchFilterTags,
                      ),
                    ),
                    const SizedBox(width: CoreSpacing.space2),
                    Semantics(
                      label: l10n.globalSearchFilterModifiedSemanticLabel,
                      child: CoreFilterChip(
                        key: const Key('project_search_modified_filter_chip'),
                        label: l10n.globalSearchFilterModified,
                      ),
                    ),
                  ],
                ),
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
