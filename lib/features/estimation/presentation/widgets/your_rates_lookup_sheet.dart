import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_header.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_surface.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// "Look up a rate" sheet (Figma node `66342:169078`, "D3 ·
/// cuj6-equip-3job-lookup" on the "Estimate V2" canvas): search across the
/// contractor's own saved equipment rates, filtered to [method] so a
/// per-day rate can never land in an Amount field and vice versa.
///
/// Opens with every saved rate for the category, newest first, so a rate is
/// never hidden by a row cap before the pricing method filter runs.
///
/// Selecting a result is a two-step flow, per the Figma spec: tapping a row
/// only selects it (leading check + highlighted fill); confirming — via the
/// "Use $X" button that appears once a selected row is on screen — is what
/// pops the sheet. Tapping the already-selected row again deselects it. A
/// search that leaves the selected row off screen hides the button, so it can
/// never apply a row the user cannot see.
///
/// When the phone cannot read Your rates, the sheet shows an error row with a
/// "Try again" button, and never says there are no saved rates (storyboard
/// CUJ 6, frame "Look-up, saved prices not read").
///
/// TODO: [CA-1157](https://ripplearc.youtrack.cloud/issue/CA-1157) Search the sample cost file here once a real data source exists, with the YOUR RATES and FROM SAMPLE COST FILE headings and the "Not your own rates" notice under the sample group.
///
/// Returns the picked [YourRateEntry] via `Navigator.pop`, or null if
/// dismissed without confirming a selection.
class YourRatesLookupSheet extends StatefulWidget {
  /// Restricts results to this pricing method — see the class doc comment.
  final EquipmentPricingMethod method;

  const YourRatesLookupSheet({super.key, required this.method});

  @override
  State<YourRatesLookupSheet> createState() => _YourRatesLookupSheetState();

  /// Opens this sheet in a [CoreQuickSheet] and returns the confirmed
  /// [YourRateEntry], or null if the sheet was dismissed without one.
  static Future<YourRateEntry?> show({
    required BuildContext context,
    required EquipmentPricingMethod method,
    required YourRatesBloc Function() blocFactory,
  }) {
    return CoreQuickSheet.show<YourRateEntry>(
      context: context,
      backgroundColor: sheetSurface(context),
      child: BlocProvider<YourRatesBloc>(
        create: (_) => blocFactory(),
        child: YourRatesLookupSheet(method: method),
      ),
    );
  }
}

String _unitSuffix(BuildContext context, EquipmentPricingMethod method) =>
    method == EquipmentPricingMethod.day
    ? context.l10n.yourRatesDaySuffix
    : context.l10n.yourRatesJobSuffix;

class _YourRatesLookupSheetState extends State<YourRatesLookupSheet> {
  final _searchController = TextEditingController();
  YourRateEntry? _selectedEntry;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String query) {
    context.read<YourRatesBloc>().add(
      YourRatesSearched(query, category: CostItemType.equipment),
    );
  }

  void _onRowTap(YourRateEntry entry) {
    setState(() {
      _selectedEntry = _selectedEntry?.id == entry.id ? null : entry;
    });
  }

  void _onConfirm(YourRateEntry entry) => Navigator.of(context).pop(entry);

  // TODO: [CA-1205](https://ripplearc.youtrack.cloud/issue/CA-1205) A search that comes up empty for the active method gives no hint that a match exists under the other method, even though the unfiltered results this method receives already have it.
  List<YourRateEntry> _entriesOf(YourRatesState state) {
    final entries = switch (state) {
      YourRatesLoaded(:final recents) => recents,
      YourRatesSearchResults(:final results) => results,
      _ => const <YourRateEntry>[],
    };
    return entries.where((e) => e.equipmentMethod == widget.method).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<YourRatesBloc, YourRatesState>(
      builder: (context, state) {
        final entries = _entriesOf(state);
        final selected = entries
            .where((entry) => entry.id == _selectedEntry?.id)
            .firstOrNull;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHeader(title: l10n.yourRatesLookupTitle),
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      CoreSpacing.space4,
                      0,
                      CoreSpacing.space4,
                      CoreSpacing.space4,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SearchField(
                          controller: _searchController,
                          onChanged: _search,
                        ),
                        const SizedBox(height: CoreSpacing.space4),
                        _results(context, state, entries, selected),
                      ],
                    ),
                  ),
                ),
              ),
              if (selected != null) ...[
                const CoreDivider(),
                Padding(
                  padding: const EdgeInsets.all(CoreSpacing.space4),
                  child: CoreButton(
                    key: const Key('your_rates_use_button'),
                    label: l10n.yourRatesUseButtonLabel(
                      DisplayFormatter.currency.format(selected.rate.amount),
                      _unitSuffix(context, widget.method),
                    ),
                    size: CoreButtonSize.medium,
                    onPressed: () => _onConfirm(selected),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _results(
    BuildContext context,
    YourRatesState state,
    List<YourRateEntry> entries,
    YourRateEntry? selected,
  ) {
    final l10n = context.l10n;
    if (state is YourRatesLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: CoreSpacing.space6),
        child: CoreLoadingIndicator(),
      );
    }
    if (state is YourRatesError) {
      return _LoadErrorRow(onTryAgain: () => _search(_searchController.text));
    }
    if (entries.isEmpty) {
      final query = _searchController.text;
      return Padding(
        key: const Key('your_rates_empty_state'),
        padding: const EdgeInsets.symmetric(vertical: CoreSpacing.space6),
        child: Text(
          query.isEmpty
              ? l10n.yourRatesEmptyState
              : l10n.yourRatesNoMatchState(query),
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMediumRegular.copyWith(
            color: context.colorTheme.textBody,
          ),
        ),
      );
    }
    return ListView.separated(
      key: const Key('your_rates_results_list'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: CoreSpacing.space3),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _YourRateRow(
          key: Key('your_rate_row_${entry.id}'),
          entry: entry,
          method: widget.method,
          selected: entry.id == selected?.id,
          onTap: () => _onRowTap(entry),
        );
      },
    );
  }
}

/// Figma node 66342:169083 ("Search Bar", `Property 1=Sheet filled`):
/// white fill, 1px `#d0d5dd` (`colorTheme.lineMid`) stroke, 12px corner
/// radius. [CoreSearchBox] gets the icon behavior right but is borderless
/// everywhere else it is used, so this wraps it in the bordered box.
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final theme = Theme.of(context);
    return Container(
      key: const Key('your_rates_search_field'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: colorTheme.lineMid),
        borderRadius: BorderRadius.circular(CoreSpacing.space3),
      ),
      child: Theme(
        data: theme.copyWith(
          extensions: [
            for (final extension in theme.extensions.values)
              if (extension is AppColorsExtension)
                extension.copyWith(pageBackground: sheetSurface(context))
              else
                extension,
          ],
        ),
        child: CoreSearchBox(
          hintText: context.l10n.yourRatesSearchHint,
          controller: controller,
          onChanged: onChanged,
          clearSemanticLabel: context.l10n.yourRatesClearSearchSemanticLabel,
        ),
      ),
    );
  }
}

// TODO: [CA-1249](https://ripplearc.youtrack.cloud/issue/CA-1249) Replace with CoreUI's error row once it exists.
class _LoadErrorRow extends StatelessWidget {
  final VoidCallback onTryAgain;

  const _LoadErrorRow({required this.onTryAgain});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    return Row(
      key: const Key('your_rates_load_error'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CoreIconWidget(
          icon: CoreIcons.error,
          size: 16,
          color: colorTheme.iconRed,
        ),
        const SizedBox(width: CoreSpacing.space1),
        Expanded(
          child: Text(
            l10n.yourRatesLoadError,
            style: textTheme.bodySmallRegular.copyWith(
              color: colorTheme.textError,
            ),
          ),
        ),
        Semantics(
          button: true,
          label: l10n.yourRatesTryAgain,
          excludeSemantics: true,
          child: GestureDetector(
            key: const Key('your_rates_try_again_button'),
            behavior: HitTestBehavior.opaque,
            onTap: onTryAgain,
            child: Container(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              alignment: Alignment.center,
              child: Text(
                l10n.yourRatesTryAgain,
                style: textTheme.bodyMediumSemiBold.copyWith(
                  color: colorTheme.textLink,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// TODO: [CA-1204](https://ripplearc.youtrack.cloud/issue/CA-1204) Replace with CoreUI's list-row component once it exists.
class _YourRateRow extends StatelessWidget {
  final YourRateEntry entry;
  final EquipmentPricingMethod method;
  final bool selected;
  final VoidCallback onTap;

  const _YourRateRow({
    super.key,
    required this.entry,
    required this.method,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    final nameColor = selected ? colorTheme.textLink : colorTheme.textHeadline;
    final priceLabel =
        '${DisplayFormatter.currency.format(entry.rate.amount)} '
        '${_unitSuffix(context, method)}';
    return Semantics(
      button: true,
      selected: selected,
      label: '${entry.itemName}. $priceLabel',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CoreSpacing.space3),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: CoreSpacing.space2,
            vertical: CoreSpacing.space3,
          ),
          decoration: BoxDecoration(
            color: selected ? colorTheme.backgroundBlueLight : null,
            borderRadius: BorderRadius.circular(CoreSpacing.space3),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Opacity(
                  opacity: selected ? 1 : 0,
                  child: CoreIconWidget(
                    icon: CoreIcons.checkMark,
                    color: colorTheme.textLink,
                    size: CoreSpacing.space5,
                  ),
                ),
              ),
              const SizedBox(width: CoreSpacing.space3),
              Expanded(
                child: Text(
                  entry.itemName,
                  style: textTheme.bodyLargeSemiBold.copyWith(color: nameColor),
                ),
              ),
              const SizedBox(width: CoreSpacing.space3),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: DisplayFormatter.currency.format(entry.rate.amount),
                      style: textTheme.bodyLargeSemiBold.copyWith(
                        color: colorTheme.textHeadline,
                      ),
                    ),
                    TextSpan(
                      text: ' ${_unitSuffix(context, method)}',
                      style: textTheme.bodySmallRegular.copyWith(
                        color: colorTheme.textBody,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
