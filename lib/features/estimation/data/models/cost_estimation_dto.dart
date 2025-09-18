class CostEstimationDto {
  final String id;
  final String projectId;
  final String estimateName;
  final double? totalCost;
  final bool isFavorite;
  final bool isLocked;
  final String createdAt;
  final String updatedAt;

  CostEstimationDto({
    required this.id,
    required this.projectId,
    required this.estimateName,
    this.totalCost,
    this.isFavorite = false,
    this.isLocked = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CostEstimationDto.fromJson(Map<String, dynamic> json) {
    return CostEstimationDto(
      id: json['id'],
      projectId: json['projectId'],
      estimateName: json['estimateName'],
      totalCost: (json['totalCost'] as num?)?.toDouble(),
      isFavorite: json['isFavorite'] ?? false,
      isLocked: json['isLocked'] ?? false,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'projectId': projectId,
    'estimateName': estimateName,
    'totalCost': totalCost,
    'isFavorite': isFavorite,
    'isLocked': isLocked,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}
