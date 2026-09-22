import 'package:equatable/equatable.dart';

import 'snapshot.dart';

/// The shapes the prototype's inline checkpoint closures take, as the export
/// script classifies them. [js] is a closure the classifier did not
/// recognise — most read the DOM directly — and the runner reports it as
/// unported rather than passing it.
enum CheckKind {
  /// `r.value === x`
  value,

  /// `r.value.startsWith(x)`
  valueStartsWith,

  /// `r.value.includes(x)`
  valueIncludes,

  /// `r.value.endsWith(x)`
  valueEndsWith,

  /// `r.label === x`
  label,

  /// `r.label.startsWith(x)`
  labelStartsWith,

  /// `r.label.includes(x)`
  labelIncludes,

  /// `r.label.endsWith(x)`
  labelEndsWith,

  /// `r.tape[i] === x`
  tapeAt,

  /// `r.tape[i].startsWith(x)`
  tapeAtStartsWith,

  /// `r.tape[i].includes(x)`
  tapeAtIncludes,

  /// `r.tape[i]` on its own: the chip exists
  tapeAtPresent,

  /// `J(r.tape) === J([...])`
  tape,

  /// `r.tape.length === n`
  tapeLength,

  /// `r.tape.some(x => x === y)` or `r.tape.includes(y)`
  tapeAny,

  /// `r.tape.some(x => x.indexOf(y) === 0)`
  tapeAnyStartsWith,

  /// `r.tape[r.tape.length - 1] === x`
  tapeLast,

  /// `r.tape.join(sep) === x`
  tapeJoined,

  /// `r.tapeKinds[i] === x`
  tapeKindAt,

  /// `J(r.tapeKinds) === J([...])`
  tapeKinds,

  /// `r.tapeGroup[i]`
  tapeBracketAt,

  /// `r.tapeGroupOpen[i]`
  tapeBracketOpenAt,

  /// `r.tapeFrozen[i]`
  tapeFrozenAt,

  /// `r.strip[i] === x`
  stripAt,

  /// `r.strip[i].startsWith(x)`
  stripAtStartsWith,

  /// `r.strip[i].includes(x)`
  stripAtIncludes,

  /// `r.strip[i]` on its own: the chip exists
  stripAtPresent,

  /// `J(r.strip) === J([...])`
  strip,

  /// `r.strip.length === n`
  stripLength,

  /// `r.strip.length > n`, also `r.strip.length >= n + 1`
  stripLengthAbove,

  /// `r.strip.some(x => x === y)`
  stripAny,

  /// `r.strip.some(x => x.startsWith(y))`
  stripAnyStartsWith,

  /// `r.strip.some(x => x.includes(y))`
  stripAnyIncludes,

  /// `r.strip.some(x => x.endsWith(y))`
  stripAnyEndsWith,

  /// `r.strip.every(x => x.startsWith(a) || x.startsWith(b))`
  stripAllStartWithAny,

  /// `r.strip2[i] === x`
  strip2At,

  /// `J(r.strip2) === J([...])`, or `r.strip2 === null`
  strip2,

  /// `r.strip2.length > n`
  strip2LengthAbove,

  /// `r.depKey === x`
  depKey,

  /// `r.depKey.startsWith(x)`
  depKeyStartsWith,

  /// `r.depKey.includes(x)`
  depKeyIncludes,

  /// `!!r.depKey` / `!r.depKey`
  depKeyShown,

  /// `r.toast.includes(x)`
  toastIncludes,

  /// `r.toast.startsWith(x)`
  toastStartsWith,

  /// `!!r.toast` / `!r.toast`
  toastShown,

  /// `r.atoast.includes(x)`
  actionToastIncludes,

  /// `!!r.atoast` / `!r.atoast`
  actionToastShown,

  /// `r.hint === x`
  hint,

  /// `r.hint.includes(x)`
  hintIncludes,

  /// `!!r.hint` / `!r.hint`
  hintShown,

  /// `r.eqLabel === x`
  equalsLabel,

  /// `r.more === x`, `null` for no marker
  more,

  /// `r.mem === x`, `null` for no memory chip
  memory,

  /// `r.mems === n`
  memoryCount,

  /// `r.moreOnScreen === b`
  overflowMarkerOnScreen,

  /// `r.histStage === n`
  historyStage,

  /// `r.histStage >= n`
  historyStageAtLeast,

  /// `r.histCount > n`
  historyCountAbove,

  /// `r.histCount === histAfterSaves(n)`
  historyCountAfterSaves,

  /// `r.histBlocks.length === n`
  historyBlocks,

  /// `r.histBlocks[i] === x`
  historyBlockAt,

  /// `r.histBlocks[i].includes(x)`
  historyBlockAtIncludes,

  /// `r.histBlocks[i]` on its own: the block exists
  historyBlockAtPresent,

  /// `r.groupOpen`
  bracketOpen,

  /// `r.system === x`
  system,

  /// `r.unitToggleLabel === x`
  unitToggleLabel,

  /// `r.unitToggleShown === b`
  unitToggleShown,

  /// `r.fkGroup === x`
  functionGroup,

  /// `r.sheetHidden`
  sheetHidden,

  /// `r.collapsed`
  collapsed,

  /// `r.toggle === b`
  stripToggleShown,

  /// `r.sizeRows.some(x => x.includes(y))`
  sizeRowsAnyIncludes,

  /// `r.tiles.some(x => x.includes(y))`
  tilesAnyIncludes,

  /// `a && b && …`
  all,

  /// `a || b || …`
  any,

  /// `!(a)`
  not,

  /// A closure the export could not classify; its source is kept.
  js,
}

/// One checkpoint check over a [Snapshot], as exported from the prototype.
///
/// One class over a kind rather than a sealed hierarchy: there are fifty
/// shapes and each is one comparison, so a class per shape would be fifty
/// declarations for fifty one-liners. The fields a kind does not use stay
/// `null`.
class Check extends Equatable {
  /// The prototype's history cap: `histAfterSaves(n)` adds one per save to
  /// the count the replay started from (`baseHistory` in [holds]) and never
  /// goes past this.
  static const int historyCap = 50;

  /// The shape.
  final CheckKind kind;

  /// The index into a list for the `…At` kinds.
  final int? index;

  /// The text compared, matched as a prefix, suffix or substring.
  final String? text;

  /// A second text for [CheckKind.stripAllStartWithAny].
  final String? otherText;

  /// The list compared whole for the [CheckKind.tape]-like kinds.
  final List<String>? list;

  /// The number compared for the length and history kinds.
  final int? number;

  /// The boolean expected by the `…Shown`/`…Open` kinds.
  final bool? flag;

  /// The separator for [CheckKind.tapeJoined].
  final String? separator;

  /// The checks joined by [CheckKind.all] and [CheckKind.any].
  final List<Check> checks;

  /// The check negated by [CheckKind.not].
  final Check? inner;

  /// The closure source kept for [CheckKind.js].
  final String? source;

  const Check(
    this.kind, {
    this.index,
    this.text,
    this.otherText,
    this.list,
    this.number,
    this.flag,
    this.separator,
    this.checks = const [],
    this.inner,
    this.source,
  });

  /// Reads a check the export script wrote.
  factory Check.fromJson(Map<String, Object?> json) {
    final kind = CheckKind.values.byName(json['kind'] as String);
    final literal =
        json['equals'] ?? json['prefix'] ?? json['text'] ?? json['suffix'];
    final prefixes = (json['prefixes'] as List?)?.cast<String>();
    return Check(
      kind,
      index: json['index'] as int?,
      text: literal is String ? literal : prefixes?.first,
      otherText: (prefixes?.length ?? 0) > 1 ? prefixes![1] : null,
      list: literal is List ? literal.cast<String>() : null,
      number: literal is int
          ? literal
          : (json['above'] ?? json['saves'] ?? json['atLeast']) as int?,
      flag: literal is bool ? literal : null,
      separator: json['separator'] as String?,
      checks: [
        for (final check in (json['checks'] as List?) ?? const [])
          Check.fromJson((check as Map).cast<String, Object?>()),
      ],
      inner: json['check'] is Map
          ? Check.fromJson((json['check'] as Map).cast<String, Object?>())
          : null,
      source: json['source'] as String?,
    );
  }

  /// Whether the check can be evaluated at all: a [CheckKind.js] check,
  /// alone or inside an [all]/[any]/[not], cannot.
  bool get isPorted => switch (kind) {
    CheckKind.js => false,
    CheckKind.all || CheckKind.any => checks.every((check) => check.isPorted),
    CheckKind.not => inner?.isPorted ?? false,
    _ => true,
  };

  /// Whether the snapshot satisfies the check, given the history count the
  /// replay started from. A [CheckKind.js] check never holds.
  bool holds(Snapshot r, {int baseHistory = 0}) {
    String? at(List<String>? items, int? i) =>
        items != null && i != null && i < items.length ? items[i] : null;
    bool? boolAt(List<bool> items, int? i) =>
        i != null && i < items.length ? items[i] : null;
    return switch (kind) {
      CheckKind.value => r.value == text,
      CheckKind.valueStartsWith => r.value.startsWith(text ?? ''),
      CheckKind.valueIncludes => r.value.contains(text ?? ''),
      CheckKind.valueEndsWith => r.value.endsWith(text ?? ''),
      CheckKind.label => r.label == text,
      CheckKind.labelStartsWith => r.label.startsWith(text ?? ''),
      CheckKind.labelIncludes => r.label.contains(text ?? ''),
      CheckKind.labelEndsWith => r.label.endsWith(text ?? ''),
      CheckKind.tapeAt => at(r.tape, index) == text,
      CheckKind.tapeAtStartsWith =>
        at(r.tape, index)?.startsWith(text ?? '') ?? false,
      CheckKind.tapeAtIncludes =>
        at(r.tape, index)?.contains(text ?? '') ?? false,
      CheckKind.tapeAtPresent => at(r.tape, index) != null,
      CheckKind.tape => _sameList(r.tape, list),
      CheckKind.tapeLength => r.tape.length == number,
      CheckKind.tapeAny => r.tape.contains(text),
      CheckKind.tapeAnyStartsWith => r.tape.any(
        (x) => x.startsWith(text ?? ''),
      ),
      CheckKind.tapeLast => r.tape.isNotEmpty && r.tape.last == text,
      CheckKind.tapeJoined => r.tape.join(separator ?? '') == text,
      CheckKind.tapeKindAt => at(r.tapeKinds, index) == text,
      CheckKind.tapeKinds => _sameList(r.tapeKinds, list),
      CheckKind.tapeBracketAt => boolAt(r.tapeBracket, index) == flag,
      CheckKind.tapeBracketOpenAt => boolAt(r.tapeBracketOpen, index) == flag,
      CheckKind.tapeFrozenAt => boolAt(r.tapeFrozen, index) == flag,
      CheckKind.stripAt => at(r.strip, index) == text,
      CheckKind.stripAtStartsWith =>
        at(r.strip, index)?.startsWith(text ?? '') ?? false,
      CheckKind.stripAtIncludes =>
        at(r.strip, index)?.contains(text ?? '') ?? false,
      CheckKind.stripAtPresent => at(r.strip, index) != null,
      CheckKind.strip => _sameList(r.strip, list),
      CheckKind.stripLength => r.strip.length == number,
      CheckKind.stripLengthAbove => r.strip.length > (number ?? 0),
      CheckKind.stripAny => r.strip.contains(text),
      CheckKind.stripAnyStartsWith => r.strip.any(
        (x) => x.startsWith(text ?? ''),
      ),
      CheckKind.stripAnyIncludes => r.strip.any((x) => x.contains(text ?? '')),
      CheckKind.stripAnyEndsWith => r.strip.any((x) => x.endsWith(text ?? '')),
      CheckKind.stripAllStartWithAny => r.strip.every(
        (x) => x.startsWith(text ?? '') || x.startsWith(otherText ?? ''),
      ),
      CheckKind.strip2At => at(r.strip2, index) == text,
      CheckKind.strip2 => _sameList(r.strip2, list),
      CheckKind.strip2LengthAbove => (r.strip2?.length ?? 0) > (number ?? 0),
      CheckKind.depKey => r.depKey == text,
      CheckKind.depKeyStartsWith => r.depKey?.startsWith(text ?? '') ?? false,
      CheckKind.depKeyIncludes => r.depKey?.contains(text ?? '') ?? false,
      CheckKind.depKeyShown => (r.depKey != null) == flag,
      CheckKind.toastIncludes => r.toast?.contains(text ?? '') ?? false,
      CheckKind.toastStartsWith => r.toast?.startsWith(text ?? '') ?? false,
      CheckKind.toastShown => (r.toast != null) == flag,
      CheckKind.actionToastIncludes =>
        r.actionToast?.contains(text ?? '') ?? false,
      CheckKind.actionToastShown => (r.actionToast != null) == flag,
      CheckKind.hint => r.hint == text,
      CheckKind.hintIncludes => r.hint?.contains(text ?? '') ?? false,
      CheckKind.hintShown => (r.hint != null) == flag,
      CheckKind.equalsLabel => r.equalsLabel == text,
      CheckKind.more => r.more == text,
      CheckKind.memory => r.memory == text,
      CheckKind.memoryCount => r.memoryCount == number,
      CheckKind.overflowMarkerOnScreen => r.overflowMarkerOnScreen == flag,
      CheckKind.historyStage => r.historyStage == number,
      CheckKind.historyStageAtLeast => r.historyStage >= (number ?? 0),
      CheckKind.historyCountAbove => r.historyCount > (number ?? 0),
      CheckKind.historyCountAfterSaves =>
        r.historyCount == _historyAfterSaves(baseHistory, number ?? 0),
      CheckKind.historyBlocks => r.historyBlocks.length == number,
      CheckKind.historyBlockAt => at(r.historyBlocks, index) == text,
      CheckKind.historyBlockAtIncludes =>
        at(r.historyBlocks, index)?.contains(text ?? '') ?? false,
      CheckKind.historyBlockAtPresent => at(r.historyBlocks, index) != null,
      CheckKind.bracketOpen => r.bracketOpen == flag,
      CheckKind.system => r.system == text,
      CheckKind.unitToggleLabel => r.unitToggleLabel == text,
      CheckKind.unitToggleShown => r.unitToggleShown == flag,
      CheckKind.functionGroup => r.functionGroup == text,
      CheckKind.sheetHidden => r.sheetHidden == flag,
      CheckKind.collapsed => r.collapsed == flag,
      CheckKind.stripToggleShown => r.stripToggleShown == flag,
      CheckKind.sizeRowsAnyIncludes => r.sizeRows.any(
        (x) => x.contains(text ?? ''),
      ),
      CheckKind.tilesAnyIncludes => r.tiles.any((x) => x.contains(text ?? '')),
      CheckKind.all => checks.every(
        (check) => check.holds(r, baseHistory: baseHistory),
      ),
      CheckKind.any => checks.any(
        (check) => check.holds(r, baseHistory: baseHistory),
      ),
      CheckKind.not => !(inner?.holds(r, baseHistory: baseHistory) ?? true),
      CheckKind.js => false,
    };
  }

  static bool _sameList(List<String>? actual, List<String>? expected) {
    if (actual == null || expected == null) return actual == expected;
    if (actual.length != expected.length) return false;
    for (var i = 0; i < actual.length; i++) {
      if (actual[i] != expected[i]) return false;
    }
    return true;
  }

  static int _historyAfterSaves(int base, int saves) {
    var count = base;
    for (var i = 0; i < saves; i++) {
      count = count + 1 > historyCap ? historyCap : count + 1;
    }
    return count;
  }

  @override
  List<Object?> get props => [
    kind,
    index,
    text,
    otherText,
    list,
    number,
    flag,
    separator,
    checks,
    inner,
    source,
  ];
}
