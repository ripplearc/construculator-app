import 'package:equatable/equatable.dart';

/// What the prototype's `tpSnapshot()` records after every step: the text
/// of each surface the checkpoints read. Chip text is the DOM's
/// `textContent`, so a tape chip is its key and text with no separator
/// ("Area410.67ft²") and a strip chip reads "Area: 410.67ft²".
///
/// The Dart runner (H2) builds one of these from the engine and the
/// formatter after each step and hands it to the checks; fields it cannot
/// produce yet stay at their empty defaults, which is what a checkpoint on
/// them then reports.
class Snapshot extends Equatable {
  /// The label row ("Length…", "Addition · (3×4)").
  final String label;

  /// The value row ("22ft", "Error").
  final String value;

  /// The dependent-key pills joined with " | ", or `null` when none shows.
  final String? depKey;

  /// The strip's hint text when it shows one instead of chips.
  final String? hint;

  /// Every tape chip's text, left to right.
  final List<String> tape;

  /// Each tape chip's kind class ("t-input", "t-result", "t-error").
  final List<String> tapeKinds;

  /// Whether each tape chip is a closed bracket.
  final List<bool> tapeBracket;

  /// Whether each tape chip is an open bracket.
  final List<bool> tapeBracketOpen;

  /// Whether each tape chip is dimmed: left over from before an open
  /// bracket, still visible but not the live typing point.
  final List<bool> tapeFrozen;

  /// Row 1 of the strip.
  final List<String> strip;

  /// Row 2 of the strip, or `null` when the strip has one row.
  final List<String>? strip2;

  /// The overflow marker ("+1"), or `null`.
  final String? more;

  /// The memory chip's text, or `null`.
  final String? memory;

  /// How many memory chips the strip shows.
  final int memoryCount;

  /// Whether the overflow marker sits inside the strip's edges, or `null`
  /// when there is none.
  final bool? overflowMarkerOnScreen;

  /// The text on the bracket key ("( )", or ")" while one is open).
  final String bracketLabel;

  /// The text on the equals key ("Area", "Calc", "Ans", or empty for =).
  final String equalsLabel;

  /// Whether a bracket is open.
  final bool bracketOpen;

  /// Whether the System of units toggle shows.
  final bool unitToggleShown;

  /// The toggle's text ("Imperial", "Metric").
  final String unitToggleLabel;

  /// The system of units ("imperial", "metric").
  final String system;

  /// The function-group label on the keyboard.
  final String functionGroup;

  /// Whether the keypad sheet is collapsed.
  final bool collapsed;

  /// The detail panel's tiles.
  final List<String> tiles;

  /// The detail panel's size rows.
  final List<String> sizeRows;

  /// The error toast's body while it shows, or `null`; never the empty
  /// string, which the `…Shown` checks would read as shown.
  final String? toast;

  /// The action (receipt) toast's body while it shows, or `null`; never the
  /// empty string, for the same reason.
  final String? actionToast;

  /// How many sessions history holds.
  final int historyCount;

  /// The history stage of the display (0 to 3).
  final int historyStage;

  /// The history blocks stacked above the tape.
  final List<String> historyBlocks;

  /// Whether the keypad sheet is hidden.
  final bool sheetHidden;

  /// Whether the strip's ✨/📏 toggle shows.
  final bool stripToggleShown;

  const Snapshot({
    this.label = '',
    this.value = '',
    this.depKey,
    this.hint,
    this.tape = const [],
    this.tapeKinds = const [],
    this.tapeBracket = const [],
    this.tapeBracketOpen = const [],
    this.tapeFrozen = const [],
    this.strip = const [],
    this.strip2,
    this.more,
    this.memory,
    this.memoryCount = 0,
    this.overflowMarkerOnScreen,
    this.bracketLabel = '( )',
    this.equalsLabel = '',
    this.bracketOpen = false,
    this.unitToggleShown = true,
    this.unitToggleLabel = 'Imperial',
    this.system = 'imperial',
    this.functionGroup = '',
    this.collapsed = false,
    this.tiles = const [],
    this.sizeRows = const [],
    this.toast,
    this.actionToast,
    this.historyCount = 0,
    this.historyStage = 0,
    this.historyBlocks = const [],
    this.sheetHidden = false,
    this.stripToggleShown = false,
  });

  @override
  List<Object?> get props => [
    label,
    value,
    depKey,
    hint,
    tape,
    tapeKinds,
    tapeBracket,
    tapeBracketOpen,
    tapeFrozen,
    strip,
    strip2,
    more,
    memory,
    memoryCount,
    overflowMarkerOnScreen,
    bracketLabel,
    equalsLabel,
    bracketOpen,
    unitToggleShown,
    unitToggleLabel,
    system,
    functionGroup,
    collapsed,
    tiles,
    sizeRows,
    toast,
    actionToast,
    historyCount,
    historyStage,
    historyBlocks,
    sheetHidden,
    stripToggleShown,
  ];
}
