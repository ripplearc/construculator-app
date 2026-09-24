import 'package:construculator/features/estimation/domain/entities/cost_estimation_activity_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CostEstimationActivityType', () {
    group('enum values', () {
      test('has all expected activity types', () {
        expect(
          CostEstimationActivityType.values.length,
          22,
          reason: 'Should have exactly 22 activity types',
        );

        expect(
          CostEstimationActivityType.values,
          containsAll([
            CostEstimationActivityType.costEstimationCreated,
            CostEstimationActivityType.costEstimationRenamed,
            CostEstimationActivityType.costEstimationExported,
            CostEstimationActivityType.costEstimationLocked,
            CostEstimationActivityType.costEstimationUnlocked,
            CostEstimationActivityType.costEstimationDeleted,
            CostEstimationActivityType.costItemAdded,
            CostEstimationActivityType.costItemEdited,
            CostEstimationActivityType.costItemRemoved,
            CostEstimationActivityType.costItemDuplicated,
            CostEstimationActivityType.taskAssigned,
            CostEstimationActivityType.taskUnassigned,
            CostEstimationActivityType.costFileUploaded,
            CostEstimationActivityType.costFileDeleted,
            CostEstimationActivityType.attachmentAdded,
            CostEstimationActivityType.attachmentRemoved,
            CostEstimationActivityType.costEstimationSent,
            CostEstimationActivityType.costEstimationOpened,
            CostEstimationActivityType.costEstimationRevoked,
            CostEstimationActivityType.costEstimationApproved,
            CostEstimationActivityType.costEstimationChangesRequested,
            CostEstimationActivityType.unknown,
          ]),
        );
      });
    });

    group('CostEstimationActivityTypeExtension', () {
      group('toJson', () {
        test('converts costEstimationCreated to proper string format', () {
          expect(
            CostEstimationActivityType.costEstimationCreated.toJson(),
            'cost_estimation_created',
          );
        });

        test('converts costEstimationRenamed to proper string format', () {
          expect(
            CostEstimationActivityType.costEstimationRenamed.toJson(),
            'cost_estimation_renamed',
          );
        });

        test('converts costItemAdded to proper string format', () {
          expect(
            CostEstimationActivityType.costItemAdded.toJson(),
            'cost_item_added',
          );
        });

        test('converts taskAssigned to proper string format', () {
          expect(
            CostEstimationActivityType.taskAssigned.toJson(),
            'task_assigned',
          );
        });

        test('converts attachmentRemoved to proper string format', () {
          expect(
            CostEstimationActivityType.attachmentRemoved.toJson(),
            'attachment_removed',
          );
        });

        test('converts costEstimationSent to proper string format', () {
          expect(
            CostEstimationActivityType.costEstimationSent.toJson(),
            'cost_estimation_sent',
          );
        });

        test('converts costEstimationOpened to proper string format', () {
          expect(
            CostEstimationActivityType.costEstimationOpened.toJson(),
            'cost_estimation_opened',
          );
        });

        test('converts costEstimationRevoked to proper string format', () {
          expect(
            CostEstimationActivityType.costEstimationRevoked.toJson(),
            'cost_estimation_revoked',
          );
        });

        test('converts costEstimationApproved to proper string format', () {
          expect(
            CostEstimationActivityType.costEstimationApproved.toJson(),
            'cost_estimation_approved',
          );
        });

        test(
          'converts costEstimationChangesRequested to proper string format',
          () {
            expect(
              CostEstimationActivityType.costEstimationChangesRequested
                  .toJson(),
              'cost_estimation_changes_requested',
            );
          },
        );
      });

      group('fromJson', () {
        test('converts string to costEstimationCreated', () {
          final result = CostEstimationActivityTypeExtension.fromJson(
            'cost_estimation_created',
          );

          expect(result, CostEstimationActivityType.costEstimationCreated);
        });

        test('converts string to costEstimationRenamed', () {
          final result = CostEstimationActivityTypeExtension.fromJson(
            'cost_estimation_renamed',
          );

          expect(result, CostEstimationActivityType.costEstimationRenamed);
        });

        test('converts string to costItemAdded', () {
          final result = CostEstimationActivityTypeExtension.fromJson(
            'cost_item_added',
          );

          expect(result, CostEstimationActivityType.costItemAdded);
        });

        test('converts string to taskUnassigned', () {
          final result = CostEstimationActivityTypeExtension.fromJson(
            'task_unassigned',
          );

          expect(result, CostEstimationActivityType.taskUnassigned);
        });

        test('converts string to attachmentAdded', () {
          final result = CostEstimationActivityTypeExtension.fromJson(
            'attachment_added',
          );

          expect(result, CostEstimationActivityType.attachmentAdded);
        });

        test('converts string to costEstimationSent', () {
          final result = CostEstimationActivityTypeExtension.fromJson(
            'cost_estimation_sent',
          );

          expect(result, CostEstimationActivityType.costEstimationSent);
        });

        test('converts string to costEstimationOpened', () {
          final result = CostEstimationActivityTypeExtension.fromJson(
            'cost_estimation_opened',
          );

          expect(result, CostEstimationActivityType.costEstimationOpened);
        });

        test('converts string to costEstimationRevoked', () {
          final result = CostEstimationActivityTypeExtension.fromJson(
            'cost_estimation_revoked',
          );

          expect(result, CostEstimationActivityType.costEstimationRevoked);
        });

        test('converts string to costEstimationApproved', () {
          final result = CostEstimationActivityTypeExtension.fromJson(
            'cost_estimation_approved',
          );

          expect(result, CostEstimationActivityType.costEstimationApproved);
        });

        test('converts string to costEstimationChangesRequested', () {
          final result = CostEstimationActivityTypeExtension.fromJson(
            'cost_estimation_changes_requested',
          );

          expect(
            result,
            CostEstimationActivityType.costEstimationChangesRequested,
          );
        });

        test('also accepts camelCase string (backward compatibility)', () {
          final result = CostEstimationActivityTypeExtension.fromJson(
            'costEstimationCreated',
          );

          expect(result, CostEstimationActivityType.costEstimationCreated);
        });

        test('returns unknown for unrecognized activity type', () {
          final result = CostEstimationActivityTypeExtension.fromJson(
            'unrecognized_activity_type',
          );

          expect(result, CostEstimationActivityType.unknown);
        });
      });

      group('round-trip conversion', () {
        test('all enum values convert to JSON and back correctly', () {
          for (final activityType in CostEstimationActivityType.values) {
            final json = activityType.toJson();
            final converted = CostEstimationActivityTypeExtension.fromJson(
              json,
            );

            expect(
              converted,
              activityType,
              reason: 'Failed round-trip for $activityType',
            );
          }
        });
      });
    });
  });
}
