import 'package:construculator/features/calculator/presentation/bloc/calculator_bloc/calculator_bloc.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  DisplayAreaStage _currentStage = DisplayAreaStage.collapsed;

  Locale? _groupsLocale;
  List<FunctionGroup>? _groups;

  List<FunctionGroup> _groupsFor(BuildContext context) {
    final locale = Localizations.localeOf(context);
    var groups = _groups;
    if (groups == null || _groupsLocale != locale) {
      _groupsLocale = locale;
      groups = _buildGroups(context.l10n);
      _groups = groups;
    }
    return groups;
  }

  static const String _basicGeometryId = 'Basic Geometry';
  static const String _materialsId = 'Materials';
  static const String _trigonometryId = 'Trigonometry';

  String _displayLabelFor(AppLocalizations l10n, String id) => switch (id) {
    'Width' => l10n.calculatorKeyWidth,
    'Length' => l10n.calculatorKeyLength,
    'Height' => l10n.calculatorKeyHeight,
    'Pitch' => l10n.calculatorKeyPitch,
    'Circle' => l10n.calculatorKeyCircle,
    'Rise' => l10n.calculatorKeyRise,
    'Run' => l10n.calculatorKeyRun,
    'Radius' => l10n.calculatorKeyRadius,
    'Lbs' => l10n.calculatorKeyLbs,
    'Kg' => l10n.calculatorKeyKg,
    'Tons' => l10n.calculatorKeyTons,
    'Drywall' => l10n.calculatorKeyDrywall,
    'Fence' => l10n.calculatorKeyFence,
    'SIN' => l10n.calculatorKeySin,
    'COS' => l10n.calculatorKeyCos,
    'TAN' => l10n.calculatorKeyTan,
    'Posts' => l10n.calculatorResultPosts,
    _ => _untranslated(id),
  };

  String _untranslated(String id) {
    assert(false, 'No localized label for calculator id "$id"');
    return id;
  }

  List<CoreCalculatorChip> _localizeChips(
    AppLocalizations l10n,
    List<CoreCalculatorChip> chips,
  ) {
    return [
      for (final chip in chips)
        CoreCalculatorChip(
          key: chip.key,
          type: chip.type,
          label: switch (chip.label) {
            final label? => _displayLabelFor(l10n, label),
            null => null,
          },
          value: chip.value,
          factor: chip.factor,
          onTap: chip.onTap,
        ),
    ];
  }

  KeyType _key({
    required String id,
    required String groupId,
    required AppLocalizations l10n,
  }) => KeyType(id: id, groupName: groupId, label: _displayLabelFor(l10n, id));

  List<FunctionGroup> _buildGroups(AppLocalizations l10n) {
    final basicGeometryGroup = GroupNameType(
      id: _basicGeometryId,
      label: l10n.calculatorGroupBasicGeometry,
    );
    final materialsGroup = GroupNameType(
      id: _materialsId,
      label: l10n.calculatorGroupMaterials,
    );
    final trigonometryGroup = GroupNameType(
      id: _trigonometryId,
      label: l10n.calculatorGroupTrigonometry,
    );

    return [
      FunctionGroup(
        name: basicGeometryGroup,
        keys: [
          for (final id in const [
            'Width',
            'Length',
            'Height',
            'Pitch',
            'Circle',
            'Rise',
            'Run',
            'Radius',
          ])
            _key(id: id, groupId: _basicGeometryId, l10n: l10n),
        ],
      ),
      FunctionGroup(
        name: materialsGroup,
        keys: [
          for (final id in const ['Lbs', 'Kg', 'Tons', 'Drywall', 'Fence'])
            _key(id: id, groupId: _materialsId, l10n: l10n),
        ],
      ),
      FunctionGroup(
        name: trigonometryGroup,
        keys: [
          for (final id in const ['SIN', 'COS', 'TAN'])
            _key(id: id, groupId: _trigonometryId, l10n: l10n),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final l10n = context.l10n;
    final groups = _groupsFor(context);
    final Map<GroupNameType, Color> groupAccentColors = {
      groups[0].name: colors.keyboardFunctions,
      groups[1].name: colors.keyboardUnits,
      groups[2].name: colors.textSuccess,
    };

    return BlocProvider<CalculatorBloc>(
      create: (_) => CalculatorBloc(),
      child: Scaffold(
        backgroundColor: colors.pageBackground,
        body: SafeArea(
          child: BlocBuilder<CalculatorBloc, CalculatorState>(
            builder: (context, state) {
              final bloc = context.read<CalculatorBloc>();

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: _currentStage != DisplayAreaStage.collapsed
                          ? const NeverScrollableScrollPhysics()
                          : const AlwaysScrollableScrollPhysics(),
                      child: CoreDisplayArea(
                        label: switch (state.resultLabel ??
                            state.activeInputLabel) {
                          final id? => _displayLabelFor(l10n, id),
                          null => null,
                        },
                        value: state.resultValue ?? state.currentInputValue,
                        isTyping: state.isTyping,
                        closeSemanticLabel: l10n.closeButton,
                        historyPlaceholder: l10n.calculatorHistoryPlaceholder,
                        chipsList: _localizeChips(l10n, state.chipsList),
                        // TODO(CA-965): previousSessions is unwired pending
                        // research into archiving trigger, data model, and
                        // persistence approach for calculation history.
                        dependentKeyLabel: state.dependentKeyLabel == 'oc'
                            ? l10n.calculatorOcLabel
                            : state.dependentKeyLabel,
                        dependentKeyValue: state.dependentKeyValue,
                        onPressedDependentKey: () {},
                        onClose: () =>
                            bloc.add(const CalculatorResetRequested()),
                        onStageChanged: (stage) {
                          if (_currentStage != stage) {
                            setState(() => _currentStage = stage);
                          }
                        },
                      ),
                    ),
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
                      result: const ResultType(label: '='),
                      onDigitPressed: (digit) =>
                          bloc.add(CalculatorDigitPressed(digit.label)),
                      onUnitSelected: (unit) =>
                          bloc.add(CalculatorUnitSelected(unit.label)),
                      onOperatorPressed: (op) =>
                          bloc.add(CalculatorOperatorPressed(op.symbol)),
                      onControlAction: (action) =>
                          bloc.add(CalculatorControlActioned(action)),
                      onResultTapped: () =>
                          bloc.add(const CalculatorOperatorPressed('=')),
                      onGroupSelected: (groupName) {
                        final index = groups.indexWhere(
                          (g) => g.name == groupName,
                        );
                        bloc.add(CalculatorGroupSelected(index));
                      },
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
