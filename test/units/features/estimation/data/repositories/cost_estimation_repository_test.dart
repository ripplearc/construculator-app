import 'dart:async';
import 'package:construculator/features/estimation/data/repositories/cost_estimation_repository_impl.dart';
import 'package:construculator/features/estimation/data/testing/fake_cost_estimation_data_source.dart';
import 'package:construculator/features/estimation/domain/entities/enums.dart';
import 'package:construculator/features/estimation/domain/entities/lock_status_entity.dart';
import 'package:construculator/features/estimation/domain/entities/markup_configuration_entity.dart';
import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Test constants
  const String testProjectId = 'test-project-123';
  const String otherProjectId = 'other-project-456';
  const String estimateId1 = 'estimate-1';
  const String estimateId2 = 'estimate-2';
  const String estimateId3 = 'estimate-3';
  const String userId1 = 'user-123';
  const String userId2 = 'user-456';
  const String estimateName1 = 'Initial Estimate';
  const String estimateName2 = 'Revised Estimate';
  const String estimateName3 = 'Final Estimate';
  const String estimateDesc1 = 'First cost estimate for the project';
  const String estimateDesc2 = 'Updated cost estimate with changes';
  const String estimateDesc3 = 'Final cost estimate';
  const String errorMsgServer = 'Server error occurred';
  const String errorMsgTimeout = 'Request timeout';
  const double totalCost1 = 100000.0;
  const double totalCost2 = 150000.0;
  const double totalCost3 = 200000.0;
  const String timestamp1 = '2024-01-01T10:00:00.000Z';
  const String timestamp2 = '2024-01-02T14:30:00.000Z';
  const String timestamp3 = '2024-01-03T09:15:00.000Z';

  group('CostEstimationRepositoryImpl', () {
    late CostEstimationRepositoryImpl repository;
    late FakeCostEstimationDataSource fakeDataSource;
    late FakeClockImpl fakeClock;

    setUp(() {
      fakeClock = FakeClockImpl();
      fakeDataSource = FakeCostEstimationDataSource(clock: fakeClock);
      repository = CostEstimationRepositoryImpl(dataSource: fakeDataSource);
    });

    tearDown(() {
      fakeDataSource.reset();
    });

    group('getEstimations', () {
      test('should return cost estimates when data exists', () async {
        final estimation1 = fakeDataSource.createSampleEstimation(
          id: estimateId1,
          projectId: testProjectId,
          estimateName: estimateName1,
          estimateDescription: estimateDesc1,
          creatorUserId: userId1,
          totalCost: totalCost1,
          isLocked: false,
          createdAt: DateTime.parse(timestamp1),
          updatedAt: DateTime.parse(timestamp1),
        );

        final estimation2 = fakeDataSource.createSampleEstimation(
          id: estimateId2,
          projectId: testProjectId,
          estimateName: estimateName2,
          estimateDescription: estimateDesc2,
          creatorUserId: userId2,
          totalCost: totalCost2,
          isLocked: true,
          lockedByUserID: userId2,
          createdAt: DateTime.parse(timestamp2),
          updatedAt: DateTime.parse(timestamp2),
        );

        fakeDataSource.addProjectEstimations(testProjectId, [
          estimation1,
          estimation2,
        ]);

        final result = await repository.getEstimations(testProjectId);

        expect(result, hasLength(2));

        final firstEstimate = result[0];
        expect(firstEstimate.id, equals(estimateId1));
        expect(firstEstimate.projectId, equals(testProjectId));
        expect(firstEstimate.estimateName, equals(estimateName1));
        expect(firstEstimate.estimateDescription, equals(estimateDesc1));
        expect(firstEstimate.creatorUserId, equals(userId1));
        expect(firstEstimate.totalCost, equals(totalCost1));
        expect(firstEstimate.lockStatus.isLocked, isFalse);
        expect(firstEstimate.createdAt, equals(DateTime.parse(timestamp1)));
        expect(firstEstimate.updatedAt, equals(DateTime.parse(timestamp1)));

        final secondEstimate = result[1];
        expect(secondEstimate.id, equals(estimateId2));
        expect(secondEstimate.projectId, equals(testProjectId));
        expect(secondEstimate.estimateName, equals(estimateName2));
        expect(secondEstimate.estimateDescription, equals(estimateDesc2));
        expect(secondEstimate.creatorUserId, equals(userId2));
        expect(secondEstimate.totalCost, equals(totalCost2));
        expect(secondEstimate.lockStatus.isLocked, isTrue);
        expect(secondEstimate.lockStatus.isLockedBy(userId2), isTrue);
        expect(secondEstimate.createdAt, equals(DateTime.parse(timestamp2)));
        expect(secondEstimate.updatedAt, equals(DateTime.parse(timestamp2)));
      });

      test('should return empty list when no estimations found', () async {
        final result = await repository.getEstimations(testProjectId);

        expect(result, isEmpty);
      });

      test(
        'should return empty list when no estimations for specific project',
        () async {
          final otherProjectEstimation = fakeDataSource.createSampleEstimation(
            id: estimateId1,
            projectId: otherProjectId,
            estimateName: estimateName1,
          );

          fakeDataSource.addProjectEstimations(otherProjectId, [
            otherProjectEstimation,
          ]);

          final result = await repository.getEstimations(testProjectId);

          expect(result, isEmpty);
        },
      );

      test(
        'should correctly convert DTO to domain entity',
        () async {
          final estimation = fakeDataSource.createSampleEstimation(
            id: estimateId1,
            projectId: testProjectId,
            estimateName: estimateName1,
            estimateDescription: estimateDesc1,
            creatorUserId: userId1,
            totalCost: totalCost1,
            isLocked: false,
          );

          fakeDataSource.addProjectEstimations(testProjectId, [estimation]);

          final result = await repository.getEstimations(testProjectId);

          expect(result, hasLength(1));
          final estimate = result.first;

          expect(
            estimate.markupConfiguration.overallType,
            equals(MarkupType.overall),
          );
          expect(
            estimate.markupConfiguration.overallValue.type,
            equals(MarkupValueType.percentage),
          );
          expect(estimate.markupConfiguration.overallValue.value, equals(15.0));

          expect(estimate.markupConfiguration.materialValue, isNotNull);
          expect(
            estimate.markupConfiguration.materialValue!.type,
            equals(MarkupValueType.percentage),
          );
          expect(
            estimate.markupConfiguration.materialValue!.value,
            equals(10.0),
          );

          expect(estimate.markupConfiguration.laborValue, isNotNull);
          expect(
            estimate.markupConfiguration.laborValue!.type,
            equals(MarkupValueType.percentage),
          );
          expect(estimate.markupConfiguration.laborValue!.value, equals(20.0));

          expect(estimate.markupConfiguration.equipmentValue, isNotNull);
          expect(
            estimate.markupConfiguration.equipmentValue!.type,
            equals(MarkupValueType.percentage),
          );
          expect(
            estimate.markupConfiguration.equipmentValue!.value,
            equals(12.0),
          );
        },
      );

      test('should call data source with correct project ID', () async {
        fakeDataSource.addProjectEstimations(testProjectId, []);

        await repository.getEstimations(testProjectId);

        final methodCalls = fakeDataSource.getMethodCallsFor('getEstimations');
        expect(methodCalls, hasLength(1));
        expect(methodCalls.first['projectId'], equals(testProjectId));
      });

      test('should rethrow server exception when data source throws', () async {
        fakeDataSource.shouldThrowOnGetEstimations = true;
        fakeDataSource.getEstimationsExceptionType =
            SupabaseExceptionType.unknown;
        fakeDataSource.getEstimationsErrorMessage = errorMsgServer;

        expect(
          () => repository.getEstimations(testProjectId),
          throwsA(isA<ServerException>()),
        );
      });

      test(
        'should rethrow timeout exception when data source throws timeout',
        () async {
          fakeDataSource.shouldThrowOnGetEstimations = true;
          fakeDataSource.getEstimationsExceptionType =
              SupabaseExceptionType.timeout;
          fakeDataSource.getEstimationsErrorMessage = errorMsgTimeout;

          expect(
            () => repository.getEstimations(testProjectId),
            throwsA(isA<TimeoutException>()),
          );
        },
      );

      test(
        'should rethrow type exception when data source throws type error',
        () async {
          fakeDataSource.shouldThrowOnGetEstimations = true;
          fakeDataSource.getEstimationsExceptionType =
              SupabaseExceptionType.type;
          fakeDataSource.getEstimationsErrorMessage = 'Type error';

          expect(
            () => repository.getEstimations(testProjectId),
            throwsA(isA<TypeError>()),
          );
        },
      );

      test(
        'should handle multiple estimations with different configurations',
        () async {
          final estimation1 = fakeDataSource.createSampleEstimation(
            id: estimateId1,
            projectId: testProjectId,
            estimateName: estimateName1,
            estimateDescription: estimateDesc1,
            creatorUserId: userId1,
            totalCost: totalCost1,
            isLocked: false,
            createdAt: DateTime.parse(timestamp1),
            updatedAt: DateTime.parse(timestamp1),
          );

          final estimation2 = fakeDataSource.createSampleEstimation(
            id: estimateId2,
            projectId: testProjectId,
            estimateName: estimateName2,
            estimateDescription: estimateDesc2,
            creatorUserId: userId2,
            totalCost: totalCost2,
            isLocked: true,
            lockedByUserID: userId2,
            createdAt: DateTime.parse(timestamp2),
            updatedAt: DateTime.parse(timestamp2),
          );

          final estimation3 = fakeDataSource.createSampleEstimation(
            id: estimateId3,
            projectId: testProjectId,
            estimateName: estimateName3,
            estimateDescription: estimateDesc3,
            creatorUserId: userId1,
            totalCost: totalCost3,
            isLocked: false,
            createdAt: DateTime.parse(timestamp3),
            updatedAt: DateTime.parse(timestamp3),
          );

          fakeDataSource.addProjectEstimations(testProjectId, [
            estimation1,
            estimation2,
            estimation3,
          ]);

          final result = await repository.getEstimations(testProjectId);

          expect(result, hasLength(3));

          expect(
            result.every((estimate) => estimate.projectId == testProjectId),
            isTrue,
          );

          final ids = result.map((e) => e.id).toList();
          expect(ids, containsAll([estimateId1, estimateId2, estimateId3]));
          expect(ids.toSet(), hasLength(3));

          final lockedEstimates = result
              .where((e) => e.lockStatus.isLocked)
              .toList();
          final unlockedEstimates = result
              .where((e) => !e.lockStatus.isLocked)
              .toList();
          expect(lockedEstimates, hasLength(1));
          expect(unlockedEstimates, hasLength(2));

          final totalCosts = result.map((e) => e.totalCost).toList();
          expect(totalCosts, containsAll([totalCost1, totalCost2, totalCost3]));
        },
      );

      test(
        'should preserve all domain entity properties during conversion',
        () async {
          final estimation = fakeDataSource.createSampleEstimation(
            id: estimateId1,
            projectId: testProjectId,
            estimateName: estimateName1,
            estimateDescription: estimateDesc1,
            creatorUserId: userId1,
            totalCost: totalCost1,
            isLocked: true,
            lockedByUserID: userId2,
            createdAt: DateTime.parse(timestamp1),
            updatedAt: DateTime.parse(timestamp2),
          );

          fakeDataSource.addProjectEstimations(testProjectId, [estimation]);

          final result = await repository.getEstimations(testProjectId);

          expect(result, hasLength(1));
          final estimate = result.first;

          expect(estimate.id, equals(estimateId1));
          expect(estimate.projectId, equals(testProjectId));
          expect(estimate.estimateName, equals(estimateName1));
          expect(estimate.estimateDescription, equals(estimateDesc1));
          expect(estimate.creatorUserId, equals(userId1));
          expect(estimate.totalCost, equals(totalCost1));
          expect(estimate.createdAt, equals(DateTime.parse(timestamp1)));
          expect(estimate.updatedAt, equals(DateTime.parse(timestamp2)));

          expect(estimate.markupConfiguration, isA<MarkupConfiguration>());
          expect(estimate.markupConfiguration.overallType, isA<MarkupType>());
          expect(estimate.markupConfiguration.overallValue, isA<MarkupValue>());
          expect(
            estimate.markupConfiguration.materialValue,
            isA<MarkupValue>(),
          );
          expect(estimate.markupConfiguration.laborValue, isA<MarkupValue>());
          expect(
            estimate.markupConfiguration.equipmentValue,
            isA<MarkupValue>(),
          );

          expect(estimate.lockStatus, isA<LockStatus>());
          expect(estimate.lockStatus.isLocked, isTrue);
          expect(estimate.lockStatus, isA<LockedStatus>());
        },
      );
    });
  });
}
