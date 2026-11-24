part of 'calculator_bloc.dart';

/// The sheet table of the detail panel (UX Design Doc Section 1.4, "Sheet
/// quantities"; term 2.17): the area the counts cover and one row per
/// stored size, in the order of the chips on the strip.
class CalculatorSizeTable extends Equatable {
  /// The area every row counts, as the display writes it (180ft²).
  final String areaText;

  /// One row per stored size, in the store's order.
  final List<CalculatorSizeRow> rows;

  /// Creates a table over [rows] for [areaText].
  const CalculatorSizeTable({required this.areaText, required this.rows});

  @override
  List<Object?> get props => [areaText, rows];
}

/// One row of the sheet table: a stored size and how many of it cover the
/// area.
class CalculatorSizeRow extends Equatable {
  /// Names the row while the table is on screen: what the store calls the
  /// stored size ([PieceSize.id]), which no other row shares and which
  /// stays the row's own when another row is deleted, a row of the same
  /// size included. A count with no stored size behind it is named by the
  /// size as written and how many rows before it show the same size.
  final String id;

  /// The size, width first (48in x 96in).
  final String sizeText;

  /// The count as the strip's chip writes it (5.63).
  final String countText;

  /// The count the row shows, which a delete removes the size of.
  final TradeCount count;

  /// Creates a row.
  const CalculatorSizeRow({
    required this.id,
    required this.sizeText,
    required this.countText,
    required this.count,
  });

  @override
  List<Object?> get props => [id, sizeText, countText, count];
}
