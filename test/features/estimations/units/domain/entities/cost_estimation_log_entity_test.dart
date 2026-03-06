import 'package:construculator/features/estimation/domain/entities/cost_estimation_activity_type.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimation_log_entity.dart';
import 'package:construculator/libraries/auth/domain/entities/user_profile_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CostEstimationLog', () {
    final testLoggedAt = DateTime(2025, 2, 25, 14, 30);

    const testUser = UserProfile(
      id: 'user-123',
      credentialId: 'cred-456',
      firstName: 'John',
      lastName: 'Doe',
      professionalRole: 'Project Manager',
      profilePhotoUrl: 'https://example.com/photo.jpg',
    );

    final testLog = CostEstimationLog(
      id: 'log-123',
      estimateId: 'estimate-456',
      activity: CostEstimationActivityType.costEstimationRenamed,
      user: testUser,
      activityDetails: const {
        'oldName': 'Old Estimation Name',
        'newName': 'New Estimation Name',
      },
      loggedAt: testLoggedAt,
    );

    group('constructor', () {
      test('creates instance with all required fields', () {
        expect(testLog.id, 'log-123');
        expect(testLog.estimateId, 'estimate-456');
        expect(
          testLog.activity,
          CostEstimationActivityType.costEstimationRenamed,
        );
        expect(testLog.user, testUser);
        expect(testLog.activityDetails, {
          'oldName': 'Old Estimation Name',
          'newName': 'New Estimation Name',
        });
        expect(testLog.loggedAt, testLoggedAt);
      });

      test('creates instance with empty activity details', () {
        final log = CostEstimationLog(
          id: 'log-456',
          estimateId: 'estimate-789',
          activity: CostEstimationActivityType.costEstimationLocked,
          user: testUser,
          activityDetails: const {},
          loggedAt: testLoggedAt,
        );

        expect(log.activityDetails, isEmpty);
      });

      test('creates instance for cost item added activity', () {
        final log = CostEstimationLog(
          id: 'log-789',
          estimateId: 'estimate-123',
          activity: CostEstimationActivityType.costItemAdded,
          user: testUser,
          activityDetails: const {
            'costItemId': 'item-123',
            'costItemType': 'material',
            'description': 'Concrete',
          },
          loggedAt: testLoggedAt,
        );

        expect(log.activity, CostEstimationActivityType.costItemAdded);
        expect(log.activityDetails['costItemId'], 'item-123');
        expect(log.activityDetails['costItemType'], 'material');
        expect(log.activityDetails['description'], 'Concrete');
      });

      test('creates instance for cost item edited activity', () {
        final log = CostEstimationLog(
          id: 'log-999',
          estimateId: 'estimate-123',
          activity: CostEstimationActivityType.costItemEdited,
          user: testUser,
          activityDetails: const {
            'costItemId': 'item-456',
            'costItemType': 'labor',
            'editedFields': {
              'quantity': {'oldValue': 10, 'newValue': 15},
              'unitPrice': {'oldValue': 50.0, 'newValue': 55.0},
            },
          },
          loggedAt: testLoggedAt,
        );

        expect(log.activity, CostEstimationActivityType.costItemEdited);
        expect(log.activityDetails['editedFields'], isA<Map>());
      });
    });

    group('copyWith', () {
      test('returns new instance with updated id', () {
        final expected = testLog.copyWith(id: 'log-new');

        final updated = testLog.copyWith(id: 'log-new');

        expect(updated, expected);
      });

      test('returns new instance with updated estimateId', () {
        final expected = testLog.copyWith(estimateId: 'estimate-new');

        final updated = testLog.copyWith(estimateId: 'estimate-new');

        expect(updated, expected);
      });

      test('returns new instance with updated activity', () {
        final expected = testLog.copyWith(
          activity: CostEstimationActivityType.costEstimationDeleted,
        );

        final updated = testLog.copyWith(
          activity: CostEstimationActivityType.costEstimationDeleted,
        );

        expect(updated, expected);
      });

      test('returns new instance with updated user', () {
        const newUser = UserProfile(
          id: 'user-999',
          firstName: 'Jane',
          lastName: 'Smith',
          professionalRole: 'Engineer',
        );

        final expected = testLog.copyWith(user: newUser);

        final updated = testLog.copyWith(user: newUser);

        expect(updated, expected);
      });

      test('returns new instance with updated activity details', () {
        final expected = testLog.copyWith(
          activityDetails: const {'newKey': 'newValue'},
        );

        final updated = testLog.copyWith(
          activityDetails: const {'newKey': 'newValue'},
        );

        expect(updated, expected);
      });

      test('returns new instance with updated loggedAt', () {
        final newDate = DateTime(2025, 3, 1);
        final expected = testLog.copyWith(loggedAt: newDate);

        final updated = testLog.copyWith(loggedAt: newDate);

        expect(updated, expected);
      });

      test('returns instance with same values when no parameters provided', () {
        final copied = testLog.copyWith();

        expect(copied, testLog);
      });
    });

    group('Equatable', () {
      test('two instances with same values are equal', () {
        final log1 = CostEstimationLog(
          id: 'log-123',
          estimateId: 'estimate-456',
          activity: CostEstimationActivityType.costEstimationRenamed,
          user: testUser,
          activityDetails: const {'oldName': 'Old Name', 'newName': 'New Name'},
          loggedAt: testLoggedAt,
        );

        final log2 = CostEstimationLog(
          id: 'log-123',
          estimateId: 'estimate-456',
          activity: CostEstimationActivityType.costEstimationRenamed,
          user: testUser,
          activityDetails: const {'oldName': 'Old Name', 'newName': 'New Name'},
          loggedAt: testLoggedAt,
        );

        expect(log1, equals(log2));
      });

      test('two instances with different activity types are not equal', () {
        final log1 = CostEstimationLog(
          id: 'log-123',
          estimateId: 'estimate-456',
          activity: CostEstimationActivityType.costEstimationLocked,
          user: testUser,
          activityDetails: const {},
          loggedAt: testLoggedAt,
        );

        final log2 = CostEstimationLog(
          id: 'log-123',
          estimateId: 'estimate-456',
          activity: CostEstimationActivityType.costEstimationUnlocked,
          user: testUser,
          activityDetails: const {},
          loggedAt: testLoggedAt,
        );

        expect(log1, isNot(equals(log2)));
      });

      test('two instances with different activity details are not equal', () {
        final log1 = CostEstimationLog(
          id: 'log-123',
          estimateId: 'estimate-456',
          activity: CostEstimationActivityType.costItemAdded,
          user: testUser,
          activityDetails: const {'costItemId': 'item-1'},
          loggedAt: testLoggedAt,
        );

        final log2 = CostEstimationLog(
          id: 'log-123',
          estimateId: 'estimate-456',
          activity: CostEstimationActivityType.costItemAdded,
          user: testUser,
          activityDetails: const {'costItemId': 'item-2'},
          loggedAt: testLoggedAt,
        );

        expect(log1, isNot(equals(log2)));
      });
    });
  });
}
