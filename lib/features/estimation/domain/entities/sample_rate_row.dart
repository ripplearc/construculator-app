import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:equatable/equatable.dart';

/// One rate from the sample cost file, as the material Look up a rate sheet
/// lists it under FROM SAMPLE COST FILE (storyboard CUJ 4, sub-flow A,
/// screen 4).
class SampleRateRow extends Equatable {
  const SampleRateRow({
    required this.id,
    required this.productName,
    required this.rate,
    this.details,
    this.unit,
    this.coverage,
    this.coverageUnit,
  });

  /// Identifies the row in the cost file.
  final String id;

  /// The product, shown as the row title and appended to the material name
  /// when picked.
  final String productName;

  /// The price of one purchase.
  final Money rate;

  /// The grey line under the title, such as the brand and finish.
  final String? details;

  /// The unit one purchase is sold in.
  final Unit? unit;

  /// How much one purchase covers, in [coverageUnit]; null when the cost file
  /// does not say.
  final double? coverage;

  /// The takeoff unit [coverage] is measured in.
  final Unit? coverageUnit;

  /// The price per [coverageUnit]: [rate] divided by [coverage]. Shown only,
  /// never saved. Null without a coverage.
  double? get pricePerCoverageUnit => switch (coverage) {
    final covered? when covered > 0 => rate.amount / covered,
    _ => null,
  };

  /// The material name once this row is picked: the typed name with the
  /// product appended, as in "Interior paint · ProClassic", or the product
  /// alone while nothing is typed.
  String materialNameAfter(String typedName) {
    final typed = typedName.trim();
    return typed.isEmpty ? productName : '$typed · $productName';
  }

  /// The unit the price-per-unit column and its footnote use, or null when
  /// both stay hidden. They show only when every row states its coverage and
  /// all rows share one takeoff unit.
  static Unit? sharedCoverageUnit(List<SampleRateRow> rows) {
    final units = {
      for (final row in rows)
        row.pricePerCoverageUnit == null ? null : row.coverageUnit,
    };
    return units.length == 1 ? units.single : null;
  }

  @override
  List<Object?> get props => [
    id,
    productName,
    rate,
    details,
    unit,
    coverage,
    coverageUnit,
  ];
}

/// The sample rates matching a search. The sample cost file is not read yet,
/// so no search finds any.
// TODO: [CA-1157] search the sample cost file here once a real data source exists. https://ripplearc.youtrack.cloud/issue/CA-1157
List<SampleRateRow> noSampleRates(String query) => const [];
