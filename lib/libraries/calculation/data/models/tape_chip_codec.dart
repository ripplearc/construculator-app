import 'dart:convert';

import 'package:construculator/libraries/calculation/data/models/tape_value_codec.dart';
import 'package:construculator/libraries/calculator_engine/models/chip.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/trades.dart';

/// Writes a tape's chip list as the `computation` JSON of a
/// `calculator_tapes` row and reads it back (Design Appendices D).
///
/// The JSON is an object with `schema_version` and `chips`. Every chip is
/// an object with a `type` — `fn_key` for a value under a function key,
/// `common` for a bare number, `result`, `bracket` or `error` — and the
/// fields that chip kind holds, so that a decoded list is equal to the one
/// encoded: a value chip keeps its tokens as typed, the exact quantity a
/// conversion re-spelled it from, the ton it was typed under and its key's
/// flags; a result keeps its key and value at full precision, and a count
/// the stored size it was made at (`size`, written only for a result that
/// carries one, so a tape with none reads and writes as before), and an
/// area a trade key named the key of the answer it named (`named_from`,
/// written the same way); a bracket
/// keeps what was typed inside it, whether it is open, and the list a
/// reopened bracket can be restored to. The operator that leads a chip is
/// its `op`; the values are written by `TapeValueCodec`.
///
/// [encode] may write a `text` beside each chip, the rendering under the
/// settings in force when the tape was banked, so a history card can show
/// the tape without re-running the formatter; [decode] does not read it.
/// A JSON whose `schema_version` is not [schemaVersion], or whose shape a
/// chip cannot be read from, is a [FormatException]: a tape written by a
/// later build is refused whole, never half-read.
abstract final class TapeChipCodec {
  /// The version of the format this build writes and reads.
  static const int schemaVersion = 1;

  /// The key the format's version is written under.
  static const String versionKey = 'schema_version';

  static const String _chipsKey = 'chips';
  static const String _typeKey = 'type';
  static const String _textKey = 'text';
  static const String _keyKey = 'key';
  static const String _operatorKey = 'op';
  static const String _tokensKey = 'tokens';
  static const String _exactKey = 'exact';
  static const String _poundsPerTonKey = 'lbs_per_ton';
  static const String _keyWantsUnitKey = 'wants_unit';
  static const String _readsDegreesKey = 'degrees';
  static const String _isActiveKey = 'active';
  static const String _valueKey = 'value';
  static const String _innerKey = 'inner';
  static const String _isOpenKey = 'open';
  static const String _originalKey = 'original';
  static const String _errorKey = 'error';
  static const String _sizeKey = 'size';
  static const String _widthKey = 'width';
  static const String _heightKey = 'height';
  static const String _idKey = 'id';
  static const String _namedFromKey = 'named_from';

  /// The JSON text of [chips]; [text] renders a chip for its `text`.
  static String encode(
    List<TapeChip> chips, {
    String Function(TapeChip chip)? text,
  }) => jsonEncode({
    versionKey: schemaVersion,
    _chipsKey: [for (final chip in chips) _chip(chip, text)],
  });

  /// The chips [json] holds.
  static List<TapeChip> decode(String json) {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      throw const FormatException('Unreadable tape: not JSON');
    }
    final root = TapeValueCodec.object(decoded, 'tape');
    if (root[versionKey] != schemaVersion) {
      throw FormatException('Unreadable tape: $versionKey ${root[versionKey]}');
    }
    return _chips(root[_chipsKey], _chipsKey);
  }

  static Map<String, Object?> _chip(
    TapeChip chip,
    String Function(TapeChip chip)? text,
  ) => {
    ...switch (chip) {
      ValueChip() => {
        _typeKey: chip.key == null ? 'common' : 'fn_key',
        _keyKey: chip.key,
        _operatorKey: chip.operator?.name,
        _tokensKey: TapeValueCodec.entry(chip.entry),
        _exactKey: switch (chip.exact) {
          final exact? => {
            _valueKey: TapeValueCodec.quantity(exact.value),
            _tokensKey: TapeValueCodec.entry(exact.spelled),
          },
          null => null,
        },
        _poundsPerTonKey: chip.poundsPerTon,
        _keyWantsUnitKey: chip.keyWantsUnit,
        _readsDegreesKey: chip.readsDegrees,
        _isActiveKey: chip.isActive,
      },
      ResultChip() => {
        _typeKey: 'result',
        _keyKey: chip.key,
        _operatorKey: chip.operator?.name,
        _valueKey: TapeValueCodec.quantity(chip.value),
        if (chip.size case final size?)
          _sizeKey: {
            _widthKey: TapeValueCodec.quantity(size.width),
            _heightKey: TapeValueCodec.quantity(size.height),
            _idKey: size.id,
          },
        _namedFromKey: ?chip.namedFrom,
      },
      BracketChip() => {
        _typeKey: 'bracket',
        _operatorKey: chip.operator?.name,
        _innerKey: [for (final inner in chip.inner) _chip(inner, null)],
        _isOpenKey: chip.isOpen,
        _originalKey: switch (chip.original) {
          final original? => [for (final c in original) _chip(c, null)],
          null => null,
        },
      },
      ErrorChip() => {_typeKey: 'error', _errorKey: chip.error.name},
    },
    if (text != null) _textKey: text(chip),
  };

  static List<TapeChip> _chips(Object? json, String where) => [
    for (final (index, chip) in TapeValueCodec.list(json, where).indexed)
      _chipFrom(
        TapeValueCodec.object(chip, '$where[$index]'),
        '$where[$index]',
      ),
  ];

  static TapeChip _chipFrom(
    Map<String, Object?> json,
    String where,
  ) => switch (json[_typeKey]) {
    'fn_key' || 'common' => ValueChip(
      key: TapeValueCodec.optionalText(json, _keyKey, where),
      operator: _operator(json, where),
      entry: TapeValueCodec.entryFrom(json[_tokensKey], '$where.$_tokensKey'),
      exact: switch (json[_exactKey]) {
        null => null,
        final exact => _exact(
          TapeValueCodec.object(exact, '$where.$_exactKey'),
          '$where.$_exactKey',
        ),
      },
      poundsPerTon: TapeValueCodec.optionalInteger(
        json,
        _poundsPerTonKey,
        where,
      ),
      keyWantsUnit: TapeValueCodec.flag(json, _keyWantsUnitKey, where),
      readsDegrees: TapeValueCodec.flag(json, _readsDegreesKey, where),
      isActive: TapeValueCodec.flag(json, _isActiveKey, where),
    ),
    'result' => ResultChip(
      key: TapeValueCodec.text(json, _keyKey, where),
      operator: _operator(json, where),
      value: TapeValueCodec.quantityFrom(json[_valueKey], '$where.$_valueKey'),
      size: switch (json[_sizeKey]) {
        null => null,
        final size => _size(
          TapeValueCodec.object(size, '$where.$_sizeKey'),
          '$where.$_sizeKey',
        ),
      },
      namedFrom: TapeValueCodec.optionalText(json, _namedFromKey, where),
    ),
    'bracket' => BracketChip(
      operator: _operator(json, where),
      inner: _chips(json[_innerKey], '$where.$_innerKey'),
      isOpen: TapeValueCodec.flag(json, _isOpenKey, where),
      original: switch (json[_originalKey]) {
        null => null,
        final original => _chips(original, '$where.$_originalKey'),
      },
    ),
    'error' => ErrorChip(
      CalculationError.values.asNameMap()[json[_errorKey]] ??
          (throw FormatException('Unreadable tape: $where.$_errorKey')),
    ),
    _ => throw FormatException('Unreadable tape: $where.$_typeKey'),
  };

  static PieceSize _size(Map<String, Object?> json, String where) => PieceSize(
    width: _length(json[_widthKey], '$where.$_widthKey'),
    height: _length(json[_heightKey], '$where.$_heightKey'),
    id: TapeValueCodec.optionalText(json, _idKey, where),
  );

  static Length _length(Object? json, String where) =>
      switch (TapeValueCodec.quantityFrom(json, where)) {
        final Length length => length,
        _ => throw FormatException('Unreadable tape: $where'),
      };

  static ExactSpelling _exact(Map<String, Object?> json, String where) => (
    value: TapeValueCodec.quantityFrom(json[_valueKey], '$where.$_valueKey'),
    spelled: TapeValueCodec.entryFrom(json[_tokensKey], '$where.$_tokensKey'),
  );

  static Operator? _operator(Map<String, Object?> json, String where) =>
      switch (json[_operatorKey]) {
        null => null,
        final name =>
          Operator.values.asNameMap()[name] ??
              (throw FormatException('Unreadable tape: $where.$_operatorKey')),
      };
}
