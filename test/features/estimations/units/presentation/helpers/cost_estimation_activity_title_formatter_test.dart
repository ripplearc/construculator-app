import 'package:construculator/features/estimation/domain/entities/cost_estimation_activity_type.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimation_log_entity.dart';
import 'package:construculator/features/estimation/presentation/helpers/cost_estimation_activity_title_formatter.dart';
import 'package:construculator/l10n/generated/app_localizations_en.dart';
import 'package:construculator/libraries/auth/domain/entities/user_profile_entity.dart';
import 'package:flutter_test/flutter_test.dart';

CostEstimationLog _createLog({
  required String id,
  required CostEstimationActivityType activity,
  Map<String, dynamic> activityDetails = const {},
}) {
  return CostEstimationLog(
    id: id,
    estimateId: 'est-1',
    activity: activity,
    loggedAt: DateTime.now(),
    user: UserProfile(
      id: id,
      firstName: 'Test',
      lastName: 'User',
      professionalRole: 'Engineer',
    ),
    activityDetails: activityDetails,
  );
}

void main() {
  group('CostEstimationActivityTitleFormatter', () {
    final l10n = AppLocalizationsEn();

    group('format', () {
      test('returns created message for costEstimationCreated activity', () {
        final log = _createLog(
          id: '1',
          activity: CostEstimationActivityType.costEstimationCreated,
        );

        final result = CostEstimationActivityTitleFormatter.format(l10n, log);

        expect(result, equals(l10n.activityCostEstimationCreated));
      });

      test('returns renamed message for costEstimationRenamed activity', () {
        final log = _createLog(
          id: '2',
          activity: CostEstimationActivityType.costEstimationRenamed,
        );

        final result = CostEstimationActivityTitleFormatter.format(l10n, log);

        expect(result, equals(l10n.activityCostEstimationRenamed));
      });

      test('returns exported message for costEstimationExported activity', () {
        final log = _createLog(
          id: '3',
          activity: CostEstimationActivityType.costEstimationExported,
        );

        final result = CostEstimationActivityTitleFormatter.format(l10n, log);

        expect(result, equals(l10n.activityCostEstimationExported));
      });

      test('returns locked message for costEstimationLocked activity', () {
        final log = _createLog(
          id: '4',
          activity: CostEstimationActivityType.costEstimationLocked,
        );

        final result = CostEstimationActivityTitleFormatter.format(l10n, log);

        expect(result, equals(l10n.activityCostEstimationLocked));
      });

      test('returns unlocked message for costEstimationUnlocked activity', () {
        final log = _createLog(
          id: '5',
          activity: CostEstimationActivityType.costEstimationUnlocked,
        );

        final result = CostEstimationActivityTitleFormatter.format(l10n, log);

        expect(result, equals(l10n.activityCostEstimationUnlocked));
      });

      test('returns deleted message for costEstimationDeleted activity', () {
        final log = _createLog(
          id: '6',
          activity: CostEstimationActivityType.costEstimationDeleted,
        );

        final result = CostEstimationActivityTitleFormatter.format(l10n, log);

        expect(result, equals(l10n.activityCostEstimationDeleted));
      });

      test('returns cost item added message with item name', () {
        final log = _createLog(
          id: '7',
          activity: CostEstimationActivityType.costItemAdded,
          activityDetails: {'itemName': 'Labor'},
        );

        final result = CostEstimationActivityTitleFormatter.format(l10n, log);

        expect(result, equals(l10n.activityCostItemAdded('Labor')));
      });

      test(
        'returns simple cost item added message when item name is missing',
        () {
          final log = _createLog(
            id: '8',
            activity: CostEstimationActivityType.costItemAdded,
          );

          final result = CostEstimationActivityTitleFormatter.format(l10n, log);

          expect(result, equals(l10n.activityCostItemAddedSimple));
        },
      );

      test('returns cost item edited message with item name', () {
        final log = _createLog(
          id: '9',
          activity: CostEstimationActivityType.costItemEdited,
          activityDetails: {'itemName': 'Materials'},
        );

        final result = CostEstimationActivityTitleFormatter.format(l10n, log);

        expect(result, equals(l10n.activityCostItemEdited('Materials')));
      });

      test(
        'returns simple cost item edited message when item name is missing',
        () {
          final log = _createLog(
            id: '10',
            activity: CostEstimationActivityType.costItemEdited,
          );

          final result = CostEstimationActivityTitleFormatter.format(l10n, log);

          expect(result, equals(l10n.activityCostItemEditedSimple));
        },
      );

      test('returns cost item removed message with item name', () {
        final log = _createLog(
          id: '11',
          activity: CostEstimationActivityType.costItemRemoved,
          activityDetails: {'itemName': 'Equipment'},
        );

        final result = CostEstimationActivityTitleFormatter.format(l10n, log);

        expect(result, equals(l10n.activityCostItemRemoved('Equipment')));
      });

      test(
        'returns simple cost item removed message when item name is missing',
        () {
          final log = _createLog(
            id: '12',
            activity: CostEstimationActivityType.costItemRemoved,
          );

          final result = CostEstimationActivityTitleFormatter.format(l10n, log);

          expect(result, equals(l10n.activityCostItemRemovedSimple));
        },
      );

      test('returns cost item duplicated message with item name', () {
        final log = _createLog(
          id: '13',
          activity: CostEstimationActivityType.costItemDuplicated,
          activityDetails: {'itemName': 'Permits'},
        );

        final result = CostEstimationActivityTitleFormatter.format(l10n, log);

        expect(result, equals(l10n.activityCostItemDuplicated('Permits')));
      });

      test(
        'returns simple cost item duplicated message when item name is missing',
        () {
          final log = _createLog(
            id: '14',
            activity: CostEstimationActivityType.costItemDuplicated,
          );

          final result = CostEstimationActivityTitleFormatter.format(l10n, log);

          expect(result, equals(l10n.activityCostItemDuplicatedSimple));
        },
      );

      test('returns task assigned message with task and assignee names', () {
        final log = _createLog(
          id: '15',
          activity: CostEstimationActivityType.taskAssigned,
          activityDetails: {
            'taskName': 'Review Estimate',
            'assigneeName': 'John Doe',
          },
        );

        final result = CostEstimationActivityTitleFormatter.format(l10n, log);

        expect(
          result,
          equals(l10n.activityTaskAssigned('Review Estimate', 'John Doe')),
        );
      });

      test('returns simple task assigned message when details are missing', () {
        final log = _createLog(
          id: '16',
          activity: CostEstimationActivityType.taskAssigned,
        );

        final result = CostEstimationActivityTitleFormatter.format(l10n, log);

        expect(result, equals(l10n.activityTaskAssignedSimple));
      });

      test('returns task unassigned message with task name', () {
        final log = _createLog(
          id: '17',
          activity: CostEstimationActivityType.taskUnassigned,
          activityDetails: {'taskName': 'Approval'},
        );

        final result = CostEstimationActivityTitleFormatter.format(l10n, log);

        expect(result, equals(l10n.activityTaskUnassigned('Approval')));
      });

      test(
        'returns simple task unassigned message when task name is missing',
        () {
          final log = _createLog(
            id: '18',
            activity: CostEstimationActivityType.taskUnassigned,
          );

          final result = CostEstimationActivityTitleFormatter.format(l10n, log);

          expect(result, equals(l10n.activityTaskUnassignedSimple));
        },
      );

      test('returns cost file uploaded message with file name', () {
        final log = _createLog(
          id: '19',
          activity: CostEstimationActivityType.costFileUploaded,
          activityDetails: {'fileName': 'budget.xlsx'},
        );

        final result = CostEstimationActivityTitleFormatter.format(l10n, log);

        expect(result, equals(l10n.activityCostFileUploaded('budget.xlsx')));
      });

      test(
        'returns simple cost file uploaded message when details are missing',
        () {
          final log = _createLog(
            id: '20',
            activity: CostEstimationActivityType.costFileUploaded,
          );

          final result = CostEstimationActivityTitleFormatter.format(l10n, log);

          expect(result, equals(l10n.activityCostFileUploadedSimple));
        },
      );

      test('returns cost file deleted message with file name', () {
        final log = _createLog(
          id: '21',
          activity: CostEstimationActivityType.costFileDeleted,
          activityDetails: {'fileName': 'old_budget.xlsx'},
        );

        final result = CostEstimationActivityTitleFormatter.format(l10n, log);

        expect(result, equals(l10n.activityCostFileDeleted('old_budget.xlsx')));
      });

      test(
        'returns simple cost file deleted message when file name is missing',
        () {
          final log = _createLog(
            id: '22',
            activity: CostEstimationActivityType.costFileDeleted,
          );

          final result = CostEstimationActivityTitleFormatter.format(l10n, log);

          expect(result, equals(l10n.activityCostFileDeletedSimple));
        },
      );

      test('returns attachment added message with file name', () {
        final log = _createLog(
          id: '23',
          activity: CostEstimationActivityType.attachmentAdded,
          activityDetails: {'fileName': 'document.pdf'},
        );

        final result = CostEstimationActivityTitleFormatter.format(l10n, log);

        expect(result, equals(l10n.activityAttachmentAdded('document.pdf')));
      });

      test(
        'returns simple attachment added message when file name is missing',
        () {
          final log = _createLog(
            id: '24',
            activity: CostEstimationActivityType.attachmentAdded,
          );

          final result = CostEstimationActivityTitleFormatter.format(l10n, log);

          expect(result, equals(l10n.activityAttachmentAddedSimple));
        },
      );

      test('returns attachment removed message with file name', () {
        final log = _createLog(
          id: '25',
          activity: CostEstimationActivityType.attachmentRemoved,
          activityDetails: {'fileName': 'old_document.pdf'},
        );

        final result = CostEstimationActivityTitleFormatter.format(l10n, log);

        expect(
          result,
          equals(l10n.activityAttachmentRemoved('old_document.pdf')),
        );
      });

      test(
        'returns simple attachment removed message when file name is missing',
        () {
          final log = _createLog(
            id: '26',
            activity: CostEstimationActivityType.attachmentRemoved,
          );

          final result = CostEstimationActivityTitleFormatter.format(l10n, log);

          expect(result, equals(l10n.activityAttachmentRemovedSimple));
        },
      );

      test('returns localized fallback for unknown activity', () {
        final log = _createLog(
          id: '27',
          activity: CostEstimationActivityType.unknown,
        );

        final result = CostEstimationActivityTitleFormatter.format(l10n, log);

        expect(result, equals(l10n.activityUnknown));
      });
    });
  });
}
