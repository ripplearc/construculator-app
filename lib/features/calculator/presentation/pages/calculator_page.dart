import 'package:construculator/features/calculator/presentation/bloc/calculator_bloc/calculator_bloc.dart';
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

  // TODO(CA-898): KeyType.label doubles as BLoC domain identifier and display
  // string, blocking localization. Requires CoreUI to add a separate `id` field
  // so `onKeyTapped` passes key.id while displayLabel comes from context.l10n.
  static const _basicGeometryGroup = GroupNameType(label: 'Basic Geometry');
  static const _materialsGroup = GroupNameType(label: 'Materials');
  static const _trigonometryGroup = GroupNameType(label: 'Trigonometry');

  static final List<FunctionGroup> _groups = [
    FunctionGroup(
      name: _basicGeometryGroup,
      keys: [
        KeyType(groupName: 'Basic Geometry', label: 'Width'),
        KeyType(groupName: 'Basic Geometry', label: 'Length'),
        KeyType(groupName: 'Basic Geometry', label: 'Height'),
        KeyType(groupName: 'Basic Geometry', label: 'Pitch'),
        KeyType(groupName: 'Basic Geometry', label: 'Circle'),
        KeyType(groupName: 'Basic Geometry', label: 'Rise'),
        KeyType(groupName: 'Basic Geometry', label: 'Run'),
        KeyType(groupName: 'Basic Geometry', label: 'Radius'),
      ],
    ),
    FunctionGroup(
      name: _materialsGroup,
      keys: [
        KeyType(groupName: 'Materials', label: 'Lbs'),
        KeyType(groupName: 'Materials', label: 'Kg'),
        KeyType(groupName: 'Materials', label: 'Tons'),
        KeyType(groupName: 'Materials', label: 'Drywall'),
        KeyType(groupName: 'Materials', label: 'Fence'),
      ],
    ),
    FunctionGroup(
      name: _trigonometryGroup,
      keys: [
        KeyType(groupName: 'Trigonometry', label: 'SIN'),
        KeyType(groupName: 'Trigonometry', label: 'COS'),
        KeyType(groupName: 'Trigonometry', label: 'TAN'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final Map<GroupNameType, Color> groupAccentColors = {
      _basicGeometryGroup: colors.keyboardFunctions,
      _materialsGroup: colors.keyboardUnits,
      _trigonometryGroup: colors.textSuccess,
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
                        label: state.resultLabel ?? state.activeInputLabel,
                        value: state.resultValue ?? state.currentInputValue,
                        isTyping: state.isTyping,
                        chipsList: state.chipsList,
                        dependentKeyLabel: state.dependentKeyLabel,
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
                      currentGroup: _groups[state.currentGroupIndex].name,
                      allGroups: _groups,
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
                        final index =
                            _groups.indexWhere((g) => g.name == groupName);
                        if (index != -1) {
                          bloc.add(CalculatorGroupSelected(index));
                        }
                      },
                      onKeyTapped: (key) =>
                          bloc.add(CalculatorKeySelected(key.label)),
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
