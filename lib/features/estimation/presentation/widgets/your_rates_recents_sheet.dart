import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
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

/// "Your recents" sheet (Figma node `66342:177929`, "phone ·
/// cuj6-equip-1-recents" on the "Estimate V2" canvas): the pre-form step
/// opened by "+ Add equipment cost" — a tap-to-reuse list of the
/// contractor's most recently used equipment rates. Day- and job-priced
/// rows share one list with no heading or color split between them; only
/// the trailing "/day" vs "job" word differs. A trailing "+ New equipment
/// cost" row opens the form blank instead.
///
/// A "Search or type equipment" box sits above the list. A typed name lists
/// the matching saved rates under YOUR RATES, or one "No matches" line, and
/// the last row becomes "Create “name” as a new equipment cost". Clearing the
/// box shows the recents again.
///
/// TODO: [CA-1157](https://ripplearc.youtrack.cloud/issue/CA-1157) Search the sample cost file here too, under a FROM SAMPLE COST FILE heading below YOUR RATES, once a real data source exists.
///
/// Distinct from [YourRatesLookupSheet] (Figma Screen 4, reached later from
/// inside the open form's magnifier icon): this sheet has no disclaimer, no
/// checkbox-select-then-confirm step, and isn't filtered to a single pricing
/// method — tapping a row recalls it immediately.
///
/// Returns a [YourRatesRecentsResult]: the tapped entry, the "+ New equipment
/// cost" action, or a dismissal (swipe down, tap outside, or back).
class YourRatesRecentsSheet extends StatefulWidget {
  /// Supplies "now" for each row's recency subtitle — see [Clock]'s own doc
  /// comment for why this is injected rather than calling [DateTime.now]
  /// directly.
  final Clock clock;

  const YourRatesRecentsSheet({super.key, required this.clock});

  @override
  State<YourRatesRecentsSheet> createState() => _YourRatesRecentsSheetState();

  /// Opens this sheet in a [CoreQuickSheet] and returns what the user chose.
  static Future<YourRatesRecentsResult> show({
    required BuildContext context,
    required Clock clock,
    required YourRatesBloc Function() blocFactory,
  }) async {
    final result = await CoreQuickSheet.show<YourRatesRecentsResult>(
      context: context,
      backgroundColor: sheetSurface(context),
      child: BlocProvider<YourRatesBloc>(
        create: (_) => blocFactory(),
        child: YourRatesRecentsSheet(clock: clock),
      ),
    );
    return result ?? const YourRatesRecentsDismissed();
  }
}

class _YourRatesRecentsSheetState extends State<YourRatesRecentsSheet> {
  final _searchController = TextEditingController();
  List<YourRateEntry> _lastEntries = const [];
  String? _createPendingFor;

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadRecents() => context.read<YourRatesBloc>().add(
    const YourRatesRecentsQueried('', CostItemType.equipment),
  );

  void _onQueryChanged(String query) {
    setState(() {});
    context.read<YourRatesBloc>().add(
      YourRatesRecentsQueried(query, CostItemType.equipment),
    );
  }

  void _onTryAgain() => _searchController.text.trim().isEmpty
      ? _loadRecents()
      : context.read<YourRatesBloc>().add(
          YourRatesRecentsQueried(
            _searchController.text,
            CostItemType.equipment,
            immediate: true,
          ),
        );

  void _onRowTap(YourRateEntry entry) =>
      Navigator.of(context).pop(YourRatesRecentsPicked(entry));

  void _onNewEquipmentCost() =>
      Navigator.of(context).pop(const YourRatesRecentsNewEquipmentCost());

  void _onCreateTypedEquipment(String name) {
    if (_createPendingFor != null) return;
    final bloc = context.read<YourRatesBloc>();
    final state = bloc.state;
    if (state is YourRatesSearchResults && state.query == name) {
      _popForTypedName(name, state.results);
      return;
    }
    _createPendingFor = name;
    bloc.add(
      YourRatesRecentsQueried(name, CostItemType.equipment, immediate: true),
    );
  }

  void _onStateChanged(BuildContext context, YourRatesState state) {
    final pendingName = _createPendingFor;
    if (pendingName == null) return;
    if (state is YourRatesSearchResults && state.query == pendingName) {
      _createPendingFor = null;
      _popForTypedName(pendingName, state.results);
    } else if (state is YourRatesError) {
      _createPendingFor = null;
    }
  }

  void _popForTypedName(String name, List<YourRateEntry> savedRows) {
    final saved = savedRows
        .where(
          (entry) => entry.itemName.trim().toLowerCase() == name.toLowerCase(),
        )
        .firstOrNull;
    Navigator.of(context).pop(
      saved != null
          ? YourRatesRecentsPicked(saved)
          : YourRatesRecentsNewEquipmentCost(name: name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    final now = widget.clock.now();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(title: l10n.yourRatesRecentsTitle),
        Padding(
          padding: const EdgeInsets.only(
            left: CoreSpacing.space5,
            right: CoreSpacing.space5,
            bottom: CoreSpacing.space2,
          ),
          child: SheetSearchField(
            controller: _searchController,
            onChanged: _onQueryChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: CoreSpacing.space4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BlocConsumer<YourRatesBloc, YourRatesState>(
                listener: _onStateChanged,
                builder: (context, state) {
                  final typedName = _searchController.text.trim();
                  final isSearching = typedName.isNotEmpty;
                  final isLoading = state is YourRatesLoading;
                  if (isLoading && !isSearching) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: CoreSpacing.space6,
                      ),
                      child: CoreLoadingIndicator(),
                    );
                  }
                  final loadError = switch (state) {
                    YourRatesError() => _RecentsLoadError(
                      isRetrying: false,
                      onTryAgain: _onTryAgain,
                    ),
                    YourRatesRetrying() => _RecentsLoadError(
                      isRetrying: true,
                      onTryAgain: _onTryAgain,
                    ),
                    _ => null,
                  };
                  final entries = switch (state) {
                    YourRatesLoaded(:final recents) when !isSearching =>
                      recents,
                    YourRatesSearchResults(:final results) when isSearching =>
                      results,
                    YourRatesLoading() => _lastEntries,
                    _ => const <YourRateEntry>[],
                  };
                  if (!isLoading) _lastEntries = entries;
                  final hasNoMatch =
                      isSearching &&
                      state is YourRatesSearchResults &&
                      entries.isEmpty;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ?loadError,
                      if (entries.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            CoreSpacing.space5,
                            CoreSpacing.space3,
                            CoreSpacing.space5,
                            CoreSpacing.space1,
                          ),
                          child: Text(
                            (isSearching
                                    ? l10n.yourRatesName
                                    : l10n.yourRatesRecentsSectionHeading)
                                .toUpperCase(),
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
                          separatorBuilder: (_, _) => const SizedBox.shrink(),
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
                      if (isLoading)
                        const Padding(
                          key: Key('your_rates_recents_searching'),
                          padding: EdgeInsets.symmetric(
                            vertical: CoreSpacing.space6,
                          ),
                          child: CoreLoadingIndicator(),
                        ),
                      if (hasNoMatch)
                        Padding(
                          key: const Key('your_rates_recents_no_match'),
                          padding: const EdgeInsets.only(
                            left: CoreSpacing.space5,
                            top: CoreSpacing.space6,
                            right: CoreSpacing.space5,
                            bottom: CoreSpacing.space6 + CoreSpacing.space2,
                          ),
                          child: Text(
                            l10n.yourRatesNoMatchState(typedName),
                            textAlign: TextAlign.center,
                            style: context.textTheme.bodyMediumRegular.copyWith(
                              color: colorTheme.textBody,
                            ),
                          ),
                        ),
                      const CoreDivider(),
                      if (isSearching)
                        _NewEquipmentCostRow(
                          key: const Key('create_typed_equipment_row'),
                          label: l10n.yourRatesCreateEquipmentAction(typedName),
                          onTap: () => _onCreateTypedEquipment(typedName),
                        )
                      else
                        _NewEquipmentCostRow(
                          key: const Key('new_equipment_cost_row'),
                          label: l10n.yourRatesNewEquipmentCostAction,
                          onTap: _onNewEquipmentCost,
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// TODO: [CA-1316] replace with the CoreUI inline error row once it exists. https://ripplearc.youtrack.cloud/issue/CA-1316
class _RecentsLoadError extends StatelessWidget {
  final bool isRetrying;
  final VoidCallback onTryAgain;

  const _RecentsLoadError({required this.isRetrying, required this.onTryAgain});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    return Padding(
      key: const Key('your_rates_recents_load_error'),
      padding: const EdgeInsets.fromLTRB(
        CoreSpacing.space5,
        CoreSpacing.space3,
        CoreSpacing.space5,
        CoreSpacing.space3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            liveRegion: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CoreIconWidget(
                      icon: CoreIcons.error,
                      size: CoreIconSize.size16,
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
                  ],
                ),
                const SizedBox(height: CoreSpacing.space2),
                Text(
                  l10n.yourRatesRecentsLoadErrorHint,
                  style: textTheme.bodySmallRegular.copyWith(
                    color: colorTheme.textBody,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: CoreSpacing.space3),
          CoreButton(
            key: const Key('your_rates_recents_try_again_button'),
            label: l10n.yourRatesTryAgain,
            variant: CoreButtonVariant.secondary,
            fullWidth: false,
            isDisabled: isRetrying,
            onPressed: onTryAgain,
          ),
        ],
      ),
    );
  }
}

String _unitSuffixFor(BuildContext context, EquipmentPricingMethod? method) =>
    method == EquipmentPricingMethod.job
    ? context.l10n.yourRatesJobSuffix
    : context.l10n.yourRatesDaySuffix;

// TODO: [CA-1204](https://ripplearc.youtrack.cloud/issue/CA-1204) Replace with CoreUI's list-row component once it exists; it also removes the 11 px and 1 px values below, which have no CoreSpacing token.
class _RecentRateRow extends StatelessWidget {
  static const double _rowVerticalPadding = 11;
  static const double _nameToRecencyGap = 1;

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
    final recency = entry.recencyLabel(context.l10n, now: now);
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
            horizontal: CoreSpacing.space7,
            vertical: _rowVerticalPadding,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                    const SizedBox(height: _nameToRecencyGap),
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
                      text: DisplayFormatter.currency.format(entry.rate.amount),
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

// TODO: [CA-1204] replace with CoreUI's list-row component once it exists. https://ripplearc.youtrack.cloud/issue/CA-1204
class _NewEquipmentCostRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NewEquipmentCostRow({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: CoreSpacing.space12),
          padding: const EdgeInsets.symmetric(
            vertical: CoreSpacing.space3,
            horizontal: CoreSpacing.space5,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CoreIconWidget(
                icon: CoreIcons.add,
                color: colorTheme.textLink,
                size: CoreSpacing.space5,
              ),
              const SizedBox(width: CoreSpacing.space3),
              Flexible(
                child: Text(
                  label,
                  style: context.textTheme.bodyMediumSemiBold.copyWith(
                    color: colorTheme.textLink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What the user chose on [YourRatesRecentsSheet].
sealed class YourRatesRecentsResult {
  const YourRatesRecentsResult();
}

/// A saved rate row was tapped.
final class YourRatesRecentsPicked extends YourRatesRecentsResult {
  final YourRateEntry entry;

  const YourRatesRecentsPicked(this.entry);
}

/// "+ New equipment cost" was tapped, or a typed name was created as new.
/// [name] is the typed name, or null when the form opens blank.
final class YourRatesRecentsNewEquipmentCost extends YourRatesRecentsResult {
  final String? name;

  const YourRatesRecentsNewEquipmentCost({this.name});
}

/// The sheet was closed without a choice: swipe down, tap outside, or back.
final class YourRatesRecentsDismissed extends YourRatesRecentsResult {
  const YourRatesRecentsDismissed();
}
