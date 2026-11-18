import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/helpers/sample_rate_row.dart';
import 'package:construculator/features/estimation/presentation/helpers/unit_display_name.dart';
import 'package:construculator/features/estimation/presentation/helpers/your_rate_recency_label.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_header.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_search_field.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_surface.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:equatable/equatable.dart';
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
/// The matching sample cost file rates follow under FROM SAMPLE COST FILE,
/// with the "Not your own rates" notice that has no close control. When every
/// sample row states its coverage in one takeoff unit, each also shows its
/// price per that unit, with a footnote saying why; otherwise neither shows.
class MaterialRateLookupSheet extends StatefulWidget {
  /// The material name typed in the form, searched as the sheet opens.
  final String initialQuery;

  /// Dates the "Used …" and "Saved …" line under each saved rate.
  final Clock clock;

  /// The sample cost file rates matching a search.
  final List<SampleRateRow> Function(String query) sampleRatesFor;

  const MaterialRateLookupSheet({
    super.key,
    required this.initialQuery,
    required this.clock,
    required this.sampleRatesFor,
  });

  @override
  State<MaterialRateLookupSheet> createState() =>
      _MaterialRateLookupSheetState();

  /// Opens this sheet in a [CoreQuickSheet] and returns the picked rate, or
  /// null if the sheet was closed without one.
  static Future<MaterialLookupPick?> show({
    required BuildContext context,
    required String initialQuery,
    required Clock clock,
    required YourRatesBloc Function() blocFactory,
    required List<SampleRateRow> Function(String query) sampleRatesFor,
  }) {
    return CoreQuickSheet.show<MaterialLookupPick>(
      context: context,
      backgroundColor: sheetSurface(context),
      child: BlocProvider<YourRatesBloc>(
        create: (_) => blocFactory(),
        child: MaterialRateLookupSheet(
          initialQuery: initialQuery,
          clock: clock,
          sampleRatesFor: sampleRatesFor,
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
  List<SampleRateRow> _sampleRows = const [];
  MaterialLookupPick? _picked;

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

  void _search(String query) {
    _sampleRows = widget.sampleRatesFor(query);
    context.read<YourRatesBloc>().add(
      YourRatesSearched(query, category: CostItemType.material),
    );
  }

  void _onRowTap(MaterialLookupPick pick) =>
      setState(() => _picked = _picked == pick ? null : pick);

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
        final picks = [
          for (final entry in entries) MaterialLookupYourRate(entry),
          for (final row in _sampleRows) MaterialLookupSampleRate(row),
        ];
        final selected = picks.contains(_picked) ? _picked : null;
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
                          onChanged: (query) => setState(() => _search(query)),
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
                        else if (picks.isEmpty &&
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
                            unit: _unitSuffix(context, entry.unit),
                            selected: selected == MaterialLookupYourRate(entry),
                            onTap: () =>
                                _onRowTap(MaterialLookupYourRate(entry)),
                          ),
                        if (_sampleRows.isNotEmpty)
                          _SampleGroup(
                            rows: _sampleRows,
                            selected: selected,
                            unitSuffix: (unit) => _unitSuffix(context, unit),
                            onTap: _onRowTap,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (picks.isNotEmpty) ...[
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
                                _unitSuffix(context, selected.unit) ?? '',
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

  String? _unitSuffix(BuildContext context, Unit? unit) => switch (unit) {
    final unit? => context.l10n.materialRatePerUnitSuffix(
      unit.displayName(context.l10n),
    ),
    null => null,
  };
}

class _SampleGroup extends StatelessWidget {
  final List<SampleRateRow> rows;
  final MaterialLookupPick? selected;
  final String? Function(Unit? unit) unitSuffix;
  final ValueChanged<MaterialLookupPick> onTap;

  const _SampleGroup({
    required this.rows,
    required this.selected,
    required this.unitSuffix,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    final columnUnit = SampleRateRow.sharedCoverageUnit(rows);
    return Column(
      key: const Key('material_lookup_sample_group'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CoreSpacing.space2,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: CoreSpacing.space4),
          child: Text(
            l10n.materialLookupSampleHeading.toUpperCase(),
            style: textTheme.bodySmallSemiBold.copyWith(
              color: colorTheme.textBody,
            ),
          ),
        ),
        // TODO: [CA-1510] use CoreUI's inline notice once it exists. https://ripplearc.youtrack.cloud/issue/CA-1510
        Container(
          key: const Key('material_lookup_sample_notice'),
          padding: const EdgeInsets.all(CoreSpacing.space4),
          decoration: BoxDecoration(
            color: colorTheme.backgroundOrangeLight,
            border: Border.all(color: colorTheme.lineOrange),
            borderRadius: BorderRadius.circular(CoreSpacing.space3),
          ),
          child: Text(
            l10n.materialLookupSampleNotice,
            style: textTheme.bodyMediumRegular.copyWith(
              color: colorTheme.textHeadline,
            ),
          ),
        ),
        if (columnUnit != null)
          Row(
            key: const Key('material_lookup_price_per_unit_footnote'),
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: CoreSpacing.space1,
            children: [
              CoreIconWidget(
                icon: CoreIcons.info,
                size: CoreIconSize.size16,
                color: colorTheme.iconGrayMid,
              ),
              Expanded(
                child: Text(
                  l10n.materialLookupPricePerUnitFootnote(
                    columnUnit.displayName(l10n),
                  ),
                  style: textTheme.bodySmallRegular.copyWith(
                    color: colorTheme.textBody,
                  ),
                ),
              ),
            ],
          ),
        for (final row in rows)
          CoreListRow.selectable(
            key: Key('sample_rate_row_${row.id}'),
            title: row.productName,
            // TODO: [CA-1157] show the price per unit as a second line under the price once CoreListRow has one. https://ripplearc.youtrack.cloud/issue/CA-1157
            subtitle: [
              ?row.details,
              if (columnUnit != null)
                l10n.materialLookupPricePerUnit(
                  DisplayFormatter.currency.format(row.pricePerCoverageUnit),
                  unitSuffix(columnUnit) ?? '',
                ),
            ].join(' · '),
            value: DisplayFormatter.currency.format(row.rate.amount),
            unit: unitSuffix(row.unit),
            selected: selected == MaterialLookupSampleRate(row),
            onTap: () => onTap(MaterialLookupSampleRate(row)),
          ),
      ],
    );
  }
}

/// What was picked on [MaterialRateLookupSheet].
sealed class MaterialLookupPick extends Equatable {
  const MaterialLookupPick();

  /// The price of one unit.
  Money get rate;

  /// The unit [rate] is the price of.
  Unit? get unit;
}

/// A rate from YOUR RATES: it arrives as the user's own, with no tag.
final class MaterialLookupYourRate extends MaterialLookupPick {
  const MaterialLookupYourRate(this.entry);

  /// The saved rate.
  final YourRateEntry entry;

  @override
  Money get rate => entry.rate;

  @override
  Unit? get unit => entry.unit;

  @override
  List<Object?> get props => [entry.id];
}

/// A rate from FROM SAMPLE COST FILE: it arrives tagged Sample rate.
final class MaterialLookupSampleRate extends MaterialLookupPick {
  const MaterialLookupSampleRate(this.row);

  /// The sample cost file rate.
  final SampleRateRow row;

  @override
  Money get rate => row.rate;

  @override
  Unit? get unit => row.unit;

  @override
  List<Object?> get props => [row.id];
}
