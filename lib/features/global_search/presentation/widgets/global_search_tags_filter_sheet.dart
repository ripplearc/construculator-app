import 'package:construculator/features/global_search/presentation/bloc/global_search_bloc/global_search_bloc.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// A modal bottom sheet for selecting tag filters in the global search screen.
///
/// The available tags and search filtering are owned by [GlobalSearchBloc]:
/// the sheet dispatches [GlobalSearchTagSearchQueryUpdated] as the user types
/// and renders [GlobalSearchReady.availableTags]. Tag selection is kept local
/// until the user taps Apply, at which point the sheet dispatches
/// [GlobalSearchTagFiltersApplied] and pops itself. Tapping Clear all
/// deselects all tags without dismissing the sheet.
class GlobalSearchTagsFilterSheet extends StatefulWidget {
  /// The tags already selected when the sheet opens.
  final Set<String> initialSelectedTags;

  /// Creates a [GlobalSearchTagsFilterSheet].
  const GlobalSearchTagsFilterSheet({
    super.key,
    required this.initialSelectedTags,
  });

  @override
  State<GlobalSearchTagsFilterSheet> createState() =>
      _GlobalSearchTagsFilterSheetState();
}

class _GlobalSearchTagsFilterSheetState
    extends State<GlobalSearchTagsFilterSheet> {
  late Set<String> _localSelected;

  @override
  void initState() {
    super.initState();
    _localSelected = Set.of(widget.initialSelectedTags);
  }

  void _onApply(BuildContext context) {
    BlocProvider.of<GlobalSearchBloc>(context).add(
      GlobalSearchTagFiltersApplied(tags: Set.unmodifiable(_localSelected)),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final typography = context.textTheme;
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle(typography, l10n),
        _buildSearchField(context, l10n),
        _buildTagList(typography, l10n),
        _buildActionButtons(context, l10n),
      ],
    );
  }

  Widget _buildTitle(AppTypographyExtension typography, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CoreSpacing.space4,
        vertical: CoreSpacing.space3,
      ),
      child: Text(
        l10n.globalSearchTagsSheetTitle,
        style: typography.bodyLargeSemiBold,
      ),
    );
  }

  Widget _buildSearchField(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CoreSpacing.space4,
        vertical: CoreSpacing.space2,
      ),
      child: CoreTextField(
        hintText: l10n.globalSearchTagsSheetSearchHint,
        onChanged: (value) => BlocProvider.of<GlobalSearchBloc>(
          context,
        ).add(GlobalSearchTagSearchQueryUpdated(query: value)),
        prefix: const CoreIconWidget(
          icon: CoreIcons.search,
          size: CoreSpacing.space5,
        ),
      ),
    );
  }

  Widget _buildTagList(
    AppTypographyExtension typography,
    AppLocalizations l10n,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 300),
      child: BlocBuilder<GlobalSearchBloc, GlobalSearchState>(
        buildWhen: (prev, curr) => curr is GlobalSearchReady,
        builder: (context, state) {
          if (state is! GlobalSearchReady) {
            return const SizedBox.shrink();
          }
          if (state.availableTagsLoading) {
            return const Padding(
              padding: EdgeInsets.all(CoreSpacing.space6),
              child: Center(
                child: CoreLoadingIndicator(
                  key: Key('tags_filter_loading_indicator'),
                ),
              ),
            );
          }
          final tags = state.availableTags;
          if (tags.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(CoreSpacing.space6),
              child: Center(
                child: Text(
                  l10n.globalSearchTagsSheetEmpty,
                  key: const Key('tags_filter_empty_label'),
                  style: typography.bodyMediumRegular,
                ),
              ),
            );
          }
          return ListView.builder(
            shrinkWrap: true,
            itemCount: tags.length,
            itemBuilder: (_, index) {
              final tag = tags[index];
              final isSelected = _localSelected.contains(tag);
              return CheckboxListTile(
                key: Key('tag_filter_item_$tag'),
                value: isSelected,
                title: Text(tag, style: typography.bodyLargeRegular),
                // Ignore the nullable bool parameter; use the pre-captured
                // isSelected to avoid null-unwrapping and keep the toggle readable.
                onChanged: (_) => setState(() {
                  if (isSelected) {
                    _localSelected = Set.of(_localSelected)..remove(tag);
                  } else {
                    _localSelected = Set.of(_localSelected)..add(tag);
                  }
                }),
                controlAffinity: ListTileControlAffinity.leading,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CoreSpacing.space4,
        CoreSpacing.space3,
        CoreSpacing.space4,
        CoreSpacing.space4,
      ),
      child: Row(
        children: [
          Expanded(
            child: CoreButton(
              key: const Key('tags_filter_clear_all_button'),
              label: l10n.globalSearchTagsSheetClearAll,
              variant: CoreButtonVariant.secondary,
              onPressed: () => setState(() => _localSelected = {}),
            ),
          ),
          const SizedBox(width: CoreSpacing.space3),
          Expanded(
            child: CoreButton(
              key: const Key('tags_filter_apply_button'),
              label: l10n.globalSearchTagsSheetApply,
              onPressed: () => _onApply(context),
            ),
          ),
        ],
      ),
    );
  }
}
