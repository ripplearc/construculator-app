import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// "Your recents" sheet (Figma node `66342:177929`, "phone ·
/// cuj6-equip-1-recents" on the "Estimate V2" canvas): the pre-form step
/// opened by "+ Add equipment cost" — a tap-to-reuse list of the
/// contractor's most recently saved equipment rates. Day- and job-priced
/// rows share one list with no heading or color split between them; only
/// the trailing "/day" vs "job" word differs. A trailing "+ New equipment
/// cost" row opens the form blank instead.
///
/// Distinct from [YourRatesLookupSheet] (Figma Screen 4, reached later from
/// inside the open form's magnifier icon): this sheet has no search box, no
/// disclaimer, no checkbox-select-then-confirm step, and isn't filtered to a
/// single pricing method — tapping a row recalls it immediately.
///
/// TODO: CA-1151 — Figma's recents screen also shows a "Search or type
/// equipment" name-entry field above this list, for typing a brand-new
/// equipment name directly (a different concern from [YourRatesLookupSheet]'s
/// saved-rate search). Left out of this pass: the follow-up-PR scope agreed
/// on this ticket only covers the recents list and the "+ New equipment
/// cost" row, and this field's behavior — filtering these recents vs.
/// feeding the form's name field directly — isn't specified anywhere yet.
///
/// Returns the tapped [YourRateEntry], or null if dismissed or if "+ New
/// equipment cost" was tapped — both mean "open the form blank."
class YourRatesRecentsSheet extends StatefulWidget {
  /// Supplies "now" for each row's recency subtitle — see [Clock]'s own doc
  /// comment for why this is injected rather than calling [DateTime.now]
  /// directly.
  final Clock clock;

  const YourRatesRecentsSheet({super.key, required this.clock});

  @override
  State<YourRatesRecentsSheet> createState() => _YourRatesRecentsSheetState();

  /// Opens this sheet in a [CoreQuickSheet] and returns the tapped
  /// [YourRateEntry], or null if the sheet was dismissed, or "+ New
  /// equipment cost" was tapped, without picking one.
  static Future<YourRateEntry?> show({
    required BuildContext context,
    required Clock clock,
    required YourRatesBloc Function() blocFactory,
  }) {
    return CoreQuickSheet.show<YourRateEntry>(
      context: context,
      child: BlocProvider<YourRatesBloc>(
        create: (_) => blocFactory(),
        child: YourRatesRecentsSheet(clock: clock),
      ),
    );
  }
}

class _YourRatesRecentsSheetState extends State<YourRatesRecentsSheet> {
  @override
  void initState() {
    super.initState();
    context.read<YourRatesBloc>().add(
      const YourRatesRefreshRecents(CostItemType.equipment),
    );
  }

  void _onRowTap(YourRateEntry entry) => Navigator.of(context).pop(entry);

  void _onNewEquipmentCost() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    final now = widget.clock.now();
    return Padding(
      padding: const EdgeInsets.all(CoreSpacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.yourRatesRecentsTitle,
            style: context.textTheme.titleMediumSemiBold.copyWith(
              color: colorTheme.textHeadline,
            ),
          ),
          const SizedBox(height: CoreSpacing.space4),
          BlocBuilder<YourRatesBloc, YourRatesState>(
            builder: (context, state) {
              if (state is YourRatesLoading) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: CoreSpacing.space6),
                  child: CoreLoadingIndicator(),
                );
              }
              final entries = switch (state) {
                YourRatesLoaded(:final recents) => recents,
                _ => const <YourRateEntry>[],
              };
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (entries.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: CoreSpacing.space2,
                      ),
                      child: Text(
                        l10n.yourRatesRecentsSectionHeading.toUpperCase(),
                        style: context.textTheme.bodySmallSemiBold.copyWith(
                          color: colorTheme.textBody,
                        ),
                      ),
                    ),
                    ListView.separated(
                      key: const Key('your_rates_recents_list'),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: CoreSpacing.space2),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return _RecentRateRow(
                          key: Key('your_rate_row_${entry.id}'),
                          entry: entry,
                          now: now,
                          onTap: () => _onRowTap(entry),
                        );
                      },
                    ),
                    const SizedBox(height: CoreSpacing.space2),
                  ],
                  _NewEquipmentCostRow(onTap: _onNewEquipmentCost),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// The unit suffix shown after a row's rate amount; a per-entry equivalent
/// of `your_rates_lookup_sheet.dart`'s own `_unitSuffix`, needed here
/// because recents rows — unlike that sheet's rows — aren't all the same
/// pricing method.
String _unitSuffixFor(BuildContext context, EquipmentPricingMethod? method) =>
    method == EquipmentPricingMethod.job
    ? context.l10n.yourRatesJobSuffix
    : context.l10n.yourRatesDaySuffix;

// TODO: CA-1204 — replace with CoreUI's list-row component once it exists.
class _RecentRateRow extends StatelessWidget {
  final YourRateEntry entry;
  final DateTime now;
  final VoidCallback onTap;

  const _RecentRateRow({
    super.key,
    required this.entry,
    required this.now,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    final recency = DisplayFormatter.formatRecency(entry.savedAt, now: now);
    final unitSuffix = _unitSuffixFor(context, entry.equipmentMethod);
    final priceLabel =
        '${DisplayFormatter.currency.format(entry.rate.amount)} $unitSuffix';
    return Semantics(
      button: true,
      label: '${entry.itemName}. $recency. $priceLabel',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CoreSpacing.space3),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CoreSpacing.space2,
            vertical: CoreSpacing.space3,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.itemName,
                      style: textTheme.bodyLargeSemiBold.copyWith(
                        color: colorTheme.textHeadline,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      recency,
                      style: textTheme.bodySmallRegular.copyWith(
                        color: colorTheme.textBody,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: CoreSpacing.space3),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: DisplayFormatter.currency.format(
                        entry.rate.amount,
                      ),
                      style: textTheme.bodyLargeSemiBold.copyWith(
                        color: colorTheme.textHeadline,
                      ),
                    ),
                    TextSpan(
                      text: ' $unitSuffix',
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

// TODO: CA-1204 — replace with CoreUI's list-row component once it exists.
class _NewEquipmentCostRow extends StatelessWidget {
  final VoidCallback onTap;

  const _NewEquipmentCostRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final label = context.l10n.yourRatesNewEquipmentCostAction;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        key: const Key('new_equipment_cost_row'),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: CoreSpacing.space12),
          padding: const EdgeInsets.symmetric(
            vertical: CoreSpacing.space3,
            horizontal: CoreSpacing.space2,
          ),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colorTheme.lineLight)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CoreIconWidget(
                icon: CoreIcons.add,
                color: colorTheme.textLink,
                size: CoreSpacing.space4,
              ),
              const SizedBox(width: CoreSpacing.space2),
              Text(
                label,
                style: context.textTheme.bodyMediumSemiBold.copyWith(
                  color: colorTheme.textLink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
