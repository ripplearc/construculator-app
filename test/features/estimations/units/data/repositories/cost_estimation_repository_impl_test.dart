import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/data/models/cost_estimate_dto.dart';
import 'package:construculator/features/estimation/data/repositories/cost_estimation_repository_impl.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/estimation_test_data_map_factory.dart';

void main() {
  const String otherProjectId = 'other-project-456';
  const String estimateId2 = 'estimate-2';
  const String estimateId3 = 'estimate-3';
  const String userId2 = 'user-456';
  const String estimateName2 = 'Revised Estimate';
  const String estimateName3 = 'Final Estimate';
  const String estimateDesc2 = 'Updated cost estimate with changes';
  const String estimateDesc3 = 'Final cost estimate';
  const String errorMsgServer = 'Server error occurred';
  const String errorMsgTimeout = 'Request timeout';
  const double totalCost2 = 150000.0;
  const double totalCost3 = 200000.0;
  const String timestamp2 = '2024-01-02T14:30:00.000Z';
  const String timestamp3 = '2024-01-03T09:15:00.000Z';

  group('CostEstimationRepositoryImpl', () {
    late CostEstimationRepositoryImpl repository;
    late FakeSupabaseWrapper fakeSupabaseWrapper;
    late FakeClockImpl fakeClock;

    setUpAll(() {
      fakeClock = FakeClockImpl();
      Modular.init(
        EstimationModule(
          AppBootstrap(
            supabaseWrapper: FakeSupabaseWrapper(clock: fakeClock),
            config: FakeAppConfig(),
            envLoader: FakeEnvLoader(),
          ),
        ),
      );
      fakeSupabaseWrapper =
          Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
      repository =
          Modular.get<CostEstimationRepository>()
              as CostEstimationRepositoryImpl;
    });

    tearDownAll(() {
      Modular.dispose();
    });

    setUp(() {
      repository.dispose();
      fakeSupabaseWrapper.reset();
    });

    Map<String, dynamic> buildEstimationMap({
      String? id,
      String? projectId,
      String? estimateName,
      String? estimateDescription,
      String? creatorUserId,
      double? totalCost,
      bool? isLocked,
      String? lockedByUserId,
      String? lockedAt,
      String? createdAt,
      String? updatedAt,
    }) {
      return EstimationTestDataMapFactory.createFakeEstimationData(
        id: id,
        projectId: projectId,
        estimateName: estimateName,
        estimateDescription: estimateDescription,
        creatorUserId: creatorUserId,
        totalCost: totalCost,
        isLocked: isLocked,
        lockedByUserId: lockedByUserId,
        lockedAt: lockedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    }

    CostEstimateDto buildEstimationDto({
      String? id,
      String? projectId,
      String? estimateName,
      String? estimateDescription,
      String? creatorUserId,
      double? totalCost,
      bool? isLocked,
      String? lockedByUserId,
      String? lockedAt,
      String? createdAt,
      String? updatedAt,
    }) {
      final map = buildEstimationMap(
        id: id,
        projectId: projectId,
        estimateName: estimateName,
        estimateDescription: estimateDescription,
        creatorUserId: creatorUserId,
        totalCost: totalCost,
        isLocked: isLocked,
        lockedByUserId: lockedByUserId,
        lockedAt: lockedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      return CostEstimateDto.fromJson(map);
    }

    void seedEstimationTable(List<Map<String, dynamic>> rows) {
      fakeSupabaseWrapper.addTableData(
        DatabaseConstants.costEstimatesTable,
        rows,
      );
    }

    group('getEstimations', () {
      test('should return cost estimates when data exists', () async {
        final estimationMap1 = buildEstimationMap(
          id: estimateId2,
          projectId: testProjectId,
          estimateName: estimateName2,
          estimateDescription: estimateDesc2,
          creatorUserId: userId2,
          totalCost: totalCost2,
          isLocked: true,
          lockedByUserId: userId2,
          lockedAt: timestamp2,
          createdAt: timestamp2,
          updatedAt: timestamp2,
        );

        final estimationMap2 = buildEstimationMap(
          id: estimateIdDefault,
          projectId: testProjectId,
          estimateName: estimateNameDefault,
          estimateDescription: estimateDescDefault,
          creatorUserId: userIdDefault,
          totalCost: totalCostDefault,
          isLocked: false,
          createdAt: timestampDefault,
          updatedAt: timestampDefault,
        );

        final estimation1 = CostEstimateDto.fromJson(estimationMap1);
        final estimation2 = CostEstimateDto.fromJson(estimationMap2);

        seedEstimationTable([estimationMap1, estimationMap2]);

        final result = await repository.getEstimations(testProjectId);

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected success but got failure'), (
          estimates,
        ) {
          expect(estimates, hasLength(2));
          expect(estimates[0], equals(estimation1.toDomain()));
          expect(estimates[1], equals(estimation2.toDomain()));
        });
      });

      test('should return empty list when no estimations found', () async {
        final result = await repository.getEstimations(testProjectId);

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected success but got failure'),
          (estimates) => expect(estimates, isEmpty),
        );
      });

      test(
        'should return empty list when no estimations for specific project',
        () async {
          final otherProjectEstimationMap = buildEstimationMap(
            id: estimateIdDefault,
            projectId: otherProjectId,
            estimateName: estimateNameDefault,
          );

          seedEstimationTable([otherProjectEstimationMap]);

          final result = await repository.getEstimations(testProjectId);

          expect(result.isRight(), isTrue);
          result.fold(
            (_) => fail('Expected success but got failure'),
            (estimates) => expect(estimates, isEmpty),
          );
        },
      );

      test('should call supabaseWrapper with correct project ID', () async {
        seedEstimationTable([]);

        await repository.getEstimations(testProjectId);

        final methodCalls = fakeSupabaseWrapper.getMethodCallsFor(
          'selectPaginated',
        );
        expect(methodCalls, hasLength(1));
        expect(
          methodCalls.first['table'],
          equals(DatabaseConstants.costEstimatesTable),
        );
        expect(
          methodCalls.first['filterColumn'],
          equals(DatabaseConstants.projectIdColumn),
        );
        expect(methodCalls.first['filterValue'], equals(testProjectId));
      });

      test(
        'should return unexpected failure when data source throws server exception',
        () async {
          fakeSupabaseWrapper.shouldThrowOnSelectPaginated = true;
          fakeSupabaseWrapper.selectPaginatedExceptionType =
              SupabaseExceptionType.unknown;
          fakeSupabaseWrapper.selectPaginatedErrorMessage = errorMsgServer;

          final result = await repository.getEstimations(testProjectId);

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, UnexpectedFailure()),
            (_) => fail('Expected failure but got success'),
          );
        },
      );

      test(
        'should return timeout error when data source throws timeout',
        () async {
          fakeSupabaseWrapper.shouldThrowOnSelectPaginated = true;
          fakeSupabaseWrapper.selectPaginatedExceptionType =
              SupabaseExceptionType.timeout;
          fakeSupabaseWrapper.selectPaginatedErrorMessage = errorMsgTimeout;

          final result = await repository.getEstimations(testProjectId);

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(
              failure,
              EstimationFailure(errorType: EstimationErrorType.timeoutError),
            ),
            (_) => fail('Expected failure but got success'),
          );
        },
      );

      test(
        'should return connection error when data source throws SocketException',
        () async {
          fakeSupabaseWrapper.shouldThrowOnSelectPaginated = true;
          fakeSupabaseWrapper.selectPaginatedExceptionType =
              SupabaseExceptionType.socket;
          fakeSupabaseWrapper.selectPaginatedErrorMessage = 'Connection failed';

          final result = await repository.getEstimations(testProjectId);

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(
              failure,
              EstimationFailure(errorType: EstimationErrorType.connectionError),
            ),
            (_) => fail('Expected failure but got success'),
          );
        },
      );

      test(
        'should return parsing error when data source throws FormatException',
        () async {
          fakeSupabaseWrapper.selectPaginatedErrorMessage = 'Format error';
          fakeSupabaseWrapper.selectPaginatedExceptionType =
              SupabaseExceptionType.type;
          fakeSupabaseWrapper.shouldThrowOnSelectPaginated = true;

          final result = await repository.getEstimations(testProjectId);

          expect(result.isLeft(), isTrue);
          result.fold((failure) {
            expect(
              failure,
              EstimationFailure(errorType: EstimationErrorType.parsingError),
            );
          }, (_) => fail('Expected failure but got success'));
        },
      );

      test(
        'should return connection error when data source throws PostgrestException with connection failure',
        () async {
          fakeSupabaseWrapper.shouldThrowOnSelectPaginated = true;
          fakeSupabaseWrapper.selectPaginatedExceptionType =
              SupabaseExceptionType.postgrest;
          fakeSupabaseWrapper.postgrestErrorCode =
              PostgresErrorCode.connectionFailure;
          fakeSupabaseWrapper.selectPaginatedErrorMessage = 'Connection lost';

          final result = await repository.getEstimations(testProjectId);

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(
              failure,
              EstimationFailure(errorType: EstimationErrorType.connectionError),
            ),
            (_) => fail('Expected failure but got success'),
          );
        },
      );

      test(
        'should return unexpected database error when data source throws PostgrestException with unique violation',
        () async {
          fakeSupabaseWrapper.shouldThrowOnSelectPaginated = true;
          fakeSupabaseWrapper.selectPaginatedExceptionType =
              SupabaseExceptionType.postgrest;
          fakeSupabaseWrapper.postgrestErrorCode =
              PostgresErrorCode.uniqueViolation;
          fakeSupabaseWrapper.selectPaginatedErrorMessage = 'Unique violation';

          final result = await repository.getEstimations(testProjectId);

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(
              failure,
              EstimationFailure(
                errorType: EstimationErrorType.unexpectedDatabaseError,
              ),
            ),
            (_) => fail('Expected failure but got success'),
          );
        },
      );

      test(
        'should handle multiple estimations with different configurations',
        () async {
          final estimationMap1 = buildEstimationMap(
            id: estimateId3,
            projectId: testProjectId,
            estimateName: estimateName3,
            estimateDescription: estimateDesc3,
            creatorUserId: userIdDefault,
            totalCost: totalCost3,
            isLocked: false,
            createdAt: timestamp3,
            updatedAt: timestamp3,
          );

          final estimationMap2 = buildEstimationMap(
            id: estimateId2,
            projectId: testProjectId,
            estimateName: estimateName2,
            estimateDescription: estimateDesc2,
            creatorUserId: userId2,
            totalCost: totalCost2,
            isLocked: true,
            lockedByUserId: userId2,
            lockedAt: timestamp2,
            createdAt: timestamp2,
            updatedAt: timestamp2,
          );

          final estimationMap3 = buildEstimationMap(
            id: estimateIdDefault,
            projectId: testProjectId,
            estimateName: estimateNameDefault,
            estimateDescription: estimateDescDefault,
            creatorUserId: userIdDefault,
            totalCost: totalCostDefault,
            isLocked: false,
            createdAt: timestampDefault,
            updatedAt: timestampDefault,
          );

          final estimation1 = CostEstimateDto.fromJson(estimationMap1);
          final estimation2 = CostEstimateDto.fromJson(estimationMap2);
          final estimation3 = CostEstimateDto.fromJson(estimationMap3);

          seedEstimationTable([estimationMap1, estimationMap2, estimationMap3]);

          final result = await repository.getEstimations(testProjectId);

          expect(result.isRight(), isTrue);
          result.fold((_) => fail('Expected success but got failure'), (
            estimates,
          ) {
            expect(estimates, [
              estimation1.toDomain(),
              estimation2.toDomain(),
              estimation3.toDomain(),
            ]);
          });
        },
      );
    });

    group('watchEstimations', () {
      test('should emit estimations when stream is watched', () async {
        final estimationMap = buildEstimationMap(
          id: estimateIdDefault,
          projectId: testProjectId,
          estimateName: estimateNameDefault,
        );
        final estimation1 = CostEstimateDto.fromJson(estimationMap);

        seedEstimationTable([estimationMap]);

        final stream = repository.watchEstimations(testProjectId);

        await expectLater(
          stream,
          emits(
            predicate((dynamic result) {
              if (result is! Either<Failure, List<CostEstimate>>) return false;
              return result.isRight() &&
                  result.fold(
                    (_) => false,
                    (estimations) =>
                        estimations.length == 1 &&
                        estimations[0] == estimation1.toDomain(),
                  );
            }),
          ),
        );
      });

      test('should share stream emissions across multiple listeners', () async {
        seedEstimationTable([]);

        final stream1 = repository.watchEstimations(testProjectId);
        final stream2 = repository.watchEstimations(testProjectId);

        final results1 = <Either<Failure, List<CostEstimate>>>[];
        final results2 = <Either<Failure, List<CostEstimate>>>[];

        stream1.listen(results1.add);
        stream2.listen(results2.add);

        await pumpEventQueue();

        expect(results1, equals(results2));
      });
    });

    group('createEstimation', () {
      test('should return created estimation on success', () async {
        final estimationDto = buildEstimationDto(
          id: estimateIdDefault,
          projectId: testProjectId,
          estimateName: estimateNameDefault,
          estimateDescription: estimateDescDefault,
          creatorUserId: userIdDefault,
          totalCost: totalCostDefault,
          createdAt: timestampDefault,
          updatedAt: timestampDefault,
        );
        final estimation = estimationDto.toDomain();

        final result = await repository.createEstimation(estimation);

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected success but got failure'), (created) {
          final insertTimestamp = fakeClock.now().toIso8601String();
          final createdDto = CostEstimateDto.fromJson({
            ...estimationDto.toJson(),
            'id': '1',
            'created_at': insertTimestamp,
            'updated_at': insertTimestamp,
          });
          expect(created, equals(createdDto.toDomain()));
        });
      });

      test('should call data source with correct estimation', () async {
        final estimationDto = buildEstimationDto(
          projectId: testProjectId,
          estimateName: estimateNameDefault,
          createdAt: timestampDefault,
          updatedAt: timestampDefault,
        );
        final estimation = estimationDto.toDomain();

        await repository.createEstimation(estimation);

        final methodCalls = fakeSupabaseWrapper.getMethodCallsFor('insert');
        expect(methodCalls, hasLength(1));
        expect(
          methodCalls.first['table'],
          equals(DatabaseConstants.costEstimatesTable),
        );
        Map<String, dynamic> estimationJson = methodCalls.first['data'];

        expect(estimationJson, estimationDto.toJson());
      });

      test(
        'should return timeout failure when data source throws timeout',
        () async {
          fakeSupabaseWrapper.shouldThrowOnInsert = true;
          fakeSupabaseWrapper.insertExceptionType =
              SupabaseExceptionType.timeout;
          fakeSupabaseWrapper.insertErrorMessage = errorMsgTimeout;

          final estimationDto = buildEstimationDto(
            createdAt: timestampDefault,
            updatedAt: timestampDefault,
          );
          final estimation = estimationDto.toDomain();

          final result = await repository.createEstimation(estimation);

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(
              failure,
              EstimationFailure(errorType: EstimationErrorType.timeoutError),
            ),
            (_) => fail('Expected failure but got success'),
          );
        },
      );

      test(
        'should return connection failure when data source throws SocketException',
        () async {
          fakeSupabaseWrapper.shouldThrowOnInsert = true;
          fakeSupabaseWrapper.insertExceptionType =
              SupabaseExceptionType.socket;
          fakeSupabaseWrapper.insertErrorMessage = 'Connection failed';

          final estimationDto = buildEstimationDto(
            createdAt: timestampDefault,
            updatedAt: timestampDefault,
          );
          final estimation = estimationDto.toDomain();

          final result = await repository.createEstimation(estimation);

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(
              failure,
              EstimationFailure(errorType: EstimationErrorType.connectionError),
            ),
            (_) => fail('Expected failure but got success'),
          );
        },
      );

      test(
        'should return unexpected failure when data source throws unknown error',
        () async {
          fakeSupabaseWrapper.shouldThrowOnInsert = true;
          fakeSupabaseWrapper.insertExceptionType =
              SupabaseExceptionType.unknown;
          fakeSupabaseWrapper.insertErrorMessage = errorMsgServer;

          final estimationDto = buildEstimationDto(
            createdAt: timestampDefault,
            updatedAt: timestampDefault,
          );
          final estimation = estimationDto.toDomain();

          final result = await repository.createEstimation(estimation);

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, UnexpectedFailure()),
            (_) => fail('Expected failure but got success'),
          );
        },
      );

      test(
        'should update stream with newly created estimation using cached data',
        () async {
          final existingEstimationMap = buildEstimationMap(
            id: estimateIdDefault,
            projectId: testProjectId,
            estimateName: estimateNameDefault,
          );
          final existingEstimation = CostEstimateDto.fromJson(
            existingEstimationMap,
          );

          seedEstimationTable([existingEstimationMap]);

          final stream = repository.watchEstimations(testProjectId);
          final streamResults = <Either<Failure, List<CostEstimate>>>[];

          final subscription = stream.listen(streamResults.add);

          await pumpEventQueue();

          expect(streamResults.length, equals(1));
          expect(
            streamResults[0].fold(
              (_) => 0,
              (estimations) => estimations.length,
            ),
            equals(1),
          );

          final newEstimationDto = buildEstimationDto(
            id: estimateId2,
            projectId: testProjectId,
            estimateName: estimateName2,
            createdAt: timestampDefault,
            updatedAt: timestampDefault,
          );
          final newEstimation = newEstimationDto.toDomain();

          await repository.createEstimation(newEstimation);

          await pumpEventQueue();

          expect(streamResults.length, equals(2));
          expect(
            streamResults[1].fold(
              (_) => 0,
              (estimations) => estimations.length,
            ),
            equals(2),
          );

          streamResults[1].fold(
            (_) => fail('Expected success but got failure'),
            (estimations) {
              final insertTimestamp = fakeClock.now().toIso8601String();
              final createdDto = CostEstimateDto.fromJson({
                ...newEstimationDto.toJson(),
                'id': '2',
                'created_at': insertTimestamp,
                'updated_at': insertTimestamp,
              });
              expect(estimations[0], equals(existingEstimation.toDomain()));
              expect(estimations[1], equals(createdDto.toDomain()));
            },
          );

          await subscription.cancel();
        },
      );
    });

    group('dispose', () {
      test('should close all stream controllers and clear caches', () async {
        seedEstimationTable([]);

        repository.watchEstimations(testProjectId);
        repository.watchEstimations(otherProjectId);

        repository.dispose();

        expect(
          () => repository.watchEstimations(testProjectId),
          returnsNormally,
        );
      });

      test('should not throw when disposing with no active streams', () {
        expect(() => repository.dispose(), returnsNormally);
      });

      test(
        'should close stream controllers that are not already closed',
        () async {
          seedEstimationTable([]);

          final stream = repository.watchEstimations(testProjectId);
          final subscription = stream.listen((_) {});

          await pumpEventQueue();

          repository.dispose();

          await subscription.cancel();

          expect(() => repository.dispose(), returnsNormally);
        },
      );
    });

    group('deleteEstimation', () {
      test('should return Right(null) when deletion is successful', () async {
        final estimationMap = buildEstimationMap(
          id: estimateIdDefault,
          projectId: testProjectId,
        );
        seedEstimationTable([estimationMap]);

        final result = await repository.deleteEstimation(
          estimateIdDefault,
          testProjectId,
        );

        expect(result.isRight(), isTrue);
      });

      test(
        'should return notFoundError when data source throws PGRST116',
        () async {
          fakeSupabaseWrapper.shouldThrowOnDelete = true;
          fakeSupabaseWrapper.deleteExceptionType =
              SupabaseExceptionType.postgrest;
          fakeSupabaseWrapper.postgrestErrorCode =
              PostgresErrorCode.noDataFound;
          fakeSupabaseWrapper.deleteErrorMessage = 'No data found';

          final result = await repository.deleteEstimation(
            estimateIdDefault,
            testProjectId,
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(
              failure,
              EstimationFailure(errorType: EstimationErrorType.notFoundError),
            ),
            (_) => fail('Expected failure but got success'),
          );
        },
      );

      test('should call data source with correct estimation ID', () async {
        await repository.deleteEstimation(estimateIdDefault, testProjectId);

        final methodCalls = fakeSupabaseWrapper.getMethodCallsFor('delete');
        expect(methodCalls, hasLength(1));
        expect(
          methodCalls.first['table'],
          equals(DatabaseConstants.costEstimatesTable),
        );
        expect(methodCalls.first['filterColumn'], equals('id'));
        expect(methodCalls.first['filterValue'], equals(estimateIdDefault));
      });

      test(
        'should update stream optimistically by removing deleted estimation',
        () async {
          final estimationMap1 = buildEstimationMap(
            id: estimateIdDefault,
            projectId: testProjectId,
          );
          final estimationMap2 = buildEstimationMap(
            id: estimateId2,
            projectId: testProjectId,
          );
          final estimation2 = CostEstimateDto.fromJson(estimationMap2);
          seedEstimationTable([estimationMap1, estimationMap2]);

          final stream = repository.watchEstimations(testProjectId);
          final updates = <Either<Failure, List<CostEstimate>>>[];

          stream.listen((event) {
            updates.add(event);
          });

          await pumpEventQueue();

          final result = await repository.deleteEstimation(
            estimateIdDefault,
            testProjectId,
          );

          expect(result.isRight(), isTrue);

          await pumpEventQueue();

          expect(updates, isNotEmpty);
          final lastUpdate = updates.last;
          lastUpdate.fold((_) => fail('Expected success but got failure'), (
            estimations,
          ) {
            expect(estimations, hasLength(1));
            expect(estimations, equals([estimation2.toDomain()]));
          });

          repository.dispose();
        },
      );

      test('should timeout failure when data source throws timeout', () async {
        fakeSupabaseWrapper.shouldThrowOnDelete = true;
        fakeSupabaseWrapper.deleteExceptionType = SupabaseExceptionType.timeout;
        fakeSupabaseWrapper.deleteErrorMessage = errorMsgTimeout;

        final result = await repository.deleteEstimation(
          estimateIdDefault,
          testProjectId,
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(
            failure,
            EstimationFailure(errorType: EstimationErrorType.timeoutError),
          ),
          (_) => fail('Expected failure but got success'),
        );
      });

      test(
        'should return connection failure when data source throws SocketException',
        () async {
          fakeSupabaseWrapper.shouldThrowOnDelete = true;
          fakeSupabaseWrapper.deleteExceptionType =
              SupabaseExceptionType.socket;
          fakeSupabaseWrapper.deleteErrorMessage = 'Connection failed';

          final result = await repository.deleteEstimation(
            estimateIdDefault,
            testProjectId,
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(
              failure,
              EstimationFailure(errorType: EstimationErrorType.connectionError),
            ),
            (_) => fail('Expected failure but got success'),
          );
        },
      );

      test(
        'should return unexpected failure when data source throws unknown error',
        () async {
          fakeSupabaseWrapper.shouldThrowOnDelete = true;
          fakeSupabaseWrapper.deleteExceptionType =
              SupabaseExceptionType.unknown;
          fakeSupabaseWrapper.deleteErrorMessage = errorMsgServer;

          final result = await repository.deleteEstimation(
            estimateIdDefault,
            testProjectId,
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, UnexpectedFailure()),
            (_) => fail('Expected failure but got success'),
          );
        },
      );

      test(
        'should return connection error when data source throws PostgrestException with connection failure',
        () async {
          fakeSupabaseWrapper.shouldThrowOnDelete = true;
          fakeSupabaseWrapper.deleteExceptionType =
              SupabaseExceptionType.postgrest;
          fakeSupabaseWrapper.postgrestErrorCode =
              PostgresErrorCode.connectionFailure;
          fakeSupabaseWrapper.deleteErrorMessage = 'Connection lost';

          final result = await repository.deleteEstimation(
            estimateIdDefault,
            testProjectId,
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(
              failure,
              EstimationFailure(errorType: EstimationErrorType.connectionError),
            ),
            (_) => fail('Expected failure but got success'),
          );
        },
      );

      test(
        'should return unexpected database error when data source throws PostgrestException with other error',
        () async {
          fakeSupabaseWrapper.shouldThrowOnDelete = true;
          fakeSupabaseWrapper.deleteExceptionType =
              SupabaseExceptionType.postgrest;
          fakeSupabaseWrapper.postgrestErrorCode =
              PostgresErrorCode.uniqueViolation;
          fakeSupabaseWrapper.deleteErrorMessage = 'Database error';

          final result = await repository.deleteEstimation(
            estimateIdDefault,
            testProjectId,
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(
              failure,
              EstimationFailure(
                errorType: EstimationErrorType.unexpectedDatabaseError,
              ),
            ),
            (_) => fail('Expected failure but got success'),
          );
        },
      );
    });
  });
}
