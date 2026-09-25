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

  String _displayLabelFor(AppLocalizations l10n, String id) => switch (id) {
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
    'Posts' => l10n.calculatorResultPosts,
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
    'ton' => l10n.calculatorKeyTonsFullName,
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

  List<CoreDependentKeyData> _dependentKeys(
    AppLocalizations l10n,
    CalculatorState state,
  ) {
    final id = state.dependentKeyId;
    if (id == null) return const [];
    return [
      CoreDependentKeyData(
        label: CalculatorPage.pillLabelFor(l10n, id),
        value: state.dependentKeyValue ?? '',
        kind: id.kind,
        onPressed: () {},
      ),
    ];
  }

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
    final Map<GroupNameType, Color> groupAccentColors = {
      groups[0].name: colors.keyboardFunctions,
      groups[1].name: colors.indigo,
      groups[2].name: colors.iconOrange,
      groups[3].name: colors.keyboardUnits,
      groups[4].name: colors.textSuccess,
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
                        dependentKeys: _dependentKeys(l10n, state),
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
