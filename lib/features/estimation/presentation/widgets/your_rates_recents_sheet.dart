import 'dart:async';

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
import 'package:flutter/semantics.dart';
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
/// The Material sheet (storyboard CUJ 4, screen 2 "Your recents") is the same
/// list for [CostItemType.material]: "Add material", "Search or type a
/// material", "New material cost", and each rate shown per its unit.
///
/// Returns a [YourRatesRecentsResult]: the tapped entry, the "+ New … cost"
/// action, or a dismissal (swipe down, tap outside, or back).
class YourRatesRecentsSheet extends StatefulWidget {
  /// Supplies "now" for each row's recency subtitle — see [Clock]'s own doc
  /// comment for why this is injected rather than calling [DateTime.now]
  /// directly.
  final Clock clock;

  /// Whose saved rates are listed: [CostItemType.equipment] or
  /// [CostItemType.material].
  final CostItemType category;

  const YourRatesRecentsSheet({
    super.key,
    required this.clock,
    required this.category,
  });

  @override
  State<YourRatesRecentsSheet> createState() => _YourRatesRecentsSheetState();

  /// Opens this sheet in a [CoreQuickSheet] and returns what the user chose.
  static Future<YourRatesRecentsResult> show({
    required BuildContext context,
    required Clock clock,
    required CostItemType category,
    required YourRatesBloc Function() blocFactory,
  }) async {
    final result = await CoreQuickSheet.show<YourRatesRecentsResult>(
      context: context,
      backgroundColor: sheetSurface(context),
      child: BlocProvider<YourRatesBloc>(
        create: (_) => blocFactory(),
        child: YourRatesRecentsSheet(clock: clock, category: category),
      ),
    );
    return result ?? const YourRatesRecentsDismissed();
  }
}

class _YourRatesRecentsSheetState extends State<YourRatesRecentsSheet> {
  final _searchController = TextEditingController();
  List<YourRateEntry> _lastEntries = const [];
  String? _createPendingFor;
  YourRatesState? _previousState;

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

  bool get _isMaterial => widget.category == CostItemType.material;

  void _loadRecents() => context.read<YourRatesBloc>().add(
    YourRatesRecentsQueried('', widget.category),
  );

  void _onQueryChanged(String query) {
    setState(() {});
    context.read<YourRatesBloc>().add(
      YourRatesRecentsQueried(query, widget.category),
    );
  }

  void _onTryAgain() => _searchController.text.trim().isEmpty
      ? _loadRecents()
      : context.read<YourRatesBloc>().add(
          YourRatesRecentsQueried(
            _searchController.text,
            widget.category,
            immediate: true,
          ),
        );

  void _onRowTap(YourRateEntry entry) =>
      Navigator.of(context).pop(YourRatesRecentsPicked(entry));

  void _onNewCost() =>
      Navigator.of(context).pop(const YourRatesRecentsNewCost());

  void _onCreateTypedName(String name) {
    if (_createPendingFor != null) return;
    final bloc = context.read<YourRatesBloc>();
    final state = bloc.state;
    if (state is YourRatesSearchResults && state.query == name) {
      _popForTypedName(name, state.results);
      return;
    }
    if (state is YourRatesError) {
      _popForTypedName(name, const []);
      return;
    }
    _createPendingFor = name;
    bloc.add(YourRatesRecentsQueried(name, widget.category, immediate: true));
  }

  void _announceFailedRetry(BuildContext context) {
    final l10n = context.l10n;
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        '${l10n.yourRatesLoadError} ${l10n.yourRatesRecentsLoadErrorHint}',
        Directionality.of(context),
      ),
    );
  }

  void _onStateChanged(BuildContext context, YourRatesState state) {
    final wasRetrying = _previousState is YourRatesRetrying;
    _previousState = state;
    if (wasRetrying && state is YourRatesError) _announceFailedRetry(context);
    final pendingName = _createPendingFor;
    if (pendingName == null) return;
    if (state is YourRatesSearchResults && state.query == pendingName) {
      _createPendingFor = null;
      _popForTypedName(pendingName, state.results);
    } else if (state is YourRatesError) {
      _createPendingFor = null;
      _popForTypedName(pendingName, const []);
    }
  }

  static String _nameKey(String text) =>
      text.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  void _popForTypedName(String name, List<YourRateEntry> savedRows) {
    final saved = savedRows
        .where((entry) => _nameKey(entry.itemName) == _nameKey(name))
        .firstOrNull;
    Navigator.of(context).pop(
      saved != null
          ? YourRatesRecentsPicked(saved)
          : YourRatesRecentsNewCost(name: name),
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
        SheetHeader(
          title: _isMaterial
              ? l10n.yourRatesMaterialRecentsTitle
              : l10n.yourRatesRecentsTitle,
        ),
        Padding(
          padding: const EdgeInsets.only(
            left: CoreSpacing.space5,
            right: CoreSpacing.space5,
            bottom: CoreSpacing.space2,
          ),
          child: SheetSearchField(
            controller: _searchController,
            hintText: _isMaterial
                ? l10n.yourRatesMaterialSearchHint
                : l10n.yourRatesSearchHint,
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
                      isMaterial: _isMaterial,
                      onTryAgain: _onTryAgain,
                    ),
                    YourRatesRetrying() => _RecentsLoadError(
                      isRetrying: true,
                      isMaterial: _isMaterial,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: CoreSpacing.space5,
                          ),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: entries.length,
                          separatorBuilder: (_, _) => const SizedBox.shrink(),
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            final recency = entry.recencyLabel(l10n, now: now);
                            final value = DisplayFormatter.currency.format(
                              entry.rate.amount,
                            );
                            final unit = _unitSuffixFor(context, entry);
                            // TODO: [CA-1379] each row is 3 dp taller than the storyboard until CoreUI changes the CoreListRow padding
                            // https://ripplearc.youtrack.cloud/issue/CA-1379
                            return CoreListRow(
                              key: Key('your_rate_row_${entry.id}'),
                              title: entry.itemName,
                              subtitle: recency,
                              value: value,
                              unit: unit,
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
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: CoreSpacing.space3,
                        ),
                        child: isSearching
                            ? CoreListRow.action(
                                key: const Key('create_typed_name_row'),
                                icon: CoreIcons.add,
                                title: _isMaterial
                                    ? l10n.yourRatesCreateMaterialAction(
                                        typedName,
                                      )
                                    : l10n.yourRatesCreateEquipmentAction(
                                        typedName,
                                      ),
                                onTap: () => _onCreateTypedName(typedName),
                              )
                            : CoreListRow.action(
                                key: const Key('new_cost_row'),
                                icon: CoreIcons.add,
                                title: _isMaterial
                                    ? l10n.yourRatesNewMaterialCostAction
                                    : l10n.yourRatesNewEquipmentCostAction,
                                onTap: _onNewCost,
                              ),
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

class _RecentsLoadError extends StatelessWidget {
  final bool isRetrying;
  final bool isMaterial;
  final VoidCallback onTryAgain;

  const _RecentsLoadError({
    required this.isRetrying,
    required this.isMaterial,
    required this.onTryAgain,
  });

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
                CoreInlineErrorRow(message: l10n.yourRatesLoadError),
                const SizedBox(height: CoreSpacing.space2),
                Text(
                  isMaterial
                      ? l10n.yourRatesMaterialRecentsLoadErrorHint
                      : l10n.yourRatesRecentsLoadErrorHint,
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

String? _unitSuffixFor(BuildContext context, YourRateEntry entry) {
  final l10n = context.l10n;
  if (entry.category == CostItemType.material) {
    final unit = entry.unit;
    return unit == null
        ? null
        : l10n.materialRatePerUnitSuffix(unit.displayName(l10n));
  }
  return entry.equipmentMethod == EquipmentPricingMethod.job
      ? l10n.yourRatesJobSuffix
      : l10n.yourRatesDaySuffix;
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

/// "+ New equipment cost" or "+ New material cost" was tapped, or a typed
/// name was created as new. [name] is the typed name, or null when the form
/// opens blank.
final class YourRatesRecentsNewCost extends YourRatesRecentsResult {
  final String? name;

  const YourRatesRecentsNewCost({this.name});
}

/// The sheet was closed without a choice: swipe down, tap outside, or back.
final class YourRatesRecentsDismissed extends YourRatesRecentsResult {
  const YourRatesRecentsDismissed();
}
