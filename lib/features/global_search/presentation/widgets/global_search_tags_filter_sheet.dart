import 'package:construculator/features/global_search/presentation/bloc/global_search_bloc/global_search_bloc.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

// Representative tag list shown until a dedicated tags data source is wired.
// TODO: [CA-638] Replace with tags fetched from repository once the data source exists.
const List<String> _kDefaultTags = [
  'Roofing',
  'Carpeting',
  'Flooring',
  'Wall',
  'Bed room wall',
  'Plumbing',
  'Electrical',
  'Painting',
];

/// A modal bottom sheet for selecting tag filters in the global search screen.
///
/// Maintains a local copy of the selected tags until the user taps Apply,
/// at which point it dispatches [GlobalSearchTagFiltersApplied] and pops itself.
/// Tapping Clear all deselects all tags without dismissing the sheet.
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
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _localSelected = Set.of(widget.initialSelectedTags);
  }

  List<String> get _filteredTags {
    if (_searchQuery.isEmpty) return _kDefaultTags;
    final lower = _searchQuery.toLowerCase();
    return _kDefaultTags
        .where((t) => t.toLowerCase().contains(lower))
        .toList();
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
        _buildSearchField(l10n),
        _buildTagList(typography),
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

  Widget _buildSearchField(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CoreSpacing.space4,
        vertical: CoreSpacing.space2,
      ),
      child: CoreTextField(
        hintText: l10n.globalSearchTagsSheetSearchHint,
        onChanged: (value) => setState(() => _searchQuery = value),
        prefix: const CoreIconWidget(
          icon: CoreIcons.search,
          size: CoreSpacing.space5,
        ),
      ),
    );
  }

  Widget _buildTagList(AppTypographyExtension typography) {
    final tags = _filteredTags;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: tags.length,
        itemBuilder: (_, index) {
          final tag = tags[index];
          final isSelected = _localSelected.contains(tag);
          return CheckboxListTile(
            key: Key('tag_filter_item_$tag'),
            value: isSelected,
            title: Text(tag, style: typography.bodyLargeRegular),
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
