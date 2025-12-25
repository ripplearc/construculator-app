import 'dart:async';
import 'package:construculator/features/estimation/data/testing/fake_cost_estimation_repository.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/entities/enums.dart';
import 'package:construculator/features/estimation/domain/entities/lock_status_entity.dart';
import 'package:construculator/features/estimation/domain/entities/markup_configuration_entity.dart';
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
      final testEstimation = fakeRepository.createSampleEstimation(
        projectId: projectId,
      );
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

      fakeRepository.addProjectEstimations(projectId, [
        testEstimation1,
        testEstimation2,
      ]);

      final result = await fakeRepository.getEstimations(projectId);

      expect(result, hasLength(2));
      expect(result[0], equals(testEstimation1));
      expect(result[1], equals(testEstimation2));
    });

    test(
      'getEstimations should return empty list when no estimations exist',
      () async {
        const projectId = 'non-existent-project';

        final result = await fakeRepository.getEstimations(projectId);

        expect(result, isEmpty);
      },
    );

    test(
      'getEstimations should return empty list when shouldReturnEmptyList is true',
      () async {
        const projectId = 'test-project-123';
        final testEstimation = fakeRepository.createSampleEstimation(
          projectId: projectId,
        );
        fakeRepository.addProjectEstimation(projectId, testEstimation);
        fakeRepository.shouldReturnEmptyList = true;

        final result = await fakeRepository.getEstimations(projectId);

        expect(result, isEmpty);
      },
    );

    test(
      'getEstimations should throw ServerException when shouldThrowOnGetEstimations is true',
      () async {
        fakeRepository.shouldThrowOnGetEstimations = true;
        fakeRepository.getEstimationsErrorMessage = 'Custom error message';

        expect(
          () => fakeRepository.getEstimations('any-project-id'),
          throwsA(isA<ServerException>()),
        );
      },
    );

    test(
      'getEstimations should throw TimeoutException when configured with timeout type',
      () async {
        fakeRepository.shouldThrowOnGetEstimations = true;
        fakeRepository.getEstimationsExceptionType =
            SupabaseExceptionType.timeout;
        fakeRepository.getEstimationsErrorMessage = 'Request timeout';

        expect(
          () => fakeRepository.getEstimations('any-project-id'),
          throwsA(isA<TimeoutException>()),
        );
      },
    );

    test(
      'getEstimations should throw TypeError when configured with type exception',
      () async {
        fakeRepository.shouldThrowOnGetEstimations = true;
        fakeRepository.getEstimationsExceptionType = SupabaseExceptionType.type;

        expect(
          () => fakeRepository.getEstimations('any-project-id'),
          throwsA(isA<TypeError>()),
        );
      },
    );

    test('getEstimations should handle delayed operations', () async {
      const projectId = 'test-project-123';
      final testEstimation = fakeRepository.createSampleEstimation(
        projectId: projectId,
      );
      fakeRepository.addProjectEstimation(projectId, testEstimation);
      fakeRepository.shouldDelayOperations = true;
      fakeRepository.completer = Completer();

      final future = fakeRepository.getEstimations(projectId);
      var completed = false;
      future.then((_) => completed = true);
      expect(
        completed,
        isFalse,
        reason: 'Future should not complete before completer is completed',
      );

      fakeRepository.completer!.complete();
      final result = await future;

      expect(result, hasLength(1));
      expect(result.first.id, equals(testEstimation.id));
    });
  });

  group('Test Data Management', () {
    test(
      'addProjectEstimation should add single estimation to existing list',
      () async {
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
      },
    );

    test(
      'clearProjectEstimations should remove specific project estimation data',
      () async {
        const projectId = 'to-be-cleared';
        final testEstimation = fakeRepository.createSampleEstimation(
          projectId: projectId,
        );
        fakeRepository.addProjectEstimation(projectId, testEstimation);

        final result = await fakeRepository.getEstimations(projectId);
        expect(result, hasLength(1));

        fakeRepository.clearProjectEstimations(projectId);

        final clearedResult = await fakeRepository.getEstimations(projectId);
        expect(clearedResult, isEmpty);
      },
    );

    test(
      'clearAllData should remove all estimation data and method calls',
      () async {
        const projectId1 = 'project-1';
        const projectId2 = 'project-2';
        final estimation1 = fakeRepository.createSampleEstimation(
          projectId: projectId1,
        );
        final estimation2 = fakeRepository.createSampleEstimation(
          projectId: projectId2,
        );

        fakeRepository.addProjectEstimation(projectId1, estimation1);
        fakeRepository.addProjectEstimation(projectId2, estimation2);

        await fakeRepository.getEstimations(projectId1);

        expect(fakeRepository.getMethodCalls(), isNotEmpty);
        expect(fakeRepository.getMethodCallsFor('getEstimations'), isNotEmpty);

        fakeRepository.clearAllData();

        expect(fakeRepository.getMethodCalls(), isEmpty);
        expect(await fakeRepository.getEstimations(projectId1), isEmpty);
        expect(await fakeRepository.getEstimations(projectId2), isEmpty);
      },
    );
  });

  group('Method Call Tracking', () {
    test('getMethodCalls should return all method calls', () async {
      const projectId = 'test-project';
      final testEstimation = fakeRepository.createSampleEstimation(
        projectId: projectId,
      );
      fakeRepository.addProjectEstimation(projectId, testEstimation);

      await fakeRepository.getEstimations(projectId);
      await fakeRepository.getEstimations(projectId);

      final allCalls = fakeRepository.getMethodCalls();
      expect(allCalls, hasLength(2));
      expect(
        allCalls.every((call) => call['method'] == 'getEstimations'),
        isTrue,
      );
    });

    test(
      'getLastMethodCall should return the most recent method call',
      () async {
        const projectId1 = 'project-1';
        const projectId2 = 'project-2';
        final estimation1 = fakeRepository.createSampleEstimation(
          projectId: projectId1,
        );
        final estimation2 = fakeRepository.createSampleEstimation(
          projectId: projectId2,
        );

        fakeRepository.addProjectEstimation(projectId1, estimation1);
        fakeRepository.addProjectEstimation(projectId2, estimation2);

        await fakeRepository.getEstimations(projectId1);
        await fakeRepository.getEstimations(projectId2);

        final lastCall = fakeRepository.getLastMethodCall();
        expect(lastCall, isNotNull);
        expect(lastCall!['method'], equals('getEstimations'));
        expect(lastCall['projectId'], equals(projectId2));
      },
    );

    test('getLastMethodCall should return null when no calls made', () {
      final lastCall = fakeRepository.getLastMethodCall();
      expect(lastCall, isNull);
    });

    test('getMethodCallsFor should return calls for specific method', () async {
      const projectId = 'test-project';
      final testEstimation = fakeRepository.createSampleEstimation(
        projectId: projectId,
      );
      fakeRepository.addProjectEstimation(projectId, testEstimation);

      await fakeRepository.getEstimations(projectId);
      await fakeRepository.getEstimations(projectId);

      final getEstimationsCalls = fakeRepository.getMethodCallsFor(
        'getEstimations',
      );
      expect(getEstimationsCalls, hasLength(2));
      expect(
        getEstimationsCalls.every((call) => call['method'] == 'getEstimations'),
        isTrue,
      );

      final nonExistentCalls = fakeRepository.getMethodCallsFor(
        'nonExistentMethod',
      );
      expect(nonExistentCalls, isEmpty);
    });

    test('clearMethodCalls should remove all method call tracking', () async {
      const projectId = 'test-project';
      final testEstimation = fakeRepository.createSampleEstimation(
        projectId: projectId,
      );
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
      final testEstimation = fakeRepository.createSampleEstimation(
        projectId: projectId,
      );
      fakeRepository.addProjectEstimation(projectId, testEstimation);
      await fakeRepository.getEstimations(projectId);
      fakeRepository.shouldThrowOnGetEstimations = true;
      fakeRepository.getEstimationsErrorMessage = 'Test error';
      fakeRepository.getEstimationsExceptionType =
          SupabaseExceptionType.timeout;
      fakeRepository.shouldReturnEmptyList = true;
      fakeRepository.shouldDelayOperations = true;
      fakeRepository.completer = Completer();
      fakeRepository.completer!.complete();

      expect(fakeRepository.shouldThrowOnGetEstimations, isTrue);
      expect(fakeRepository.getEstimationsErrorMessage, equals('Test error'));
      expect(
        fakeRepository.getEstimationsExceptionType,
        equals(SupabaseExceptionType.timeout),
      );
      expect(fakeRepository.shouldReturnEmptyList, isTrue);
      expect(fakeRepository.shouldDelayOperations, isTrue);
      expect(fakeRepository.completer, isNotNull);
      expect(fakeRepository.getMethodCalls(), isNotEmpty);

      fakeRepository.reset();

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
    test(
      'createSampleEstimation should create estimation with default values',
      () {
        const expectedConfig = MarkupConfiguration(
          overallType: MarkupType.overall,
          overallValue: MarkupValue(
            type: MarkupValueType.percentage,
            value: 15.0,
          ),
        );
        const expectedLockStatus = LockStatus.unlocked();

        final estimation = fakeRepository.createSampleEstimation();

        expect(estimation.id, startsWith('test-estimation-'));
        expect(estimation.projectId, equals('test-project-123'));
        expect(estimation.estimateName, equals('Test Estimation'));
        expect(
          estimation.estimateDescription,
          equals('Test estimation description'),
        );
        expect(estimation.creatorUserId, equals('test-user-123'));
        expect(estimation.totalCost, equals(50000.0));
        expect(estimation.lockStatus, equals(expectedLockStatus));
        expect(estimation.markupConfiguration, equals(expectedConfig));
      },
    );

    test(
      'createSampleEstimation should create estimation with custom values',
      () {
        const customId = 'custom-estimation-id';
        const customProjectId = 'custom-project-id';
        const customName = 'Custom Estimation';
        const customDescription = 'Custom description';
        const customUserId = 'custom-user-id';
        const customTotalCost = 75000.0;
        const customLockedByUserId = 'locked-by-user';
        final customCreatedAt = DateTime(2024, 1, 1);
        final customUpdatedAt = DateTime(2024, 1, 2);

        final expected = CostEstimate(
          id: customId,
          projectId: customProjectId,
          estimateName: customName,
          estimateDescription: customDescription,
          creatorUserId: customUserId,
          totalCost: customTotalCost,
          lockStatus: LockStatus.locked(customLockedByUserId, fakeClock.now()),
          createdAt: customCreatedAt,
          updatedAt: customUpdatedAt,
          markupConfiguration: const MarkupConfiguration(
            overallType: MarkupType.granular,
            overallValue: MarkupValue(
              type: MarkupValueType.percentage,
              value: 15.0,
            ),
            materialValueType: MarkupType.granular,
            materialValue: MarkupValue(
              type: MarkupValueType.percentage,
              value: 10.0,
            ),
            laborValueType: MarkupType.granular,
            laborValue: MarkupValue(
              type: MarkupValueType.percentage,
              value: 20.0,
            ),
            equipmentValueType: MarkupType.granular,
            equipmentValue: MarkupValue(
              type: MarkupValueType.percentage,
              value: 12.0,
            ),
          ),
        );

        final actual = fakeRepository.createSampleEstimation(
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

        expect(actual, equals(expected));
      },
    );

    test(
      'createSampleOverallMarkupEstimation should create estimation with overall markup',
      () {
        const customOverallMarkup = 25.0;
        const expectedConfig = MarkupConfiguration(
          overallType: MarkupType.overall,
          overallValue: MarkupValue(
            type: MarkupValueType.percentage,
            value: customOverallMarkup,
          ),
        );

        final estimation = fakeRepository.createSampleOverallMarkupEstimation(
          overallMarkupValue: customOverallMarkup,
        );

        expect(estimation.markupConfiguration, equals(expectedConfig));
      },
    );

    test(
      'createSampleGranularMarkupEstimation should create estimation with granular markup',
      () {
        const customMaterialMarkup = 8.0;
        const customLaborMarkup = 18.0;
        const customEquipmentMarkup = 12.0;
        const expectedConfig = MarkupConfiguration(
          overallType: MarkupType.granular,
          overallValue: MarkupValue(
            type: MarkupValueType.percentage,
            value: 15.0,
          ),
          materialValueType: MarkupType.granular,
          materialValue: MarkupValue(
            type: MarkupValueType.percentage,
            value: customMaterialMarkup,
          ),
          laborValueType: MarkupType.granular,
          laborValue: MarkupValue(
            type: MarkupValueType.percentage,
            value: customLaborMarkup,
          ),
          equipmentValueType: MarkupType.granular,
          equipmentValue: MarkupValue(
            type: MarkupValueType.percentage,
            value: customEquipmentMarkup,
          ),
        );

        final estimation = fakeRepository.createSampleGranularMarkupEstimation(
          materialMarkupValue: customMaterialMarkup,
          laborMarkupValue: customLaborMarkup,
          equipmentMarkupValue: customEquipmentMarkup,
        );

        expect(estimation.markupConfiguration, equals(expectedConfig));
      },
    );

    test(
      'createSampleEstimation with granular markup should set all granular values',
      () {
        const expectedConfig = MarkupConfiguration(
          overallType: MarkupType.granular,
          overallValue: MarkupValue(
            type: MarkupValueType.percentage,
            value: 15.0,
          ),
          materialValueType: MarkupType.granular,
          materialValue: MarkupValue(
            type: MarkupValueType.percentage,
            value: 10.0,
          ),
          laborValueType: MarkupType.granular,
          laborValue: MarkupValue(
            type: MarkupValueType.percentage,
            value: 20.0,
          ),
          equipmentValueType: MarkupType.granular,
          equipmentValue: MarkupValue(
            type: MarkupValueType.percentage,
            value: 12.0,
          ),
        );

        final estimation = fakeRepository.createSampleEstimation(
          markupType: MarkupType.granular,
        );

        expect(estimation.markupConfiguration, equals(expectedConfig));
      },
    );

    test(
      'createSampleEstimation should create locked estimation when isLocked is true',
      () {
        const lockedByUserId = 'lock-user-123';
        final expectedLockStatus = LockStatus.locked(
          lockedByUserId,
          fakeClock.now(),
        );

        final estimation = fakeRepository.createSampleEstimation(
          isLocked: true,
          lockedByUserID: lockedByUserId,
        );

        expect(estimation.lockStatus, equals(expectedLockStatus));
      },
    );

    test(
      'createSampleEstimation should create unlocked estimation when isLocked is false',
      () {
        const expectedLockStatus = LockStatus.unlocked();

        final estimation = fakeRepository.createSampleEstimation(
          isLocked: false,
          lockedByUserID: 'some-user',
        );

        expect(estimation.lockStatus, equals(expectedLockStatus));
      },
    );

    test(
      'createSampleEstimation should create unlocked estimation when lockedByUserID is null',
      () {
        const expectedLockStatus = LockStatus.unlocked();

        final estimation = fakeRepository.createSampleEstimation(
          isLocked: true,
          lockedByUserID: null,
        );

        expect(estimation.lockStatus, equals(expectedLockStatus));
      },
    );
  });
}
