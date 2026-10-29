import 'package:construculator/features/calculator/presentation/bloc/calculator_bloc/calculator_bloc.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// The words the calculator page shows for the engine's stable ids: a
/// function key's label and full name, a group's name, the title of an
/// error chip, the full name of a trig function, and a dependent-key pill.
///
/// The bloc names everything by a locale-independent id and never by a
/// visible string; this is the one place those ids become text, so the
/// page, its tests and the golden replay read the same words.
class CalculatorLabelFormatter {
  /// The translations the words come from.
  final AppLocalizations l10n;

  const CalculatorLabelFormatter(this.l10n);

  /// The id of the Basic geometry group.
  static const String basicGeometryGroupId = 'Basic Geometry';

  /// The id of the Shapes group.
  static const String shapesGroupId = 'Shapes';

  /// The id of the Materials group.
  static const String materialsGroupId = 'Materials';

  /// The id of the Unit group.
  static const String unitGroupId = 'Unit';

  /// The id of the Trigonometry group.
  static const String trigonometryGroupId = 'Trigonometry';

  /// The visible name of a function-key group.
  String groupLabel(String groupId) => switch (groupId) {
    basicGeometryGroupId => l10n.calculatorGroupBasicGeometry,
    shapesGroupId => l10n.calculatorGroupShapes,
    materialsGroupId => l10n.calculatorGroupMaterials,
    unitGroupId => l10n.calculatorGroupUnit,
    trigonometryGroupId => l10n.calculatorGroupTrigonometry,
    _ => _untranslated(groupId),
  };

  /// The text the display shows for the id a chip or the label row names:
  /// an error's title, a trig function's full name with the ratio it took,
  /// or a key's label.
  String displayLabel(String id) {
    if (CalculationError.values.asNameMap()[id] case final error?) {
      return errorTitle(error);
    }
    if (_trigFunctionOf(id) case final function?) {
      return trigLabel(function) + id.substring(function.key.length);
    }
    return keyLabel(id);
  }

  TrigFunction? _trigFunctionOf(String id) {
    for (final function in TrigFunction.values) {
      if (id == function.key || id.startsWith('${function.key}(')) {
        return function;
      }
    }
    return null;
  }

  /// The full name of a trig function.
  String trigLabel(TrigFunction function) => switch (function) {
    TrigFunction.sine => l10n.calculatorKeySinFullName,
    TrigFunction.cosine => l10n.calculatorKeyCosFullName,
    TrigFunction.tangent => l10n.calculatorKeyTanFullName,
    TrigFunction.arcsine => l10n.calculatorKeyAsinFullName,
    TrigFunction.arccosine => l10n.calculatorKeyAcosFullName,
    TrigFunction.arctangent => l10n.calculatorKeyAtanFullName,
  };

  /// The title of an error chip.
  String errorTitle(CalculationError error) => switch (error) {
    CalculationError.dimensionError => l10n.calculatorErrorDimension,
    CalculationError.divisionByZero => l10n.calculatorErrorDivisionByZero,
    CalculationError.outOfRange => l10n.calculatorErrorTooLarge,
  };

  /// The label on a function key, or of a result chip's key.
  String keyLabel(String id) => switch (id) {
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

  /// The full name of an abbreviated key, read to a screen reader after the
  /// face; `null` when the face is the full name.
  String? fullName(String id) => switch (id) {
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

  /// The visible name of a dependent-key pill.
  String pillLabel(DependentKeyId id) => switch (id) {
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

  /// The pill for [id], named from i18n and drawn as the id's kind. No
  /// answer carries one of these ids yet (the stores, G1 to G3).
  @visibleForTesting
  CoreDependentKeyData pill(DependentKeyId id, String value) =>
      CoreDependentKeyData(
        label: pillLabel(id),
        value: value,
        kind: id.kind,
        // TODO: [CA-1096] Open the single-value editor to change the spacing.
        // https://ripplearc.youtrack.cloud/issue/CA-1096
        // TODO: [CA-1094] Pass a semanticsHint for the kind once a tap edits
        // or toggles. https://ripplearc.youtrack.cloud/issue/CA-1094
        onPressed: () {},
      );

  /// The chips of the tape with their labels translated; the values are
  /// already text.
  List<CoreCalculatorChip> localizeChips(List<CoreCalculatorChip> chips) => [
    for (final chip in chips)
      CoreCalculatorChip(
        key: chip.key,
        type: chip.type,
        label: switch (chip.label) {
          final label? => displayLabel(label),
          null => null,
        },
        value: chip.value,
        factor: chip.factor,
        onTap: chip.onTap,
      ),
  ];

  String _untranslated(String id) {
    assert(false, 'No localized label for calculator id "$id"');
    return id;
  }
}
