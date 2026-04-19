/// Specifies the field by which cost estimations should be sorted.
///
/// Used by the CostEstimationRepository to determine the order
/// of estimations in streams and paginated lists.
enum EstimationSortOption {
  /// Sort by creation date
  createdAt,
  
  /// Sort by last modification date
  updatedAt,
}
