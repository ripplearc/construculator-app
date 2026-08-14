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

  // TODO(CA-898): KeyType.label doubles as BLoC domain identifier and display
  // string, blocking localization. Requires CoreUI to add a separate `id` field
  // so `onKeyTapped` passes key.id while displayLabel comes from context.l10n.
  List<FunctionGroup> _buildGroups(AppLocalizations l10n) {
    final basicGeometryGroup = GroupNameType(
      label: l10n.calculatorGroupBasicGeometry,
    );
    final materialsGroup = GroupNameType(label: l10n.calculatorGroupMaterials);
    final trigonometryGroup = GroupNameType(
      label: l10n.calculatorGroupTrigonometry,
    );

    return [
      FunctionGroup(
        name: basicGeometryGroup,
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
        name: materialsGroup,
        keys: [
          KeyType(groupName: 'Materials', label: 'Lbs'),
          KeyType(groupName: 'Materials', label: 'Kg'),
          KeyType(groupName: 'Materials', label: 'Tons'),
          KeyType(groupName: 'Materials', label: 'Drywall'),
          KeyType(groupName: 'Materials', label: 'Fence'),
        ],
      ),
      FunctionGroup(
        name: trigonometryGroup,
        keys: [
          KeyType(groupName: 'Trigonometry', label: 'SIN'),
          KeyType(groupName: 'Trigonometry', label: 'COS'),
          KeyType(groupName: 'Trigonometry', label: 'TAN'),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
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
                        label: state.resultLabel ?? state.activeInputLabel,
                        value: state.resultValue ?? state.currentInputValue,
                        isTyping: state.isTyping,
                        closeSemanticLabel: context.l10n.closeButton,
                        chipsList: state.chipsList,
                        // TODO(CA-969): previousSessions is unwired. See
                        // docs/Calculator-History-Design.md (CA-965) for the
                        // archiving trigger, data model, and persistence
                        // approach CA-969 implements.
                        dependentKeyLabel: state.dependentKeyLabel == 'oc'
                            ? context.l10n.calculatorOcLabel
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
