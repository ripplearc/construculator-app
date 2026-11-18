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
  });

  /// Identifies the row in the cost file.
  final String id;

  /// The product, shown as the row title.
  final String productName;

  /// The price of one purchase.
  final Money rate;

  /// The grey line under the title, such as the brand and finish.
  final String? details;

  /// The unit one purchase is sold in.
  final Unit? unit;

  @override
  List<Object?> get props => [id, productName, rate, details, unit];
}

/// The sample rates matching a search. The sample cost file is not read yet,
/// so no search finds any.
// TODO: [CA-1157] search the sample cost file here once a real data source exists. https://ripplearc.youtrack.cloud/issue/CA-1157
List<SampleRateRow> noSampleRates(String query) => const [];
