import 'package:construculator/features/global_search/presentation/widgets/global_search_empty_recent_widget.dart';
import 'package:construculator/features/global_search/presentation/widgets/global_search_filter_chip_widget.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// The Global Search screen.
///
/// Provides a search input field, filter chips (Tags, Modified, Type),
/// a recent searches section, and an empty state when no recent searches exist.
///
/// This screen is UI-only and is not yet connected to [GlobalSearchBloc].
class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  late final AppRouter _router = Modular.get<AppRouter>();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final hasText = _searchController.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
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
                color: colors.textDark,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClearButton(BuildContext context) {
    final colors = context.colorTheme;
    final l10n = context.l10n;

    return Semantics(
      label: l10n.globalSearchClearSearchSemanticLabel,
      button: true,
      child: GestureDetector(
        key: const Key('global_search_clear_button'),
        onTap: () => _searchController.clear(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: CoreSpacing.space12,
            minHeight: CoreSpacing.space12,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(right: CoreSpacing.space2),
              child: CoreIconWidget(
                icon: CoreIcons.close,
                color: colors.textBody,
                size: CoreSpacing.space4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;
    final l10n = context.l10n;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: CoreSpacing.space12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              textAlignVertical: TextAlignVertical.center,
              textInputAction: TextInputAction.search,
              minLines: 1,
              maxLines: 1,
              style: typography.bodyMediumRegular.copyWith(
                color: colors.textDark,
              ),
              decoration: InputDecoration(
                hintText: l10n.globalSearchHint,
                hintStyle: typography.bodyMediumRegular.copyWith(
                  color: colors.textBody,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: false,
                constraints: const BoxConstraints(
                  minHeight: CoreSpacing.space12,
                ),
                contentPadding: const EdgeInsets.only(
                  left: CoreSpacing.space2,
                  right: CoreSpacing.space2,
                  top: CoreSpacing.space4,
                  bottom: CoreSpacing.space4,
                ),
              ),
            ),
          ),
          if (_hasText) _buildClearButton(context),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colors.pageBackground,
      appBar: AppBar(
        backgroundColor: colors.pageBackground,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          children: [
            _buildBackButton(context),
            Expanded(child: _buildSearchField(context)),
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
            child: Row(
              children: [
                // TODO: [CA-638] Wire GlobalSearchFilterChipWidget.onTap to GlobalSearchBloc filter state. https://ripplearc.youtrack.cloud/issue/CA-638/DashboardGlobalSearch-Wire-GlobalSearchFilterChipWidget.onTap-to-GlobalSearchBloc-filter-state
                GlobalSearchFilterChipWidget(label: l10n.globalSearchFilterTags),
                const SizedBox(width: CoreSpacing.space2),
                GlobalSearchFilterChipWidget(
                  label: l10n.globalSearchFilterModified,
                ),
                const SizedBox(width: CoreSpacing.space2),
                GlobalSearchFilterChipWidget(
                  label: l10n.globalSearchFilterType,
                ),
              ],
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
          const Expanded(child: GlobalSearchEmptyRecentWidget()),
        ],
      ),
    );
  }
}
