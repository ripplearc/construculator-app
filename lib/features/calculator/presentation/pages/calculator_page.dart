import 'package:construculator/features/calculator/presentation/bloc/calculator_bloc/calculator_bloc.dart';
import 'package:construculator/features/calculator/presentation/formatters/calculator_label_formatter.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// The calculator screen: the display area, the suggestion strip and the
/// keyboard over one [CalculatorBloc] the page owns. It is pushed above the
/// shell, so ✕ with no value in progress leaves it through [router] and
/// returns to Home (UX Design Doc Section 1.1).
class CalculatorPage extends StatefulWidget {
  /// Pops the page when the bloc says the calculator closes.
  final AppRouter router;

  /// Creates the page over the app's [router].
  const CalculatorPage({super.key, required this.router});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  DisplayAreaStage _currentStage = DisplayAreaStage.collapsed;

  Locale? _groupsLocale;
  Map<String, FunctionGroup>? _groupsById;
  List<String>? _orderedFor;
  Map<String, FunctionGroup>? _orderedFrom;
  List<FunctionGroup>? _orderedGroups;

  Map<String, FunctionGroup> _groupsFor(
    BuildContext context,
    CalculatorLabelFormatter labels,
  ) {
    final locale = Localizations.localeOf(context);
    var groups = _groupsById;
    if (groups == null || _groupsLocale != locale) {
      _groupsLocale = locale;
      groups = _buildGroups(labels);
      _groupsById = groups;
    }
    return groups;
  }

  List<FunctionGroup> _groupsInOrder(
    Map<String, FunctionGroup> groupsById,
    List<String> order,
  ) {
    // Built once per order and per group map: the keyboard refreshes its
    // "View all" sheet whenever it is handed a new list object, so a list
    // rebuilt on every state would refresh it on every key, and a list kept
    // across a new group map would keep the old language's words.
    if (_orderedGroups case final groups?
        when identical(_orderedFor, order) &&
            identical(_orderedFrom, groupsById)) {
      return groups;
    }
    _orderedFor = order;
    _orderedFrom = groupsById;
    return _orderedGroups = [
      for (final id in order)
        groupsById[id] ?? (throw StateError('No function group "$id"')),
    ];
  }

  static const List<({String groupId, List<String> keyIds})> _groupTable = [
    (
      groupId: CalculatorLabelFormatter.basicGeometryGroupId,
      keyIds: [
        'Width',
        'Length',
        'Height',
        'Pitch',
        'Run',
        'Rise',
        'Diag',
        'Slope',
      ],
    ),
    (
      groupId: CalculatorLabelFormatter.shapesGroupId,
      keyIds: [
        'Diameter',
        'Radius',
        'Sides',
        'Chord',
        'Rise',
        'Height',
        'Arc',
        'ColCon',
      ],
    ),
    (
      groupId: CalculatorLabelFormatter.materialsGroupId,
      keyIds: [
        'Msnry',
        'Drywal',
        'Footng',
        'Fence',
        'Qty@OC',
        'Cost',
        'Weight',
      ],
    ),
    (
      groupId: CalculatorLabelFormatter.unitGroupId,
      keyIds: ['bf', 'm', 'cm', 'mm', 'lbs', 'kg', 'ton', 'mton'],
    ),
    (
      groupId: CalculatorLabelFormatter.trigonometryGroupId,
      keyIds: ['SIN', 'COS', 'TAN', 'ASIN', 'ACOS', 'ATAN', 'DMS'],
    ),
  ];

  Color _accentFor(AppColorsExtension colors, String groupId) =>
      switch (groupId) {
        CalculatorLabelFormatter.basicGeometryGroupId =>
          colors.keyboardFunctions,
        CalculatorLabelFormatter.shapesGroupId => colors.indigo,
        CalculatorLabelFormatter.materialsGroupId => colors.iconOrange,
        // TODO: [CA-1196] Use the group accent tokens once coreui has them.
        // https://ripplearc.youtrack.cloud/issue/CA-1196
        CalculatorLabelFormatter.unitGroupId => colors.keyboardUnits,
        CalculatorLabelFormatter.trigonometryGroupId => colors.textSuccess,
        _ => colors.keyboardFunctions,
      };

  KeyType _key({
    required String id,
    required String groupId,
    required CalculatorLabelFormatter labels,
  }) => KeyType(
    id: id,
    groupName: groupId,
    label: labels.displayLabel(id),
    semanticLabel: labels.fullName(id),
  );

  CalculatorEvent _unitEventFor(UnitType unit) => switch (unit) {
    UnitType.yards => const CalculatorUnitSelected(Unit.yard),
    UnitType.feet => const CalculatorUnitSelected(Unit.foot),
    UnitType.inch => const CalculatorUnitSelected(Unit.inch),
    UnitType.meter => const CalculatorUnitSelected(Unit.metre),
    UnitType.centimeter => const CalculatorUnitSelected(Unit.centimetre),
    UnitType.millimeter => const CalculatorUnitSelected(Unit.millimetre),
    UnitType.divideSymbol => const CalculatorFractionPressed(),
  };

  // TODO: [CA-1376] Press the % key on the tape once the engine has the
  // four-function percent of Section 7.
  // https://ripplearc.youtrack.cloud/issue/CA-1376
  CalculatorEvent? _operatorEventFor(
    OperatorType operator,
  ) => switch (operator) {
    OperatorType.add => const CalculatorOperatorPressed(Operator.add),
    OperatorType.subtract => const CalculatorOperatorPressed(Operator.subtract),
    OperatorType.multiply => const CalculatorOperatorPressed(Operator.multiply),
    OperatorType.divide => const CalculatorOperatorPressed(Operator.divide),
    OperatorType.percent => null,
  };

  List<SuggestionData> _stripRow(
    CalculatorLabelFormatter labels,
    CalculatorBloc bloc,
    List<CalculatorSuggestion> suggestions,
  ) => [
    for (final suggestion in suggestions)
      SuggestionData(
        label: labels.suggestionLabel(suggestion),
        value: suggestion.text,
        kind: switch (suggestion.kind) {
          CalculatorSuggestionKind.answer ||
          CalculatorSuggestionKind.runningTotal => SuggestionKind.deterministic,
          CalculatorSuggestionKind.conversion => SuggestionKind.conversion,
        },
        onTap: () => bloc.add(CalculatorSuggestionAccepted(suggestion)),
      ),
  ];

  Map<String, FunctionGroup> _buildGroups(CalculatorLabelFormatter labels) => {
    for (final group in _groupTable)
      group.groupId: FunctionGroup(
        name: GroupNameType(
          id: group.groupId,
          label: labels.groupLabel(group.groupId),
        ),
        keys: [
          for (final id in group.keyIds)
            _key(id: id, groupId: group.groupId, labels: labels),
        ],
      ),
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final l10n = context.l10n;
    final labels = CalculatorLabelFormatter(l10n);
    final groupsById = _groupsFor(context, labels);
    final groupAccentColors = {
      for (final group in groupsById.values)
        group.name: _accentFor(colors, group.name.id),
    };

    return BlocProvider<CalculatorBloc>(
      create: (_) => CalculatorBloc(),
      child: Scaffold(
        backgroundColor: colors.pageBackground,
        body: SafeArea(
          child: BlocConsumer<CalculatorBloc, CalculatorState>(
            listenWhen: (previous, current) =>
                current.closesCalculator && !previous.closesCalculator,
            listener: (_, _) => widget.router.pop(),
            builder: (context, state) {
              final bloc = context.read<CalculatorBloc>();
              final dependentKeys = state.dependentKeys;
              final groups = _groupsInOrder(groupsById, state.groupOrder);

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: _currentStage != DisplayAreaStage.collapsed
                          ? const NeverScrollableScrollPhysics()
                          : const AlwaysScrollableScrollPhysics(),
                      child: CoreDisplayArea(
                        label: switch (state.displayLabel) {
                          final label? => labels.labelText(label),
                          null => null,
                        },
                        value: labels.valueText(state),
                        isTyping: state.displayLabel?.isTyping ?? false,
                        closeSemanticLabel: l10n.closeButton,
                        historyPlaceholder: l10n.calculatorHistoryPlaceholder,
                        chipsList: labels.localizeChips(state.chipsList),
                        // TODO(CA-965): previousSessions is unwired pending
                        // research into archiving trigger, data model, and
                        // persistence approach for calculation history.
                        dependentKeys: [
                          for (final key in dependentKeys)
                            labels.dependentKey(
                              key,
                              onPressed: () =>
                                  bloc.add(const CalculatorReadAsAccepted()),
                            ),
                        ],
                        onClose: () =>
                            bloc.add(const CalculatorActiveValueCleared()),
                        onStageChanged: (stage) {
                          if (_currentStage != stage) {
                            setState(() => _currentStage = stage);
                          }
                        },
                      ),
                    ),
                  ),
                  CoreSuggestionArea(
                    layout: CoreSuggestionLayout.twoRows,
                    // TODO: [CA-1094] Draw a strip note in the warning
                    // colour, as Section 1.8 asks, once the strip has a
                    // place for it. https://ripplearc.youtrack.cloud/issue/CA-1094
                    suggestionAreaPlaceholder: labels.stripText(
                      state.stripNote,
                    ),
                    aiSuggestions: _stripRow(labels, bloc, state.suggestions),
                    conversionSuggestions: _stripRow(
                      labels,
                      bloc,
                      state.conversions,
                    ),
                    hiddenChipsTextBuilder: l10n.calculatorStripHiddenChips,
                    expandToggleSemanticsLabelBuilder:
                        l10n.calculatorStripExpandSemantics,
                    collapseToggleSemanticsLabel:
                        l10n.calculatorStripCollapseSemantics,
                    toggleSemanticsLabel: l10n.calculatorStripToggleSemantics,
                    conversionsRowTagLabel: l10n.calculatorStripConversionsTag,
                    conversionsRowSemanticsLabel:
                        l10n.calculatorStripConversionsSemantics,
                    secondRowHidden: dependentKeys.isNotEmpty,
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 1.0,
                      end: switch (_currentStage) {
                        DisplayAreaStage.collapsed => 1.0,
                        DisplayAreaStage.expandedCurrent => 0.95,
                        DisplayAreaStage.expandedPrevious => 0.75,
                        DisplayAreaStage.fullScreen => 0.0,
                      },
                    ),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    builder: (context, factor, child) => ClipRect(
                      child: Align(
                        alignment: Alignment.topCenter,
                        heightFactor: factor,
                        child: child,
                      ),
                    ),
                    child: CoreKeyboard(
                      currentGroup:
                          groups[state.currentGroupIndex.clamp(
                                0,
                                groups.length - 1,
                              )]
                              .name,
                      allGroups: groups,
                      groupAccentColors: groupAccentColors,
                      currentUnitSystem: state.currentUnitSystem,
                      result: ResultType(
                        label: labels.equalsLabel(state.equalsKeyId),
                      ),
                      onDigitPressed: (digit) =>
                          bloc.add(CalculatorDigitPressed(digit.label)),
                      onUnitSelected: (unit) => bloc.add(_unitEventFor(unit)),
                      onOperatorPressed: (op) {
                        if (_operatorEventFor(op) case final event?) {
                          bloc.add(event);
                        }
                      },
                      onControlAction: (action) =>
                          bloc.add(CalculatorControlActioned(action)),
                      onResultTapped: () =>
                          bloc.add(const CalculatorEqualsPressed()),
                      onGroupSelected: (groupName) {
                        final index = groups.indexWhere(
                          (g) => g.name == groupName,
                        );
                        bloc.add(CalculatorGroupSelected(index));
                      },
                      onGroupsReordered: (oldIndex, newIndex) => bloc.add(
                        CalculatorGroupsReordered(
                          oldIndex: oldIndex,
                          newIndex: newIndex,
                        ),
                      ),
                      reorderSemanticsLabelBuilder:
                          l10n.calculatorReorderGroupSemantics,
                      parenSemanticLabel: l10n.calculatorBracketKeySemantics,
                      parenSemanticHint: l10n.calculatorBracketKeyHint,
                      onKeyTapped: (key) =>
                          bloc.add(CalculatorKeySelected(key.id)),
                      onUnitSystemChanged: (unitSystem) =>
                          bloc.add(CalculatorUnitSystemChanged(unitSystem)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
