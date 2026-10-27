import 'package:construculator/features/calculator/presentation/bloc/calculator_bloc/calculator_bloc.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();

  /// The visible name of a dependent-key pill, from i18n.
  @visibleForTesting
  static String pillLabelFor(AppLocalizations l10n, DependentKeyId id) =>
      switch (id) {
        DependentKeyId.onCentre => l10n.calculatorPillOnCentre,
        DependentKeyId.sheetSize => l10n.calculatorPillSheetSize,
        DependentKeyId.pieceSize => l10n.calculatorPillPieceSize,
        DependentKeyId.crossSection => l10n.calculatorPillCrossSection,
        DependentKeyId.railsPerSection => l10n.calculatorPillRailsPerSection,
        DependentKeyId.rate => l10n.calculatorPillRate,
        DependentKeyId.waste => l10n.calculatorPillWaste,
        DependentKeyId.density => l10n.calculatorPillDensity,
        DependentKeyId.shownAs => l10n.calculatorPillShownAs,
        DependentKeyId.across => l10n.calculatorPillAcross,
      };

  /// The pill for [id], named from i18n and drawn as the id's kind.
  @visibleForTesting
  static CoreDependentKeyData pillFor(
    AppLocalizations l10n,
    DependentKeyId id,
    String value,
  ) => CoreDependentKeyData(
    label: pillLabelFor(l10n, id),
    value: value,
    kind: id.kind,
    // TODO: [CA-1096] Open the single-value editor to change the spacing.
    // https://ripplearc.youtrack.cloud/issue/CA-1096
    // TODO: [CA-1094] Pass a semanticsHint for the kind once a tap edits or
    // toggles. https://ripplearc.youtrack.cloud/issue/CA-1094
    onPressed: () {},
  );
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
  static const String _shapesId = 'Shapes';
  static const String _materialsId = 'Materials';
  static const String _unitId = 'Unit';
  static const String _trigonometryId = 'Trigonometry';

  static const List<({String groupId, List<String> keyIds})> _groupTable = [
    (
      groupId: _basicGeometryId,
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
      groupId: _shapesId,
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
      groupId: _materialsId,
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
      groupId: _unitId,
      keyIds: ['bf', 'm', 'cm', 'mm', 'lbs', 'kg', 'ton', 'mton'],
    ),
    (
      groupId: _trigonometryId,
      keyIds: ['SIN', 'COS', 'TAN', 'ASIN', 'ACOS', 'ATAN', 'DMS'],
    ),
  ];

  String _groupLabelFor(AppLocalizations l10n, String groupId) =>
      switch (groupId) {
        _basicGeometryId => l10n.calculatorGroupBasicGeometry,
        _shapesId => l10n.calculatorGroupShapes,
        _materialsId => l10n.calculatorGroupMaterials,
        _unitId => l10n.calculatorGroupUnit,
        _trigonometryId => l10n.calculatorGroupTrigonometry,
        _ => _untranslated(groupId),
      };

  Color _accentFor(AppColorsExtension colors, String groupId) =>
      switch (groupId) {
        _basicGeometryId => colors.keyboardFunctions,
        _shapesId => colors.indigo,
        _materialsId => colors.iconOrange,
        // TODO: [CA-1196] Use the group accent tokens once coreui has them.
        // https://ripplearc.youtrack.cloud/issue/CA-1196
        _unitId => colors.keyboardUnits,
        _trigonometryId => colors.textSuccess,
        _ => colors.keyboardFunctions,
      };

  String _displayLabelFor(AppLocalizations l10n, String id) {
    if (CalculationError.values.asNameMap()[id] case final error?) {
      return _errorTitleFor(l10n, error);
    }
    return _keyLabelFor(l10n, id);
  }

  String _errorTitleFor(AppLocalizations l10n, CalculationError error) =>
      switch (error) {
        CalculationError.dimensionError => l10n.calculatorErrorDimension,
        CalculationError.divisionByZero => l10n.calculatorErrorDivisionByZero,
        CalculationError.outOfRange => l10n.calculatorErrorTooLarge,
      };

  String _keyLabelFor(AppLocalizations l10n, String id) => switch (id) {
    'Width' => l10n.calculatorKeyWidth,
    'Length' => l10n.calculatorKeyLength,
    'Height' => l10n.calculatorKeyHeight,
    'Pitch' => l10n.calculatorKeyPitch,
    'Run' => l10n.calculatorKeyRun,
    'Rise' => l10n.calculatorKeyRise,
    'Diag' => l10n.calculatorKeyDiag,
    'Slope' => l10n.calculatorKeySlope,
    'Diameter' => l10n.calculatorKeyDiameter,
    'Radius' => l10n.calculatorKeyRadius,
    'Sides' => l10n.calculatorKeySides,
    'Chord' => l10n.calculatorKeyChord,
    'Arc' => l10n.calculatorKeyArc,
    'ColCon' => l10n.calculatorKeyColCone,
    'Msnry' => l10n.calculatorKeyMsnry,
    'Drywal' => l10n.calculatorKeyDrywal,
    'Footng' => l10n.calculatorKeyFootng,
    'Fence' => l10n.calculatorKeyFence,
    'Qty@OC' => l10n.calculatorKeyQtyAtOc,
    'Cost' => l10n.calculatorKeyCost,
    'Weight' => l10n.calculatorKeyWeight,
    'bf' => l10n.calculatorKeyBdFt,
    'm' => l10n.calculatorKeyMetre,
    'cm' => l10n.calculatorKeyCentimetre,
    'mm' => l10n.calculatorKeyMillimetre,
    'lbs' => l10n.calculatorKeyLbs,
    'kg' => l10n.calculatorKeyKg,
    'ton' => l10n.calculatorKeyTons,
    'mton' => l10n.calculatorKeyMetricTons,
    'SIN' => l10n.calculatorKeySin,
    'COS' => l10n.calculatorKeyCos,
    'TAN' => l10n.calculatorKeyTan,
    'ASIN' => l10n.calculatorKeyAsin,
    'ACOS' => l10n.calculatorKeyAcos,
    'ATAN' => l10n.calculatorKeyAtan,
    'DMS' => l10n.calculatorKeyDms,
    Tape.calcKey => l10n.calculatorResultCalc,
    _ => _untranslated(id),
  };

  String? _fullNameFor(AppLocalizations l10n, String id) => switch (id) {
    'Diag' => l10n.calculatorKeyDiagFullName,
    'ColCon' => l10n.calculatorKeyColConeFullName,
    'Msnry' => l10n.calculatorKeyMsnryFullName,
    'Drywal' => l10n.calculatorKeyDrywalFullName,
    'Footng' => l10n.calculatorKeyFootngFullName,
    'Qty@OC' => l10n.calculatorKeyQtyAtOcFullName,
    'bf' => l10n.calculatorKeyBdFtFullName,
    'm' => l10n.calculatorKeyMetreFullName,
    'cm' => l10n.calculatorKeyCentimetreFullName,
    'mm' => l10n.calculatorKeyMillimetreFullName,
    'lbs' => l10n.calculatorKeyLbsFullName,
    'kg' => l10n.calculatorKeyKgFullName,
    'mton' => l10n.calculatorKeyMetricTonsFullName,
    'SIN' => l10n.calculatorKeySinFullName,
    'COS' => l10n.calculatorKeyCosFullName,
    'TAN' => l10n.calculatorKeyTanFullName,
    'ASIN' => l10n.calculatorKeyAsinFullName,
    'ACOS' => l10n.calculatorKeyAcosFullName,
    'ATAN' => l10n.calculatorKeyAtanFullName,
    'DMS' => l10n.calculatorKeyDmsFullName,
    _ => null,
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
  }) => KeyType(
    id: id,
    groupName: groupId,
    label: _displayLabelFor(l10n, id),
    semanticLabel: _fullNameFor(l10n, id),
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

  // TODO: [CA-1088] Press the % key on the tape once the engine takes a
  // grade under Slope from it. https://ripplearc.youtrack.cloud/issue/CA-1088
  CalculatorEvent? _operatorEventFor(
    OperatorType operator,
  ) => switch (operator) {
    OperatorType.add => const CalculatorOperatorPressed(Operator.add),
    OperatorType.subtract => const CalculatorOperatorPressed(Operator.subtract),
    OperatorType.multiply => const CalculatorOperatorPressed(Operator.multiply),
    OperatorType.divide => const CalculatorOperatorPressed(Operator.divide),
    OperatorType.percent => null,
  };

  List<FunctionGroup> _buildGroups(AppLocalizations l10n) => [
    for (final group in _groupTable)
      FunctionGroup(
        name: GroupNameType(
          id: group.groupId,
          label: _groupLabelFor(l10n, group.groupId),
        ),
        keys: [
          for (final id in group.keyIds)
            _key(id: id, groupId: group.groupId, l10n: l10n),
        ],
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final l10n = context.l10n;
    final groups = _groupsFor(context);
    final groupAccentColors = {
      for (final group in groups) group.name: _accentFor(colors, group.name.id),
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
                        label: switch (state.labelKeyId) {
                          final id? => _displayLabelFor(l10n, id),
                          null => null,
                        },
                        value: state.valueText,
                        isTyping: state.isTyping,
                        closeSemanticLabel: l10n.closeButton,
                        historyPlaceholder: l10n.calculatorHistoryPlaceholder,
                        chipsList: _localizeChips(l10n, state.chipsList),
                        // TODO(CA-965): previousSessions is unwired pending
                        // research into archiving trigger, data model, and
                        // persistence approach for calculation history.
                        // TODO: [CA-1088] The pills under the value come
                        // with the engine's answers.
                        // https://ripplearc.youtrack.cloud/issue/CA-1088
                        dependentKeys: const [],
                        // TODO: [CA-1092] Close the calculator when ✕ is
                        // refused with nothing being typed (Section 1.1).
                        // https://ripplearc.youtrack.cloud/issue/CA-1092
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
