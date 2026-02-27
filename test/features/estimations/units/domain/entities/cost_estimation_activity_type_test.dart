import 'package:construculator/features/estimation/domain/entities/cost_estimation_activity_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CostEstimationActivityType', () {
    group('enum values', () {
      test('has all expected activity types', () {
        expect(
          CostEstimationActivityType.values.length,
          16,
          reason: 'Should have exactly 16 activity types',
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
          ]),
        );
      });
    });

    group('CostEstimationActivityTypeExtension', () {
      group('toJson', () {
        test('converts costEstimationCreated to string', () {
          expect(
            CostEstimationActivityType.costEstimationCreated.toJson(),
            'costEstimationCreated',
          );
        });

        test('converts costEstimationRenamed to string', () {
          expect(
            CostEstimationActivityType.costEstimationRenamed.toJson(),
            'costEstimationRenamed',
          );
        });

        test('converts costItemAdded to string', () {
          expect(
            CostEstimationActivityType.costItemAdded.toJson(),
            'costItemAdded',
          );
        });

        test('converts taskAssigned to string', () {
          expect(
            CostEstimationActivityType.taskAssigned.toJson(),
            'taskAssigned',
          );
        });

        test('converts attachmentRemoved to string', () {
          expect(
            CostEstimationActivityType.attachmentRemoved.toJson(),
            'attachmentRemoved',
          );
        });
      });

      group('fromJson', () {
        test('converts string to costEstimationCreated', () {
          final result = CostEstimationActivityTypeExtension.fromJson(
            'costEstimationCreated',
          );

          expect(result, CostEstimationActivityType.costEstimationCreated);
        });

        test('converts string to costEstimationRenamed', () {
          final result = CostEstimationActivityTypeExtension.fromJson(
            'costEstimationRenamed',
          );

          expect(result, CostEstimationActivityType.costEstimationRenamed);
        });

        test('converts string to costItemAdded', () {
          final result = CostEstimationActivityTypeExtension.fromJson(
            'costItemAdded',
          );

          expect(result, CostEstimationActivityType.costItemAdded);
        });

        test('converts string to taskUnassigned', () {
          final result = CostEstimationActivityTypeExtension.fromJson(
            'taskUnassigned',
          );

          expect(result, CostEstimationActivityType.taskUnassigned);
        });

        test('converts string to attachmentAdded', () {
          final result = CostEstimationActivityTypeExtension.fromJson(
            'attachmentAdded',
          );

          expect(result, CostEstimationActivityType.attachmentAdded);
        });

        test('throws ArgumentError with descriptive message', () {
          expect(
            () => CostEstimationActivityTypeExtension.fromJson('unknown'),
            throwsA(
              isA<ArgumentError>().having(
                (e) => e.message,
                'message',
                contains('Invalid activity type: unknown'),
              ),
            ),
          );
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
