import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/helpers/unit_display_name.dart';
import 'package:construculator/features/estimation/presentation/helpers/your_rate_recency_label.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_header.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_search_field.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// "Look up a rate" sheet for a material (storyboard CUJ 4, sub-flow A,
/// screen 4). Opens searched on [initialQuery] and lists the matching Your
/// rates under YOUR RATES, each priced per its unit.
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
}

class _MaterialRateLookupSheetState extends State<MaterialRateLookupSheet> {
  late final _searchController = TextEditingController(
    text: widget.initialQuery,
  );

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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<YourRatesBloc, YourRatesState>(
      builder: (context, state) {
        final entries = switch (state) {
          YourRatesSearchResults(:final results) => results,
          _ => const <YourRateEntry>[],
        };
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
                        const SizedBox(height: CoreSpacing.space4),
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
                          CoreListRow(
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
                          ),
                      ],
                    ),
                  ),
                ),
              ),
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
