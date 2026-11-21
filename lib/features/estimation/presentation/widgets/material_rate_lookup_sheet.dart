import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/helpers/unit_display_name.dart';
import 'package:construculator/features/estimation/presentation/helpers/your_rate_recency_label.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_header.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_search_field.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_surface.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// "Look up a rate" sheet for a material (storyboard CUJ 4, sub-flow A,
/// screen 4). Opens searched on [initialQuery] and lists the matching Your
/// rates under YOUR RATES; the previous rows stay on screen while a search
/// runs. Tapping a row only selects it; the button at the foot stays greyed
/// out as "Use rate" until a row is picked, then returns that rate. A search
/// with no match shows one "No matches" line and no button: there is no way
/// to create an entry here.
///
/// TODO: [CA-1157](https://ripplearc.youtrack.cloud/issue/CA-1157) Search the sample cost file here too, under a FROM SAMPLE COST FILE heading below YOUR RATES, once a real data source exists.
class MaterialRateLookupSheet extends StatefulWidget {
  /// The material name typed in the form, searched as the sheet opens.
  final String initialQuery;

  /// Dates the "Used …" and "Saved …" line under each saved rate.
  final Clock clock;

  const MaterialRateLookupSheet({
    super.key,
    required this.initialQuery,
    required this.clock,
  });

  @override
  State<MaterialRateLookupSheet> createState() =>
      _MaterialRateLookupSheetState();

  /// Opens this sheet in a [CoreQuickSheet] and returns the picked
  /// [YourRateEntry], or null if the sheet was closed without one.
  static Future<YourRateEntry?> show({
    required BuildContext context,
    required String initialQuery,
    required Clock clock,
    required YourRatesBloc Function() blocFactory,
  }) {
    return CoreQuickSheet.show<YourRateEntry>(
      context: context,
      backgroundColor: sheetSurface(context),
      child: BlocProvider<YourRatesBloc>(
        create: (_) => blocFactory(),
        child: MaterialRateLookupSheet(
          initialQuery: initialQuery,
          clock: clock,
        ),
      ),
    );
  }
}

class _MaterialRateLookupSheetState extends State<MaterialRateLookupSheet> {
  late final _searchController = TextEditingController(
    text: widget.initialQuery,
  );

  List<YourRateEntry> _shownEntries = const [];
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _search(widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String query) => context.read<YourRatesBloc>().add(
    YourRatesSearched(query, category: CostItemType.material),
  );

  void _onRowTap(YourRateEntry entry) =>
      setState(() => _selectedId = _selectedId == entry.id ? null : entry.id);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<YourRatesBloc, YourRatesState>(
      builder: (context, state) {
        final entries = switch (state) {
          YourRatesSearchResults(:final results) => results,
          YourRatesError() => const <YourRateEntry>[],
          _ => _shownEntries,
        };
        _shownEntries = entries;
        final selected = entries
            .where((entry) => entry.id == _selectedId)
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
                        SheetSearchField(
                          controller: _searchController,
                          hintText: l10n.yourRatesMaterialSearchHint,
                          onChanged: _search,
                        ),
                        // TODO: [CA-1482] show CoreUI's progress bar here while a search runs, above the rows kept from the last search. https://ripplearc.youtrack.cloud/issue/CA-1482
                        const SizedBox(height: CoreSpacing.space4),
                        if (state is YourRatesError)
                          CoreInlineErrorRow(
                            key: const Key('your_rates_load_error'),
                            message: l10n.yourRatesLoadError,
                            actionLabel: l10n.yourRatesTryAgain,
                            actionKey: const Key('your_rates_try_again_button'),
                            onAction: () => _search(_searchController.text),
                          )
                        else if (entries.isEmpty &&
                            state is YourRatesSearchResults)
                          Padding(
                            key: const Key('material_lookup_no_match'),
                            padding: const EdgeInsets.symmetric(
                              vertical: CoreSpacing.space6,
                            ),
                            child: Text(
                              l10n.yourRatesNoMatchState(state.query),
                              textAlign: TextAlign.center,
                              style: context.textTheme.bodyMediumRegular
                                  .copyWith(color: context.colorTheme.textBody),
                            ),
                          ),
                        if (entries.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: CoreSpacing.space2,
                            ),
                            child: Text(
                              l10n.yourRatesName.toUpperCase(),
                              style: context.textTheme.bodySmallSemiBold
                                  .copyWith(color: context.colorTheme.textBody),
                            ),
                          ),
                        for (final entry in entries)
                          CoreListRow.selectable(
                            key: Key('your_rate_row_${entry.id}'),
                            title: entry.itemName,
                            subtitle: entry.recencyLabel(
                              l10n,
                              now: widget.clock.now(),
                            ),
                            value: DisplayFormatter.currency.format(
                              entry.rate.amount,
                            ),
                            unit: _unitSuffix(context, entry),
                            selected: entry.id == selected?.id,
                            onTap: () => _onRowTap(entry),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (entries.isNotEmpty) ...[
                const CoreDivider(),
                Padding(
                  padding: const EdgeInsets.all(CoreSpacing.space4),
                  child: CoreButton(
                    key: const Key('material_lookup_use_button'),
                    label: selected == null
                        ? l10n.materialLookupUseRateButton
                        : l10n
                              .yourRatesUseButtonLabel(
                                DisplayFormatter.currency.format(
                                  selected.rate.amount,
                                ),
                                _unitSuffix(context, selected) ?? '',
                              )
                              .trim(),
                    isDisabled: selected == null,
                    onPressed: () => Navigator.of(context).pop(selected),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String? _unitSuffix(BuildContext context, YourRateEntry entry) =>
      switch (entry.unit) {
        final unit? => context.l10n.materialRatePerUnitSuffix(
          unit.displayName(context.l10n),
        ),
        null => null,
      };
}
