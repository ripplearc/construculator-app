import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// "Look up a rate" sheet (Figma node `66342:169078`, "D3 ·
/// cuj6-equip-3job-lookup" on the "Estimate V2" canvas): search across the
/// contractor's own saved equipment rates, filtered to [method] so a
/// per-day rate can never land in an Amount field and vice versa —
/// [YourRateEntry.category] is filtered by [YourRatesSearched.category]
/// server-side, but [YourRateEntry.equipmentMethod] has no bloc-level
/// filter, so this sheet filters that locally.
///
/// Doubles as the "Your recents" screen (Figma Screen 2): opened with an
/// empty query, [YourRatesBloc] returns the most-recently-saved entries via
/// [YourRatesRefreshRecents] — same list, same row widget, no separate
/// screen needed for a search-vs-recents distinction that isn't visually
/// different.
///
/// Selecting a result is a two-step flow, per the Figma spec: tapping a row
/// only selects it (leading check + highlighted fill); confirming — via the
/// "Use $X" button that appears once something is selected — is what pops
/// the sheet. Tapping the already-selected row again deselects it.
///
/// TODO: CA-1157 — also search the sample cost file here once a real data
/// source exists; this sheet only searches "Your rates" for now. The Figma
/// mock's "From sample cost file" group heading (above its example rows)
/// belongs to that same follow-up — grouping results by source only makes
/// sense once there's more than one source.
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
      child: BlocProvider<YourRatesBloc>(
        create: (_) => blocFactory(),
        child: YourRatesLookupSheet(method: method),
      ),
    );
  }
}

/// The unit suffix shown after a rate amount, matching Figma's "job"/"/day"
/// result-row and confirm-button labels. Shared by [_YourRateRow] and the
/// confirm button so both read the exact same string for a given entry.
String _unitSuffix(BuildContext context, EquipmentPricingMethod method) =>
    method == EquipmentPricingMethod.day
    ? context.l10n.yourRatesDaySuffix
    : context.l10n.yourRatesJobSuffix;

class _YourRatesLookupSheetState extends State<YourRatesLookupSheet> {
  final _searchController = TextEditingController();

  /// The currently checked row, if any. Purely local UI state: nothing is
  /// dispatched to [YourRatesBloc] until the confirm button is tapped, which
  /// pops this entry straight to the caller.
  YourRateEntry? _selectedEntry;

  @override
  void initState() {
    super.initState();
    context.read<YourRatesBloc>().add(
      const YourRatesRefreshRecents(CostItemType.equipment),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Wired to [CoreSearchBox.onChanged], which — unlike a raw
  // `TextEditingController` listener — only fires when the text itself
  // changes, not on every cursor/selection change (e.g. a bare tap into an
  // already-empty field). A controller listener would re-fire
  // `YourRatesSearched('')` on that tap, replacing "Your recents" with every
  // saved rate for no typing at all.
  void _onQueryChanged(String query) {
    context.read<YourRatesBloc>().add(
      YourRatesSearched(query, category: CostItemType.equipment),
    );
  }

  void _onRowTap(YourRateEntry entry) {
    setState(() {
      _selectedEntry = _selectedEntry?.id == entry.id ? null : entry;
    });
  }

  void _onConfirm() {
    final entry = _selectedEntry;
    if (entry == null) return;
    Navigator.of(context).pop(entry);
  }

  // KNOWN GAP (reported, not fixed by this pass): [YourRatesLoaded] caps
  // recents at the bloc's own limit *before* this method's method filter
  // runs. If every one of those newest rows happens to be the other
  // pricing method, a contractor with plenty of saved rates for this
  // method still sees the empty state here. Fixing it means either
  // over-fetching recents so filtering still leaves enough rows, or moving
  // the method filter into the bloc/repository query itself.
  List<YourRateEntry> _entriesOf(YourRatesState state) {
    final entries = switch (state) {
      YourRatesLoaded(:final recents) => recents,
      YourRatesSearchResults(:final results) => results,
      YourRatesLoading() || YourRatesError() => const <YourRateEntry>[],
    };
    return entries.where((e) => e.equipmentMethod == widget.method).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    final selected = _selectedEntry;
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
          _SearchField(controller: _searchController, onChanged: _onQueryChanged),
          const SizedBox(height: CoreSpacing.space4),
          _Disclaimer(text: l10n.yourRatesDisclaimerText),
          const SizedBox(height: CoreSpacing.space4),
          BlocBuilder<YourRatesBloc, YourRatesState>(
            builder: (context, state) {
              if (state is YourRatesLoading) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: CoreSpacing.space6),
                  child: CoreLoadingIndicator(),
                );
              }
              final entries = _entriesOf(state);
              if (entries.isEmpty) {
                final query = _searchController.text;
                return Padding(
                  key: const Key('your_rates_empty_state'),
                  padding: const EdgeInsets.symmetric(
                    vertical: CoreSpacing.space6,
                  ),
                  child: Text(
                    // A non-empty query with no matches is a different
                    // situation from having no saved rates at all — the
                    // contractor may have plenty, just none matching this
                    // text (or matching, but saved under the other pricing
                    // method — see the TODO on [_entriesOf]).
                    query.isEmpty
                        ? l10n.yourRatesEmptyState
                        : l10n.yourRatesNoMatchState(query),
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
                    method: widget.method,
                    selected: entry.id == selected?.id,
                    onTap: () => _onRowTap(entry),
                  );
                },
              );
            },
          ),
          if (selected != null) ...[
            const SizedBox(height: CoreSpacing.space4),
            // Figma node 66342:169086: a 1px `#eaecf0` rule directly above
            // the confirm button, separating it from the scrolling results
            // above.
            Container(height: 1, color: colorTheme.lineLight),
            const SizedBox(height: CoreSpacing.space4),
            CoreButton(
              key: const Key('your_rates_use_button'),
              label: l10n.yourRatesUseButtonLabel(
                DisplayFormatter.currency.format(selected.rate.amount),
                _unitSuffix(context, widget.method),
              ),
              size: CoreButtonSize.medium,
              onPressed: _onConfirm,
            ),
          ],
        ],
      ),
    );
  }
}

/// Figma node 66342:169083 ("Search Bar", `Property 1=Sheet filled`):
/// white fill, 1px `#d0d5dd` (`colorTheme.lineMid`) stroke, 12px corner
/// radius. [CoreSearchBox] alone gets the icon behavior right (no
/// magnifying-glass icon while empty, a clear/× button once there's text —
/// exactly this component's two variants) but is deliberately borderless
/// everywhere else it's used in this app (an app-bar search field); this
/// wraps it to add the bordered, boxed chrome this sheet's spec calls for.
/// No explicit fill is set: the sheet behind it is already white, so an
/// unpainted box reads identically without hard-coding a duplicate white.
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    return Container(
      key: const Key('your_rates_search_field'),
      decoration: BoxDecoration(
        border: Border.all(color: colorTheme.lineMid),
        borderRadius: BorderRadius.circular(CoreSpacing.space3),
      ),
      child: CoreSearchBox(
        hintText: context.l10n.yourRatesSearchHint,
        controller: controller,
        onChanged: onChanged,
        clearSemanticLabel: context.l10n.yourRatesLookupButton,
      ),
    );
  }
}

/// Figma node 66342:169082 (`<Alert>` instance): fill `#fff6f2`
/// (`colorTheme.backgroundOrangeLight`), stroke `#f7b999`, 12px corner
/// radius, 12/16px regular body text in `colorTheme.textBody`. The `#f7b999`
/// stroke has no matching semantic border token in `ripplearc_coreui`
/// 0.15.0 — [RateStatusBadge] hits the same gap for its orange badge
/// variant, so this is a literal for the same reason, not a new one.
class _Disclaimer extends StatelessWidget {
  final String text;

  const _Disclaimer({required this.text});

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    return Container(
      key: const Key('your_rates_disclaimer'),
      padding: const EdgeInsets.symmetric(
        vertical: CoreSpacing.space3,
        horizontal: CoreSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: colorTheme.backgroundOrangeLight,
        borderRadius: BorderRadius.circular(CoreSpacing.space3),
        border: Border.all(
          // ignore: avoid_static_colors
          color: const Color(0xFFF7B999),
        ),
      ),
      child: Text(
        text,
        style: context.textTheme.bodySmallRegular.copyWith(
          color: colorTheme.textBody,
        ),
      ),
    );
  }
}

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
    final description = entry.description;
    // Figma node 66342:169084/169085: the selected row's name and its
    // leading check both switch to `#015b7c` (colorTheme.textLink); the
    // unselected row keeps the ordinary headline color.
    final nameColor = selected ? colorTheme.textLink : colorTheme.textHeadline;
    // A screen reader needs the price to pick between rows, same as a
    // sighted user reading the amount printed on the row — name and
    // description alone don't say which one costs more.
    final priceLabel =
        '${DisplayFormatter.currency.format(entry.rate.amount)} '
        '${_unitSuffix(context, method)}';
    return Semantics(
      button: true,
      selected: selected,
      label: description == null
          ? '${entry.itemName}. $priceLabel'
          : '${entry.itemName}. $description. $priceLabel',
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
            // Figma's unselected row has no fill at all (transparent over
            // the sheet's own white background); only the selected row
            // gets `#eefaff` (colorTheme.backgroundBlueLight).
            color: selected ? colorTheme.backgroundBlueLight : null,
            borderRadius: BorderRadius.circular(CoreSpacing.space3),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Always laid out, just invisible when unselected — Figma's
              // unselected row instance has this same Check icon at
              // opacity 0 rather than omitted, so text doesn't shift
              // sideways when a row becomes selected.
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Opacity(
                  opacity: selected ? 1 : 0,
                  child: CoreIconWidget(
                    icon: CoreIcons.check,
                    color: colorTheme.textLink,
                    size: CoreSpacing.space5,
                  ),
                ),
              ),
              const SizedBox(width: CoreSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.itemName,
                      style: textTheme.bodyLargeSemiBold.copyWith(
                        color: nameColor,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: textTheme.bodySmallRegular.copyWith(
                          color: colorTheme.textBody,
                        ),
                      ),
                    ],
                  ],
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
