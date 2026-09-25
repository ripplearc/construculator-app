import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// "Look up a rate" sheet (Figma Screen 4): search across the contractor's
/// own saved equipment rates, filtered to [method] so a per-day rate can
/// never land in an Amount field and vice versa — [YourRateEntry.category]
/// is filtered by [YourRatesSearched.category] server-side, but
/// [YourRateEntry.equipmentMethod] has no bloc-level filter, so this sheet
/// filters that locally.
///
/// Doubles as the "Your recents" screen (Figma Screen 2): opened with an
/// empty query, [YourRatesBloc] returns the most-recently-saved entries via
/// [YourRatesRefreshRecents] — same list, same row widget, no separate
/// screen needed for a search-vs-recents distinction that isn't visually
/// different.
///
/// TODO: CA-1157 — also search the sample cost file here once a real data
/// source exists; this sheet only searches "Your rates" for now.
///
/// Returns the picked [YourRateEntry] via `Navigator.pop`, or null if
/// dismissed without a selection.
class YourRatesLookupSheet extends StatefulWidget {
  final EquipmentPricingMethod method;

  const YourRatesLookupSheet({super.key, required this.method});

  @override
  State<YourRatesLookupSheet> createState() => _YourRatesLookupSheetState();

  static Future<YourRateEntry?> show({
    required BuildContext context,
    required EquipmentPricingMethod method,
    required YourRatesBloc Function() blocFactory,
  }) {
    return CoreQuickSheet.show<YourRateEntry>(
      context: context,
      child: BlocProvider<YourRatesBloc>(
        create: (_) => blocFactory(),
        child: YourRatesLookupSheet(method: method),
      ),
    );
  }
}

class _YourRatesLookupSheetState extends State<YourRatesLookupSheet> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<YourRatesBloc>().add(
      const YourRatesRefreshRecents(CostItemType.equipment),
    );
    _searchController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    context.read<YourRatesBloc>().add(
      YourRatesSearched(
        _searchController.text,
        category: CostItemType.equipment,
      ),
    );
  }

  List<YourRateEntry> _entriesOf(YourRatesState state) {
    final entries = switch (state) {
      YourRatesLoaded(:final recents) => recents,
      YourRatesSearchResults(:final results) => results,
      YourRatesLoading() ||
      YourRatesError() ||
      YourRatesSaveSucceeded() ||
      YourRatesSaveCollision() ||
      YourRatesSaveFailed() => const <YourRateEntry>[],
    };
    return entries.where((e) => e.equipmentMethod == widget.method).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    return Padding(
      padding: const EdgeInsets.all(CoreSpacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.yourRatesLookupTitle,
            style: context.textTheme.titleMediumSemiBold.copyWith(
              color: colorTheme.textHeadline,
            ),
          ),
          const SizedBox(height: CoreSpacing.space4),
          CoreTextField(
            key: const Key('your_rates_search_field'),
            hintText: l10n.yourRatesSearchHint,
            controller: _searchController,
            suffix: CoreIconWidget(
              icon: CoreIcons.search,
              color: colorTheme.iconGrayMid,
              size: 20,
            ),
          ),
          const SizedBox(height: CoreSpacing.space4),
          BlocBuilder<YourRatesBloc, YourRatesState>(
            builder: (context, state) {
              if (state is YourRatesLoading) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: CoreSpacing.space6),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final entries = _entriesOf(state);
              if (entries.isEmpty) {
                return Padding(
                  key: const Key('your_rates_empty_state'),
                  padding: const EdgeInsets.symmetric(
                    vertical: CoreSpacing.space6,
                  ),
                  child: Text(
                    l10n.yourRatesEmptyState,
                    style: context.textTheme.bodyMediumRegular.copyWith(
                      color: colorTheme.textBody,
                    ),
                  ),
                );
              }
              return ListView.separated(
                key: const Key('your_rates_results_list'),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: CoreSpacing.space3),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return _YourRateRow(
                    key: Key('your_rate_row_${entry.id}'),
                    entry: entry,
                    onTap: () => Navigator.of(context).pop(entry),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _YourRateRow extends StatelessWidget {
  final YourRateEntry entry;
  final VoidCallback onTap;

  const _YourRateRow({super.key, required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    final isDay = entry.equipmentMethod == EquipmentPricingMethod.day;
    return Semantics(
      button: true,
      label: entry.itemName,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CoreSpacing.space2),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: CoreSpacing.space3,
            vertical: CoreSpacing.space3,
          ),
          decoration: BoxDecoration(
            color: colorTheme.backgroundGrayLight,
            borderRadius: BorderRadius.circular(CoreSpacing.space2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  entry.itemName,
                  style: textTheme.bodyMediumSemiBold.copyWith(
                    color: colorTheme.textHeadline,
                  ),
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: DisplayFormatter.currency.format(entry.rate.amount),
                      style: textTheme.bodyMediumSemiBold.copyWith(
                        color: colorTheme.textHeadline,
                      ),
                    ),
                    TextSpan(
                      text: isDay
                          ? ' ${l10n.yourRatesDaySuffix}'
                          : ' ${l10n.yourRatesJobSuffix}',
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
