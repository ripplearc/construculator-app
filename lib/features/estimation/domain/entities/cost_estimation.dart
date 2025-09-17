class CostEstimation {
  final String id;
  final String projectId;
  final String estimateName;
  final double? totalCost;
  final bool isFavorite;
  final bool isLocked;
  final DateTime createdAt;
  final DateTime updatedAt;

  CostEstimation({
    required this.id,
    required this.projectId,
    required this.estimateName,
    this.totalCost,
    this.isFavorite = false,
    this.isLocked = false,
    required this.createdAt,
    required this.updatedAt,
  });
}
