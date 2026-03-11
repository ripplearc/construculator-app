import 'package:construculator/features/estimation/domain/entities/cost_estimation_activity_type.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimation_log_entity.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';

/// Formats cost estimation activity logs into human-readable titles.
///
/// Converts [CostEstimationLog] objects into localized activity descriptions.
/// Provides detail-aware formatting where specific entity names (e.g., item names,
/// assignees) are included when available, falling back to generic descriptions
/// when details are missing.
///
/// Example:
/// ```dart
/// final title = CostEstimationActivityTitleFormatter.format(l10n, log);
/// // Returns: "Item Name quantityadded" or "Item added"
/// ```
class CostEstimationActivityTitleFormatter {
  /// Formats a cost estimation activity log into a localized title string.
  ///
  /// Maps the activity type to its corresponding localized message template.
  /// When available, includes contextual details like item names, file names,
  /// or assignee information to create more informative activity descriptions.
  ///
  /// Parameters:
  ///   - [l10n]: Localization instance for retrieving translated strings
  ///   - [log]: The activity log containing activity type and details
  ///
  /// Returns: A localized, human-readable activity title or description
  static String format(AppLocalizations l10n, CostEstimationLog log) {
    final details = log.activityDetails;

    switch (log.activity) {
      case CostEstimationActivityType.costEstimationCreated:
        return l10n.activityCostEstimationCreated;
      case CostEstimationActivityType.costEstimationRenamed:
        return l10n.activityCostEstimationRenamed;
      case CostEstimationActivityType.costEstimationExported:
        return l10n.activityCostEstimationExported;
      case CostEstimationActivityType.costEstimationLocked:
        return l10n.activityCostEstimationLocked;
      case CostEstimationActivityType.costEstimationUnlocked:
        return l10n.activityCostEstimationUnlocked;
      case CostEstimationActivityType.costEstimationDeleted:
        return l10n.activityCostEstimationDeleted;
      case CostEstimationActivityType.costItemAdded:
        final itemName = details['itemName'] as String?;
        if (itemName != null) {
          return l10n.activityCostItemAdded(itemName);
        }
        return l10n.activityCostItemAddedSimple;
      case CostEstimationActivityType.costItemEdited:
        final itemName = details['itemName'] as String?;
        if (itemName != null) {
          return l10n.activityCostItemEdited(itemName);
        }
        return l10n.activityCostItemEditedSimple;
      case CostEstimationActivityType.costItemRemoved:
        final itemName = details['itemName'] as String?;
        if (itemName != null) {
          return l10n.activityCostItemRemoved(itemName);
        }
        return l10n.activityCostItemRemovedSimple;
      case CostEstimationActivityType.costItemDuplicated:
        final itemName = details['itemName'] as String?;
        if (itemName != null) {
          return l10n.activityCostItemDuplicated(itemName);
        }
        return l10n.activityCostItemDuplicatedSimple;
      case CostEstimationActivityType.taskAssigned:
        final taskName = details['taskName'] as String?;
        final assigneeName = details['assigneeName'] as String?;
        if (taskName != null && assigneeName != null) {
          return l10n.activityTaskAssigned(taskName, assigneeName);
        }
        return l10n.activityTaskAssignedSimple;
      case CostEstimationActivityType.taskUnassigned:
        final taskName = details['taskName'] as String?;
        if (taskName != null) {
          return l10n.activityTaskUnassigned(taskName);
        }
        return l10n.activityTaskUnassignedSimple;
      case CostEstimationActivityType.costFileUploaded:
        final fileName = details['fileName'] as String?;
        if (fileName != null) {
          return l10n.activityCostFileUploaded(fileName);
        }
        return l10n.activityCostFileUploadedSimple;
      case CostEstimationActivityType.costFileDeleted:
        final fileName = details['fileName'] as String?;
        if (fileName != null) {
          return l10n.activityCostFileDeleted(fileName);
        }
        return l10n.activityCostFileDeletedSimple;
      case CostEstimationActivityType.attachmentAdded:
        final fileName = details['fileName'] as String?;
        if (fileName != null) {
          return l10n.activityAttachmentAdded(fileName);
        }
        return l10n.activityAttachmentAddedSimple;
      case CostEstimationActivityType.attachmentRemoved:
        final fileName = details['fileName'] as String?;
        if (fileName != null) {
          return l10n.activityAttachmentRemoved(fileName);
        }
        return l10n.activityAttachmentRemovedSimple;
      case CostEstimationActivityType.unknown:
        // Unknown activity types should not appear in production but are handled
        // gracefully to prevent crashes when new server-side activity types are
        // added before the client is updated.
        return l10n.activityUnknown;
    }
  }
}
