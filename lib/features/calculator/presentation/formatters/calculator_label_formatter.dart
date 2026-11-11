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
  static const String basicGeometryGroupId = CalculatorGroupId.basicGeometry;

  /// The id of the Shapes group.
  static const String shapesGroupId = CalculatorGroupId.shapes;

  /// The id of the Materials group.
  static const String materialsGroupId = CalculatorGroupId.materials;

  /// The id of the Unit group.
  static const String unitGroupId = CalculatorGroupId.unit;

  /// The id of the Trigonometry group.
  static const String trigonometryGroupId = CalculatorGroupId.trigonometry;

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

  /// The text of the value row: the state's reading of the chip, or the
  /// word "Error" under an error chip's title (Section 5).
  String valueText(CalculatorState state) =>
      state.valueReadsError ? l10n.calculatorValueError : state.valueText;

  /// The title of an error chip.
  String errorTitle(CalculationError error) => switch (error) {
    CalculationError.dimensionError => l10n.calculatorErrorDimension,
    CalculationError.divisionByZero => l10n.calculatorErrorDivisionByZero,
    CalculationError.outOfRange => l10n.calculatorErrorTooLarge,
  };

  /// The most characters a suggestion's name may have to replace the =
  /// sign on the equals key (term 2.15: "up to eight characters (Area, Rise,
  /// Update…); a longer name such as Arctangent or Pitch-rise per 12in run
  /// keeps the = sign").
  static const int equalsKeyMaxLength = 8;

  /// The face of the equals key: the name of the suggestion = will land
  /// when it fits, else the = sign.
  String equalsLabel(String? keyId) {
    if (keyId == null) return equalsSign;
    final label = displayLabel(keyId);
    return label.length <= equalsKeyMaxLength ? label : equalsSign;
  }

  /// The = sign, the equals key's face when no suggestion names it.
  static const String equalsSign = '=';

  /// The name on a strip chip: the answer's name for row 1, nothing for a
  /// conversion, which row 2 shows by its value alone.
  String suggestionLabel(CalculatorSuggestion suggestion) =>
      switch (suggestion.key) {
        final key? => displayLabel(key),
        null => '',
      };

  /// The label on a function key, of a result chip's key, or of an answer
  /// the rules compute (Section 8).
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
    CalculatorState.ansKey => l10n.calculatorEqualsAns,
    DeterministicRules.areaKey => l10n.calculatorAnswerArea,
    DeterministicRules.diagonalKey => l10n.calculatorAnswerDiagonal,
    DeterministicRules.perimeterKey => l10n.calculatorAnswerPerimeter,
    DeterministicRules.volumeKey => l10n.calculatorAnswerVolume,
    DeterministicRules.wallAreaKey => l10n.calculatorAnswerWallArea,
    DeterministicRules.circleAreaKey => l10n.calculatorAnswerCircleArea,
    DeterministicRules.circumferenceKey => l10n.calculatorAnswerCircumference,
    DeterministicRules.polygonAreaKey => l10n.calculatorAnswerPolygonArea,
    DeterministicRules.sideLengthKey => l10n.calculatorAnswerSideLength,
    DeterministicRules.cornerAngleKey => l10n.calculatorAnswerCornerAngle,
    DeterministicRules.arcAngleKey => l10n.calculatorAnswerArcAngle,
    DeterministicRules.arcRadiusKey => l10n.calculatorAnswerArcRadius,
    DeterministicRules.arcLengthKey => l10n.calculatorAnswerArcLength,
    DeterministicRules.pitchRiseKey => l10n.calculatorAnswerPitchRise,
    DeterministicRules.pitchDegreesKey => l10n.calculatorAnswerPitchDegrees,
    DeterministicRules.pitchGradeKey => l10n.calculatorAnswerPitchGrade,
    DeterministicRules.columnKey => l10n.calculatorAnswerColumn,
    DeterministicRules.coneKey => l10n.calculatorAnswerCone,
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

  /// The text of the label row (Section 1.1): the key, the operator's name
  /// for a chip with no key, or "Value"; then the reading of a bare number
  /// and the inside of a closed bracket, each after a middle dot. The
  /// ellipsis of a value still being typed is drawn by the display.
  String labelText(CalculatorDisplayLabel label) {
    final head = switch (label) {
      CalculatorDisplayLabel(:final keyId?) => displayLabel(keyId),
      CalculatorDisplayLabel(:final operator?) => operatorLabel(operator),
      CalculatorDisplayLabel() => l10n.calculatorLabelValue,
    };
    final reading = switch (label.reading) {
      final reading? => ' · ${readingLabel(reading)}',
      null => '',
    };
    final bracket = switch (label.bracketExpression) {
      final expression? => ' · ($expression)',
      null => '',
    };
    return '$head$reading$bracket';
  }

  /// The name of the operation a chip with no key opens: "Addition 3".
  String operatorLabel(Operator operator) => switch (operator) {
    Operator.add => l10n.calculatorOperatorAddition,
    Operator.subtract => l10n.calculatorOperatorSubtraction,
    Operator.multiply => l10n.calculatorOperatorMultiplication,
    Operator.divide => l10n.calculatorOperatorDivision,
  };

  /// The word the label row names a bare number's reading by.
  String readingLabel(NumberReading reading) => switch (reading) {
    NumberReading.degrees => l10n.calculatorReadingDegrees,
    NumberReading.degreesMinutesSeconds => l10n.calculatorReadingDms,
    NumberReading.ratio => l10n.calculatorReadingRatio,
    NumberReading.risePerFoot => l10n.calculatorReadingRisePerFoot,
    NumberReading.grade => l10n.calculatorReadingGrade,
  };

  /// A pill under the value, named from i18n: the Read-as offer as the
  /// sentence "Input 8.45° as 8.45in/12in" (or "Re-input …" when the tap
  /// rebuilds an answer).
  CoreDependentKeyData dependentKey(
    CalculatorDependentKey key, {
    required VoidCallback onPressed,
  }) => switch (key) {
    CalculatorReadAsPill(
      :final sourceText,
      :final targetText,
      :final rebuildsAnAnswer,
    ) =>
      CoreDependentKeyData(
        label: rebuildsAnAnswer
            ? l10n.calculatorPillReInputAs(sourceText)
            : l10n.calculatorPillInputAs(sourceText),
        value: targetText,
        kind: CoreDependentKeyKind.offer,
        semanticsHint: l10n.calculatorPillReadAsHint,
        onPressed: onPressed,
      ),
  };

  /// The strip note (Section 1.8), or the strip's placeholder when the
  /// strip has nothing to say.
  String stripText(CalculatorStripNote? note) => switch (note) {
    null => l10n.calculatorStripPlaceholder,
    CalculatorPitchOutOfRangeNote(isAtLeastARightAngle: true) =>
      l10n.calculatorNotePitchUnderRightAngle,
    CalculatorPitchOutOfRangeNote() => l10n.calculatorNotePitchAtLeastZero,
    CalculatorFlatPitchHasNoRunNote() => l10n.calculatorNoteFlatPitchHasNoRun,
    CalculatorSlopeOutOfRangeNote() => l10n.calculatorNoteSlopeAboveZero,
    CalculatorPitchHasNoDmsNote() => l10n.calculatorNotePitchHasNoDms,
    CalculatorTrigCannotAnswerNote(:final function) =>
      l10n.calculatorNoteTrigCannotAnswer(trigLabel(function)),
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

  /// The chips of the tape with their labels translated: every other field
  /// of a chip is carried over as it is, so a field the state sets later
  /// reaches the screen. A bracket chip is read in words that tell an open
  /// bracket from a closed one, led by the operator its factor draws, as a
  /// value chip's text is led by its own ("+3"): the factor icon itself is
  /// silent to a screen reader. With [onChipTap] a tap on a value chip
  /// reaches it with the chip's index: a finished chip says a tap edits it,
  /// the chip being typed or edited that a tap finishes the edit (Section
  /// 1.1, "Tap an input chip to edit it"); a result, an error and a bracket
  /// chip take no tap here.
  List<CoreCalculatorChip> localizeChips(
    List<CoreCalculatorChip> chips, {
    void Function(int index)? onChipTap,
  }) => [
    for (final (index, chip) in chips.indexed)
      CoreCalculatorChip(
        key: chip.key,
        type: chip.type,
        label: switch (chip.label) {
          final label? => displayLabel(label),
          null => null,
        },
        value: chip.value,
        factor: chip.factor,
        onTap: switch (chip.type) {
          CoreCalculatorChipType.editable || CoreCalculatorChipType.active
              when onChipTap != null =>
            () => onChipTap(index),
          _ => chip.onTap,
        },
        tapSemanticLabel: switch (chip.type) {
          CoreCalculatorChipType.editable when onChipTap != null =>
            l10n.calculatorChipTapToEdit,
          CoreCalculatorChipType.active when onChipTap != null =>
            l10n.calculatorChipTapToFinish,
          _ => chip.tapSemanticLabel,
        },
        onLongPress: chip.onLongPress,
        longPressSemanticLabel: chip.longPressSemanticLabel,
        semanticsLabel: switch (chip.type) {
          CoreCalculatorChipType.bracketOpen =>
            '${_leadOf(chip.factor)}'
                '${l10n.calculatorBracketOpenSemantics(chip.value ?? '')}',
          CoreCalculatorChipType.bracketClosed =>
            '${_leadOf(chip.factor)}'
                '${l10n.calculatorBracketClosedSemantics(chip.value ?? '')}',
          _ => chip.semanticsLabel,
        },
        inert: chip.inert,
      ),
  ];

  static String _leadOf(CoreIconData? factor) {
    for (final MapEntry(:key, :value) in operatorIcons.entries) {
      if (value == factor) return key.symbol;
    }
    return '';
  }

  /// The unit spelled out for a toast ("yards", "pounds"; Section 5.2).
  String unitName(Unit unit) => l10n.calculatorUnitName(unit.name);

  /// The face of the key that presses [unit], for a toast that points at
  /// the key ("Press ⌫ to remove Lbs"; Section 5.2): the Unit group's keys
  /// by their localized labels, and a unit column key by its spelled-out
  /// name, since its face is the keyboard's own.
  String unitKeyFace(Unit unit) => switch (unit) {
    Unit.pound => l10n.calculatorKeyLbs,
    Unit.kilogram => l10n.calculatorKeyKg,
    Unit.ton => l10n.calculatorKeyTons,
    Unit.metricTon => l10n.calculatorKeyMetricTons,
    Unit.boardFoot => l10n.calculatorKeyBdFt,
    Unit.metre => l10n.calculatorKeyMetre,
    Unit.centimetre => l10n.calculatorKeyCentimetre,
    Unit.millimetre => l10n.calculatorKeyMillimetre,
    _ => unitName(unit),
  };

  /// The title of [toast], or `null` for a toast that is one sentence.
  String? toastTitle(CalculatorToast toast) => switch (toast) {
    CalculatorFinishValueToast() => l10n.calculatorToastFinishValueTitle,
    CalculatorTypeNewFirstValueToast() => null,
    CalculatorResultRemovedToast() => null,
    CalculatorCannotAppendUnitToast(:final unit) =>
      l10n.calculatorToastCannotAppendTitle(unitName(unit)),
    CalculatorNeedsLengthToast(:final key) =>
      l10n.calculatorToastNeedsLengthTitle(displayLabel(key)),
    CalculatorKeepsLengthToast(:final key, :final value) =>
      l10n.calculatorToastKeepsLengthTitle(displayLabel(key), value),
  };

  /// The body of [toast], in the words of UX Design Doc Section 5.
  String toastBody(CalculatorToast toast) => switch (toast) {
    CalculatorFinishValueToast(value: '') => l10n.calculatorToastValueEmptyBody,
    CalculatorFinishValueToast(:final value) =>
      l10n.calculatorToastFinishValueBody(value),
    CalculatorTypeNewFirstValueToast() => l10n.calculatorToastTypeNewFirstValue,
    CalculatorResultRemovedToast(keys: [final key]) =>
      l10n.calculatorToastResultRemoved(displayLabel(key)),
    CalculatorResultRemovedToast(keys: [final first, final second]) =>
      l10n.calculatorToastResultsRemovedBoth(
        displayLabel(first),
        displayLabel(second),
      ),
    CalculatorResultRemovedToast(keys: [final first, ...final more]) =>
      l10n.calculatorToastResultsRemovedMore(displayLabel(first), more.length),
    CalculatorResultRemovedToast(keys: []) => '',
    CalculatorCannotAppendUnitToast(:final value, :final unit) =>
      l10n.calculatorToastCannotAppendBody(value, unitName(unit)),
    CalculatorNeedsLengthToast(:final unit, tail: null) =>
      l10n.calculatorToastNeedsLengthBody(unitKeyFace(unit)),
    CalculatorNeedsLengthToast(:final key, :final unit, :final tail?) =>
      l10n.calculatorToastTailNeedsLengthBody(
        displayLabel(key),
        unitName(unit),
        tail,
      ),
    CalculatorKeepsLengthToast(:final key, :final unit, :final value) =>
      l10n.calculatorToastKeepsLengthBody(
        unitName(unit),
        value,
        displayLabel(key),
      ),
  };

  String _untranslated(String id) {
    assert(false, 'No localized label for calculator id "$id"');
    return id;
  }
}
