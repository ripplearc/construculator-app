import 'package:construculator/features/estimation/domain/entities/cost_estimation_activity_type.dart';

/// Decides which Logs entries lead to the Send screen.
extension CostEstimationActivitySendLink on CostEstimationActivityType {
  /// Whether a Logs entry of this kind shows an arrow and opens the Send
  /// screen when tapped.
  ///
  /// Per the storyboard (CUJ 11, "Build: Send entries"), only sent, link
  /// opened, approval recorded and changes requested do. Send failed, link
  /// revoked and PDF shared do not, and neither does any non-Send entry.
  bool get opensSendScreen => switch (this) {
    CostEstimationActivityType.costEstimationSent ||
    CostEstimationActivityType.costEstimationOpened ||
    CostEstimationActivityType.costEstimationApproved ||
    CostEstimationActivityType.costEstimationChangesRequested => true,
    CostEstimationActivityType.costEstimationCreated ||
    CostEstimationActivityType.costEstimationRenamed ||
    CostEstimationActivityType.costEstimationExported ||
    CostEstimationActivityType.costEstimationLocked ||
    CostEstimationActivityType.costEstimationUnlocked ||
    CostEstimationActivityType.costEstimationDeleted ||
    CostEstimationActivityType.costItemAdded ||
    CostEstimationActivityType.costItemEdited ||
    CostEstimationActivityType.costItemRemoved ||
    CostEstimationActivityType.costItemDuplicated ||
    CostEstimationActivityType.taskAssigned ||
    CostEstimationActivityType.taskUnassigned ||
    CostEstimationActivityType.costFileUploaded ||
    CostEstimationActivityType.costFileDeleted ||
    CostEstimationActivityType.attachmentAdded ||
    CostEstimationActivityType.attachmentRemoved ||
    CostEstimationActivityType.costEstimationSendFailed ||
    CostEstimationActivityType.costEstimationRevoked ||
    CostEstimationActivityType.costEstimationPdfShared ||
    CostEstimationActivityType.unknown => false,
  };
}
