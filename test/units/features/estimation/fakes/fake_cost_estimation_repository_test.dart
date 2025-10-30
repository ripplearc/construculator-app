import 'dart:async';
import 'package:construculator/features/estimation/data/testing/fake_cost_estimation_repository.dart';
import 'package:construculator/features/estimation/domain/entities/enums.dart';
import 'package:construculator/features/estimation/domain/entities/lock_status_entity.dart';
import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeCostEstimationRepository fakeRepository;
  late FakeClockImpl fakeClock;

  setUp(() {
    fakeClock = FakeClockImpl(DateTime(2024, 1, 15, 10, 30, 0));
    fakeRepository = FakeCostEstimationRepository(clock: fakeClock);
  });

  tearDown(() {
    fakeRepository.reset();
  });

  group('Estimation Retrieval', () {
    test('getEstimations should track method calls', () async {
      const projectId = 'test-project-123';
      final testEstimation = fakeRepository.createSampleEstimation(projectId: projectId);
      fakeRepository.addProjectEstimation(projectId, testEstimation);

      expect(fakeRepository.getMethodCallsFor('getEstimations'), isEmpty);

      await fakeRepository.getEstimations(projectId);

      final calls = fakeRepository.getMethodCallsFor('getEstimations');
      expect(calls, hasLength(1));
      expect(calls.first['projectId'], equals(projectId));
    });

    test('getEstimations should return estimations when they exist', () async {
      const projectId = 'test-project-123';
      final testEstimation1 = fakeRepository.createSampleEstimation(
        id: 'estimation-1',
        projectId: projectId,
        estimateName: 'Test Estimation 1',
        totalCost: 10000.0,
      );
      final testEstimation2 = fakeRepository.createSampleEstimation(
        id: 'estimation-2',
        projectId: projectId,
        estimateName: 'Test Estimation 2',
        totalCost: 20000.0,
      );
      
      fakeRepository.addProjectEstimations(projectId, [testEstimation1, testEstimation2]);

      final result = await fakeRepository.getEstimations(projectId);

      expect(result, hasLength(2));
      expect(result[0].id, equals('estimation-1'));
      expect(result[0].estimateName, equals('Test Estimation 1'));
      expect(result[0].totalCost, equals(10000.0));
      expect(result[1].id, equals('estimation-2'));
      expect(result[1].estimateName, equals('Test Estimation 2'));
      expect(result[1].totalCost, equals(20000.0));
    });

    test('getEstimations should return empty list when no estimations exist', () async {
      const projectId = 'non-existent-project';

      final result = await fakeRepository.getEstimations(projectId);

      expect(result, isEmpty);
    });

    test('getEstimations should return empty list when shouldReturnEmptyList is true', () async {
      const projectId = 'test-project-123';
      final testEstimation = fakeRepository.createSampleEstimation(projectId: projectId);
      fakeRepository.addProjectEstimation(projectId, testEstimation);
      fakeRepository.shouldReturnEmptyList = true;

      final result = await fakeRepository.getEstimations(projectId);

      expect(result, isEmpty);
    });

    test('getEstimations should throw ServerException when shouldThrowOnGetEstimations is true', () async {
      fakeRepository.shouldThrowOnGetEstimations = true;
      fakeRepository.getEstimationsErrorMessage = 'Custom error message';

      expect(
        () => fakeRepository.getEstimations('any-project-id'),
        throwsA(isA<ServerException>()),
      );
    });

    test('getEstimations should throw TimeoutException when configured with timeout type', () async {
      fakeRepository.shouldThrowOnGetEstimations = true;
      fakeRepository.getEstimationsExceptionType = SupabaseExceptionType.timeout;
      fakeRepository.getEstimationsErrorMessage = 'Request timeout';

      expect(
        () => fakeRepository.getEstimations('any-project-id'),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('getEstimations should throw TypeError when configured with type exception', () async {
      fakeRepository.shouldThrowOnGetEstimations = true;
      fakeRepository.getEstimationsExceptionType = SupabaseExceptionType.type;

      expect(
        () => fakeRepository.getEstimations('any-project-id'),
        throwsA(isA<TypeError>()),
      );
    });

    test('getEstimations should handle delayed operations', () async {
      const projectId = 'test-project-123';
      final testEstimation = fakeRepository.createSampleEstimation(projectId: projectId);
      fakeRepository.addProjectEstimation(projectId, testEstimation);
      fakeRepository.shouldDelayOperations = true;
      fakeRepository.completer = Completer();

      final future = fakeRepository.getEstimations(projectId);
      
      // Verify the operation is delayed by checking it doesn't complete immediately
      bool completedImmediately = false;
      future.then((_) => completedImmediately = true);
      await Future.delayed(Duration(milliseconds: 10));
      expect(completedImmediately, isFalse);

      // Complete the operation
      fakeRepository.completer!.complete();
      final result = await future;

      expect(result, hasLength(1));
      expect(result.first.id, equals(testEstimation.id));
    });
  });

  group('Test Data Management', () {
    test('addProjectEstimations should store estimation data for retrieval', () async {
      const projectId = 'stored-project';
      final testEstimation1 = fakeRepository.createSampleEstimation(
        id: 'estimation-1',
        projectId: projectId,
        estimateName: 'Stored Estimation 1',
        totalCost: 15000.0,
      );
      final testEstimation2 = fakeRepository.createSampleEstimation(
        id: 'estimation-2',
        projectId: projectId,
        estimateName: 'Stored Estimation 2',
        totalCost: 25000.0,
      );

      fakeRepository.addProjectEstimations(projectId, [testEstimation1, testEstimation2]);

      final result = await fakeRepository.getEstimations(projectId);
      expect(result, hasLength(2));
      expect(result[0].estimateName, equals('Stored Estimation 1'));
      expect(result[0].totalCost, equals(15000.0));
      expect(result[1].estimateName, equals('Stored Estimation 2'));
      expect(result[1].totalCost, equals(25000.0));
    });

    test('addProjectEstimation should add single estimation to existing list', () async {
      const projectId = 'test-project';
      final existingEstimation = fakeRepository.createSampleEstimation(
        id: 'existing-estimation',
        projectId: projectId,
      );
      final newEstimation = fakeRepository.createSampleEstimation(
        id: 'new-estimation',
        projectId: projectId,
      );

      fakeRepository.addProjectEstimation(projectId, existingEstimation);
      fakeRepository.addProjectEstimation(projectId, newEstimation);

      final result = await fakeRepository.getEstimations(projectId);
      expect(result, hasLength(2));
      expect(result.any((e) => e.id == 'existing-estimation'), isTrue);
      expect(result.any((e) => e.id == 'new-estimation'), isTrue);
    });

    test('clearProjectEstimations should remove specific project estimation data', () async {
      const projectId = 'to-be-cleared';
      final testEstimation = fakeRepository.createSampleEstimation(projectId: projectId);
      fakeRepository.addProjectEstimation(projectId, testEstimation);

      // Verify estimation exists
      final result = await fakeRepository.getEstimations(projectId);
      expect(result, hasLength(1));

      // Clear the estimations
      fakeRepository.clearProjectEstimations(projectId);

      // Verify estimations are cleared
      final clearedResult = await fakeRepository.getEstimations(projectId);
      expect(clearedResult, isEmpty);
    });

    test('clearAllData should remove all estimation data and method calls', () async {
      const projectId1 = 'project-1';
      const projectId2 = 'project-2';
      final estimation1 = fakeRepository.createSampleEstimation(projectId: projectId1);
      final estimation2 = fakeRepository.createSampleEstimation(projectId: projectId2);
      
      fakeRepository.addProjectEstimation(projectId1, estimation1);
      fakeRepository.addProjectEstimation(projectId2, estimation2);
      
      // Make some method calls
      await fakeRepository.getEstimations(projectId1);

      expect(fakeRepository.getMethodCalls(), isNotEmpty);
      expect(fakeRepository.getMethodCallsFor('getEstimations'), isNotEmpty);

      fakeRepository.clearAllData();

      expect(fakeRepository.getMethodCalls(), isEmpty);
      expect(await fakeRepository.getEstimations(projectId1), isEmpty);
      expect(await fakeRepository.getEstimations(projectId2), isEmpty);
    });
  });

  group('Method Call Tracking', () {
    test('getMethodCalls should return all method calls', () async {
      const projectId = 'test-project';
      final testEstimation = fakeRepository.createSampleEstimation(projectId: projectId);
      fakeRepository.addProjectEstimation(projectId, testEstimation);

      await fakeRepository.getEstimations(projectId);
      await fakeRepository.getEstimations(projectId);

      final allCalls = fakeRepository.getMethodCalls();
      expect(allCalls, hasLength(2));
      expect(allCalls.every((call) => call['method'] == 'getEstimations'), isTrue);
    });

    test('getLastMethodCall should return the most recent method call', () async {
      const projectId1 = 'project-1';
      const projectId2 = 'project-2';
      final estimation1 = fakeRepository.createSampleEstimation(projectId: projectId1);
      final estimation2 = fakeRepository.createSampleEstimation(projectId: projectId2);
      
      fakeRepository.addProjectEstimation(projectId1, estimation1);
      fakeRepository.addProjectEstimation(projectId2, estimation2);

      await fakeRepository.getEstimations(projectId1);
      await fakeRepository.getEstimations(projectId2);

      final lastCall = fakeRepository.getLastMethodCall();
      expect(lastCall, isNotNull);
      expect(lastCall!['method'], equals('getEstimations'));
      expect(lastCall['projectId'], equals(projectId2));
    });

    test('getLastMethodCall should return null when no calls made', () {
      final lastCall = fakeRepository.getLastMethodCall();
      expect(lastCall, isNull);
    });

    test('getMethodCallsFor should return calls for specific method', () async {
      const projectId = 'test-project';
      final testEstimation = fakeRepository.createSampleEstimation(projectId: projectId);
      fakeRepository.addProjectEstimation(projectId, testEstimation);

      await fakeRepository.getEstimations(projectId);
      await fakeRepository.getEstimations(projectId);

      final getEstimationsCalls = fakeRepository.getMethodCallsFor('getEstimations');
      expect(getEstimationsCalls, hasLength(2));
      expect(getEstimationsCalls.every((call) => call['method'] == 'getEstimations'), isTrue);

      final nonExistentCalls = fakeRepository.getMethodCallsFor('nonExistentMethod');
      expect(nonExistentCalls, isEmpty);
    });

    test('clearMethodCalls should remove all method call tracking', () async {
      const projectId = 'test-project';
      final testEstimation = fakeRepository.createSampleEstimation(projectId: projectId);
      fakeRepository.addProjectEstimation(projectId, testEstimation);

      await fakeRepository.getEstimations(projectId);
      expect(fakeRepository.getMethodCalls(), isNotEmpty);

      fakeRepository.clearMethodCalls();
      expect(fakeRepository.getMethodCalls(), isEmpty);
    });
  });

  group('Repository Reset', () {
    test('reset should clear all configurations and data', () async {
      const projectId = 'test-project';
      final testEstimation = fakeRepository.createSampleEstimation(projectId: projectId);
      fakeRepository.addProjectEstimation(projectId, testEstimation);
      fakeRepository.shouldThrowOnGetEstimations = true;
      fakeRepository.getEstimationsErrorMessage = 'Test error';
      fakeRepository.getEstimationsExceptionType = SupabaseExceptionType.timeout;
      fakeRepository.shouldReturnEmptyList = true;
      fakeRepository.shouldDelayOperations = true;
      fakeRepository.completer = Completer();

      // Make a method call (but complete the completer first to avoid hanging)
      fakeRepository.completer!.complete();
      try {
        await fakeRepository.getEstimations(projectId);
      } catch (e) {
        // Ignore exceptions
      }

      // Verify state before reset
      expect(fakeRepository.shouldThrowOnGetEstimations, isTrue);
      expect(fakeRepository.getEstimationsErrorMessage, equals('Test error'));
      expect(fakeRepository.getEstimationsExceptionType, equals(SupabaseExceptionType.timeout));
      expect(fakeRepository.shouldReturnEmptyList, isTrue);
      expect(fakeRepository.shouldDelayOperations, isTrue);
      expect(fakeRepository.completer, isNotNull);
      expect(fakeRepository.getMethodCalls(), isNotEmpty);

      // Reset the repository
      fakeRepository.reset();

      // Verify state after reset
      expect(fakeRepository.shouldThrowOnGetEstimations, isFalse);
      expect(fakeRepository.getEstimationsErrorMessage, isNull);
      expect(fakeRepository.getEstimationsExceptionType, isNull);
      expect(fakeRepository.shouldReturnEmptyList, isFalse);
      expect(fakeRepository.shouldDelayOperations, isFalse);
      expect(fakeRepository.completer, isNull);
      expect(fakeRepository.getMethodCalls(), isEmpty);
      expect(await fakeRepository.getEstimations(projectId), isEmpty);
    });
  });

  group('Sample Estimation Creation', () {
    test('createSampleEstimation should create estimation with default values', () {
      final estimation = fakeRepository.createSampleEstimation();

      expect(estimation.id, startsWith('test-estimation-'));
      expect(estimation.projectId, equals('test-project-123'));
      expect(estimation.estimateName, equals('Test Estimation'));
      expect(estimation.estimateDescription, equals('Test estimation description'));
      expect(estimation.creatorUserId, equals('test-user-123'));
      expect(estimation.totalCost, equals(50000.0));
      expect(estimation.lockStatus, isA<UnlockedStatus>());
      expect(estimation.markupConfiguration.overallType, equals(MarkupType.overall));
      expect(estimation.markupConfiguration.overallValue.value, equals(15.0));
    });

    test('createSampleEstimation should create estimation with custom values', () {
      const customId = 'custom-estimation-id';
      const customProjectId = 'custom-project-id';
      const customName = 'Custom Estimation';
      const customDescription = 'Custom description';
      const customUserId = 'custom-user-id';
      const customTotalCost = 75000.0;
      const customLockedByUserId = 'locked-by-user';
      final customCreatedAt = DateTime(2024, 1, 1);
      final customUpdatedAt = DateTime(2024, 1, 2);

      final estimation = fakeRepository.createSampleEstimation(
        id: customId,
        projectId: customProjectId,
        estimateName: customName,
        estimateDescription: customDescription,
        creatorUserId: customUserId,
        totalCost: customTotalCost,
        isLocked: true,
        lockedByUserID: customLockedByUserId,
        createdAt: customCreatedAt,
        updatedAt: customUpdatedAt,
        markupType: MarkupType.granular,
      );

      expect(estimation.id, equals(customId));
      expect(estimation.projectId, equals(customProjectId));
      expect(estimation.estimateName, equals(customName));
      expect(estimation.estimateDescription, equals(customDescription));
      expect(estimation.creatorUserId, equals(customUserId));
      expect(estimation.totalCost, equals(customTotalCost));
      expect(estimation.lockStatus, isA<LockedStatus>());
      expect(estimation.createdAt, equals(customCreatedAt));
      expect(estimation.updatedAt, equals(customUpdatedAt));
      expect(estimation.markupConfiguration.overallType, equals(MarkupType.granular));
    });

    test('createSampleOverallMarkupEstimation should create estimation with overall markup', () {
      const customOverallMarkup = 25.0;

      final estimation = fakeRepository.createSampleOverallMarkupEstimation(
        overallMarkupValue: customOverallMarkup,
      );

      expect(estimation.markupConfiguration.overallType, equals(MarkupType.overall));
      expect(estimation.markupConfiguration.overallValue.value, equals(customOverallMarkup));
      expect(estimation.markupConfiguration.materialValueType, isNull);
      expect(estimation.markupConfiguration.laborValueType, isNull);
      expect(estimation.markupConfiguration.equipmentValueType, isNull);
    });

    test('createSampleGranularMarkupEstimation should create estimation with granular markup', () {
      const customMaterialMarkup = 8.0;
      const customLaborMarkup = 18.0;
      const customEquipmentMarkup = 12.0;

      final estimation = fakeRepository.createSampleGranularMarkupEstimation(
        materialMarkupValue: customMaterialMarkup,
        laborMarkupValue: customLaborMarkup,
        equipmentMarkupValue: customEquipmentMarkup,
      );

      expect(estimation.markupConfiguration.overallType, equals(MarkupType.granular));
      expect(estimation.markupConfiguration.materialValueType, equals(MarkupType.granular));
      expect(estimation.markupConfiguration.laborValueType, equals(MarkupType.granular));
      expect(estimation.markupConfiguration.equipmentValueType, equals(MarkupType.granular));
      expect(estimation.markupConfiguration.materialValue!.value, equals(customMaterialMarkup));
      expect(estimation.markupConfiguration.laborValue!.value, equals(customLaborMarkup));
      expect(estimation.markupConfiguration.equipmentValue!.value, equals(customEquipmentMarkup));
    });

    test('createSampleEstimation with granular markup should set all granular values', () {
      final estimation = fakeRepository.createSampleEstimation(
        markupType: MarkupType.granular,
      );

      expect(estimation.markupConfiguration.overallType, equals(MarkupType.granular));
      expect(estimation.markupConfiguration.materialValueType, equals(MarkupType.granular));
      expect(estimation.markupConfiguration.laborValueType, equals(MarkupType.granular));
      expect(estimation.markupConfiguration.equipmentValueType, equals(MarkupType.granular));
      expect(estimation.markupConfiguration.materialValue!.value, equals(10.0));
      expect(estimation.markupConfiguration.laborValue!.value, equals(20.0));
      expect(estimation.markupConfiguration.equipmentValue!.value, equals(12.0));
    });

    test('createSampleEstimation should create locked estimation when isLocked is true', () {
      const lockedByUserId = 'lock-user-123';

      final estimation = fakeRepository.createSampleEstimation(
        isLocked: true,
        lockedByUserID: lockedByUserId,
      );

      expect(estimation.lockStatus, isA<LockedStatus>());
      final lockedStatus = estimation.lockStatus as LockedStatus;
      expect(lockedStatus.lockedByUserId, equals(lockedByUserId));
    });

    test('createSampleEstimation should create unlocked estimation when isLocked is false', () {
      final estimation = fakeRepository.createSampleEstimation(
        isLocked: false,
        lockedByUserID: 'some-user',
      );

      expect(estimation.lockStatus, isA<UnlockedStatus>());
    });

    test('createSampleEstimation should create unlocked estimation when lockedByUserID is null', () {
      final estimation = fakeRepository.createSampleEstimation(
        isLocked: true,
        lockedByUserID: null,
      );

      expect(estimation.lockStatus, isA<UnlockedStatus>());
    });
  });
}
