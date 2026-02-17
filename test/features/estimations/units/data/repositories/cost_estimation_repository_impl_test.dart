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

  const int smallDatasetSize = 3;
  const int defaultPageDatasetSize =
      CostEstimationRepositoryImpl.defaultPageSize;
  const int twoPagesDatasetSize = defaultPageDatasetSize * 2;

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

    void expectResult<L, R>(
      Either<L, R> result,
      void Function(R value) assertions,
    ) {
      result.fold((_) => fail('Expected success but got failure'), assertions);
    }

    void expectFailure<L, R>(
      Either<L, R> result,
      void Function(L error) assertions,
    ) {
      result.fold(assertions, (_) => fail('Expected failure but got success'));
    }

    List<Map<String, dynamic>> seedEstimations(
      int count, {
      String projectId = testProjectId,
      bool includeUpdatedAt = false,
    }) {
      final maps = List.generate(
        count,
        (i) => buildEstimationMap(
          id: 'estimate-$i',
          projectId: projectId,
          estimateName: 'Estimate $i',
          createdAt:
              '2026-01-${(i + 1).toString().padLeft(2, '0')}T00:00:00.000Z',
          updatedAt: includeUpdatedAt
              ? '2026-01-${(i + 1).toString().padLeft(2, '0')}T00:00:00.000Z'
              : null,
        ),
      );
      seedEstimationTable(maps);
      return maps;
    }

    List<CostEstimate> mapsToDomainEntities(List<Map<String, dynamic>> maps) {
      return maps
          .map((map) => CostEstimateDto.fromJson(map).toDomain())
          .toList();
    }

    group('fetchInitialEstimations', () {
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

        final result = await repository.fetchInitialEstimations(testProjectId);

        expect(result.isRight(), isTrue);
        expectResult(result, (estimates) {
          expect(estimates, hasLength(2));
          expect(
            estimates,
            equals([estimation1.toDomain(), estimation2.toDomain()]),
          );
        });
      });

      test('should return empty list when no estimations found', () async {
        final result = await repository.fetchInitialEstimations(testProjectId);

        expect(result.isRight(), isTrue);
        expectResult(result, (estimates) => expect(estimates, isEmpty));
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

          final result = await repository.fetchInitialEstimations(
            testProjectId,
          );

          expect(result.isRight(), isTrue);
          expectResult(result, (estimates) => expect(estimates, isEmpty));
        },
      );

      test('should call supabaseWrapper with correct parameters', () async {
        seedEstimationTable([]);

        await repository.fetchInitialEstimations(testProjectId);

        final methodCalls = fakeSupabaseWrapper.getMethodCallsFor(
          'selectPaginated',
        );
        expect(methodCalls, hasLength(1));

        final call = methodCalls.first;
        expect(
          call,
          equals({
            'method': 'selectPaginated',
            'table': DatabaseConstants.costEstimatesTable,
            'columns': '*',
            'filterColumn': DatabaseConstants.projectIdColumn,
            'filterValue': testProjectId,
            'orderColumn': DatabaseConstants.createdAtColumn,
            'ascending': false,
            'rangeFrom': 0,
            'rangeTo': 9,
          }),
        );
      });

      test(
        'should return unexpected failure when data source throws server exception',
        () async {
          fakeSupabaseWrapper.shouldThrowOnSelectPaginated = true;
          fakeSupabaseWrapper.selectPaginatedExceptionType =
              SupabaseExceptionType.unknown;
          fakeSupabaseWrapper.selectPaginatedErrorMessage = errorMsgServer;

          final result = await repository.fetchInitialEstimations(
            testProjectId,
          );

          expect(result.isLeft(), isTrue);
          expectFailure(
            result,
            (failure) => expect(failure, UnexpectedFailure()),
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

          final result = await repository.fetchInitialEstimations(
            testProjectId,
          );

          expect(result.isLeft(), isTrue);
          expectFailure(
            result,
            (failure) => expect(
              failure,
              EstimationFailure(errorType: EstimationErrorType.timeoutError),
            ),
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

          final result = await repository.fetchInitialEstimations(
            testProjectId,
          );

          expect(result.isLeft(), isTrue);
          expectFailure(
            result,
            (failure) => expect(
              failure,
              EstimationFailure(errorType: EstimationErrorType.connectionError),
            ),
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

          final result = await repository.fetchInitialEstimations(
            testProjectId,
          );

          expect(result.isLeft(), isTrue);
          expectFailure(result, (failure) {
            expect(
              failure,
              EstimationFailure(errorType: EstimationErrorType.parsingError),
            );
          });
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

          final result = await repository.fetchInitialEstimations(
            testProjectId,
          );

          expect(result.isLeft(), isTrue);
          expectFailure(
            result,
            (failure) => expect(
              failure,
              EstimationFailure(errorType: EstimationErrorType.connectionError),
            ),
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

          final result = await repository.fetchInitialEstimations(
            testProjectId,
          );

          expect(result.isLeft(), isTrue);
          expectFailure(
            result,
            (failure) => expect(
              failure,
              EstimationFailure(
                errorType: EstimationErrorType.unexpectedDatabaseError,
              ),
            ),
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

          final result = await repository.fetchInitialEstimations(
            testProjectId,
          );

          expect(result.isRight(), isTrue);
          expectResult(result, (estimates) {
            expect(estimates, [
              estimation1.toDomain(),
              estimation2.toDomain(),
              estimation3.toDomain(),
            ]);
          });
        },
      );

      test(
        'should return first page of estimations when called after pagination',
        () async {
          final maps = seedEstimations(twoPagesDatasetSize);

          final initial = await repository.fetchInitialEstimations(
            testProjectId,
          );
          expect(
            initial.getRightOrNull()!.length,
            equals(defaultPageDatasetSize),
          );
          expect(
            initial.getRightOrNull()!,
            maps
                .sublist(defaultPageDatasetSize)
                .reversed
                .map((e) => CostEstimateDto.fromJson(e).toDomain())
                .toList(),
          );

          final more = await repository.loadMoreEstimations(testProjectId);
          expect(more.getRightOrNull()!.length, equals(twoPagesDatasetSize));
          expect(
            more.getRightOrNull()!,
            maps.reversed
                .map((e) => CostEstimateDto.fromJson(e).toDomain())
                .toList(),
          );

          final resetFetch = await repository.fetchInitialEstimations(
            testProjectId,
          );
          expect(
            resetFetch.getRightOrNull()!.length,
            equals(defaultPageDatasetSize),
          );
          expect(
            resetFetch.getRightOrNull()!,
            maps
                .sublist(defaultPageDatasetSize)
                .reversed
                .map((e) => CostEstimateDto.fromJson(e).toDomain())
                .toList(),
          );
        },
      );

      test(
        'should emit error to stream when fetchInitialEstimations fails',
        () async {
          fakeSupabaseWrapper.shouldThrowOnSelectPaginated = true;
          fakeSupabaseWrapper.selectPaginatedExceptionType =
              SupabaseExceptionType.timeout;

          final stream = repository.watchEstimations(testProjectId);
          final streamUpdates = <Either<Failure, List<CostEstimate>>>[];
          final subscription = stream.listen(streamUpdates.add);

          await pumpEventQueue();

          expect(streamUpdates, hasLength(1));
          expect(streamUpdates[0].isLeft(), isTrue);
          expectFailure(
            streamUpdates[0],
            (failure) => expect(
              failure,
              EstimationFailure(errorType: EstimationErrorType.timeoutError),
            ),
          );

          await subscription.cancel();
        },
      );
    });

    group('loadMoreEstimations', () {
      test(
        'should accumulate and return correct results on successive load more calls',
        () async {
          final totalSize = twoPagesDatasetSize + 5;
          final allMaps = seedEstimations(totalSize);
          final allEstimations = mapsToDomainEntities(
            allMaps.reversed.toList(),
          );

          await repository.fetchInitialEstimations(testProjectId);

          final firstLoadMore = await repository.loadMoreEstimations(
            testProjectId,
          );

          expect(firstLoadMore.isRight(), isTrue);
          firstLoadMore.fold((_) => fail('Expected success'), (estimates) {
            expect(estimates, hasLength(defaultPageDatasetSize * 2));
            expect(
              estimates,
              equals(allEstimations.sublist(0, defaultPageDatasetSize * 2)),
            );
          });

          final secondLoadMore = await repository.loadMoreEstimations(
            testProjectId,
          );

          expect(secondLoadMore.isRight(), isTrue);
          secondLoadMore.fold((_) => fail('Expected success'), (estimates) {
            expect(estimates, hasLength(totalSize));
            expect(estimates, equals(allEstimations));
          });
        },
      );

      test(
        'should emit correct stream updates on successive load more calls',
        () async {
          final totalSize = twoPagesDatasetSize + 5;
          final allMaps = seedEstimations(totalSize);
          final allEstimations = mapsToDomainEntities(
            allMaps.reversed.toList(),
          );

          final stream = repository.watchEstimations(testProjectId);
          final streamUpdates = <Either<Failure, List<CostEstimate>>>[];
          final subscription = stream.listen(streamUpdates.add);

          await pumpEventQueue();

          expect(streamUpdates, hasLength(1));
          streamUpdates[0].fold((_) => fail('Expected success'), (estimates) {
            expect(estimates, hasLength(defaultPageDatasetSize));
            expect(
              estimates,
              equals(allEstimations.sublist(0, defaultPageDatasetSize)),
            );
          });

          await repository.loadMoreEstimations(testProjectId);
          await pumpEventQueue();

          expect(streamUpdates, hasLength(2));
          streamUpdates[1].fold((_) => fail('Expected success'), (estimates) {
            expect(estimates, hasLength(defaultPageDatasetSize * 2));
            expect(
              estimates,
              equals(allEstimations.sublist(0, defaultPageDatasetSize * 2)),
            );
          });

          await repository.loadMoreEstimations(testProjectId);
          await pumpEventQueue();

          expect(streamUpdates, hasLength(3));
          streamUpdates[2].fold((_) => fail('Expected success'), (estimates) {
            expect(estimates, hasLength(totalSize));
            expect(estimates, equals(allEstimations));
          });

          await subscription.cancel();
        },
      );

      test('should return all data when hasMore is false', () async {
        final maps = seedEstimations(smallDatasetSize);

        await repository.fetchInitialEstimations(testProjectId);
        expect(repository.hasMoreEstimations(testProjectId), isFalse);

        final result = await repository.loadMoreEstimations(testProjectId);
        expect(result.isRight(), isTrue);
        expectResult(result, (estimates) {
          expect(estimates, hasLength(smallDatasetSize));
          expect(estimates, mapsToDomainEntities(maps.reversed.toList()));
        });
      });

      test(
        'should return initial estimations when loadMore is called before initial fetch',
        () async {
          final maps = seedEstimations(smallDatasetSize);

          final result = await repository.loadMoreEstimations(testProjectId);
          expect(result.isRight(), isTrue);
          expectResult(result, (estimates) {
            expect(estimates, hasLength(smallDatasetSize));
            expect(estimates, mapsToDomainEntities(maps.reversed.toList()));
          });
        },
      );

      test(
        'should return failure and emit to stream when data source throws on loadMore',
        () async {
          seedEstimations(CostEstimationRepositoryImpl.defaultPageSize);

          final stream = repository.watchEstimations(testProjectId);
          final streamUpdates = <Either<Failure, List<CostEstimate>>>[];
          final subscription = stream.listen(streamUpdates.add);

          await pumpEventQueue();

          expect(streamUpdates, hasLength(1));
          expect(streamUpdates[0].isRight(), isTrue);

          fakeSupabaseWrapper.shouldThrowOnSelectPaginated = true;
          fakeSupabaseWrapper.selectPaginatedExceptionType =
              SupabaseExceptionType.timeout;
          fakeSupabaseWrapper.selectPaginatedErrorMessage = errorMsgTimeout;

          final result = await repository.loadMoreEstimations(testProjectId);

          expect(result.isLeft(), isTrue);
          expectFailure(
            result,
            (failure) => expect(
              failure,
              EstimationFailure(errorType: EstimationErrorType.timeoutError),
            ),
          );

          await pumpEventQueue();

          expect(streamUpdates, hasLength(2));
          expect(streamUpdates[1].isLeft(), isTrue);
          expectFailure(
            streamUpdates[1],
            (failure) => expect(
              failure,
              EstimationFailure(errorType: EstimationErrorType.timeoutError),
            ),
          );

          await subscription.cancel();
        },
      );

      test(
        'should correctly update offset after loading more estimations',
        () async {
          seedEstimations(twoPagesDatasetSize + 5);

          await repository.fetchInitialEstimations(testProjectId);
          await repository.loadMoreEstimations(testProjectId);

          final methodCalls = fakeSupabaseWrapper.getMethodCallsFor(
            'selectPaginated',
          );
          expect(methodCalls.length, equals(2));

          expect(methodCalls[0]['rangeFrom'], equals(0));
          expect(methodCalls[0]['rangeTo'], equals(9));

          expect(methodCalls[1]['rangeFrom'], equals(10));
          expect(methodCalls[1]['rangeTo'], equals(19));
        },
      );
    });

    group('hasMoreEstimations', () {
      test('should return true by default for unknown project', () {
        expect(repository.hasMoreEstimations('unknown-project'), isTrue);
      });

      test('should return false after fetching less than page size', () async {
        seedEstimations(smallDatasetSize);

        await repository.fetchInitialEstimations(testProjectId);

        expect(repository.hasMoreEstimations(testProjectId), isFalse);
      });

      test('should return true after fetching exactly page size', () async {
        seedEstimations(defaultPageDatasetSize);

        await repository.fetchInitialEstimations(testProjectId);

        expect(repository.hasMoreEstimations(testProjectId), isTrue);
      });
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
          expectFailure(
            result,
            (failure) => expect(
              failure,
              EstimationFailure(errorType: EstimationErrorType.timeoutError),
            ),
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
          expectFailure(
            result,
            (failure) => expect(
              failure,
              EstimationFailure(errorType: EstimationErrorType.connectionError),
            ),
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
          expectFailure(
            result,
            (failure) => expect(failure, UnexpectedFailure()),
          );
        },
      );

      test(
        'should emit new list with the new estimation prepended when create is succesfull',
        () async {
          final existingMap = buildEstimationMap(
            id: estimateIdDefault,
            projectId: testProjectId,
            estimateName: estimateNameDefault,
          );
          seedEstimationTable([existingMap]);

          final stream = repository.watchEstimations(testProjectId);
          final updates = <Either<Failure, List<CostEstimate>>>[];
          final subscription = stream.listen(updates.add);

          await pumpEventQueue();

          expect(updates, hasLength(1));
          updates[0].fold(
            (_) => fail('Expected success'),
            (estimates) => expect(estimates, hasLength(1)),
          );

          final newEstimationDto = buildEstimationDto(
            id: estimateId2,
            projectId: testProjectId,
            estimateName: estimateName2,
            createdAt: timestampDefault,
            updatedAt: timestampDefault,
          );
          final newEstimateResult = await repository.createEstimation(
            newEstimationDto.toDomain(),
          );

          await pumpEventQueue();

          expect(updates, hasLength(2));
          updates[1].fold((_) => fail('Expected success'), (estimates) {
            expect(estimates, hasLength(2));
            expect(estimates, [
              newEstimateResult.getRightOrNull()!,
              CostEstimateDto.fromJson(existingMap).toDomain(),
            ]);
          });

          await subscription.cancel();
        },
      );

      test(
        'should maintain correct pagination after creating a new estimation',
        () async {
          final allMaps = seedEstimations(defaultPageDatasetSize * 3);
          final allEstimations = mapsToDomainEntities(
            allMaps.reversed.toList(),
          );

          final stream = repository.watchEstimations(testProjectId);
          final updates = <Either<Failure, List<CostEstimate>>>[];
          final subscription = stream.listen(updates.add);

          await pumpEventQueue();

          await repository.loadMoreEstimations(testProjectId);
          await pumpEventQueue();

          updates.last.fold((_) => fail('Expected success'), (estimates) {
            expect(estimates.length, equals(defaultPageDatasetSize * 2));
            expect(
              estimates,
              equals(allEstimations.sublist(0, defaultPageDatasetSize * 2)),
            );
          });

          final newEstimationDto = buildEstimationDto(
            id: 'new-estimate',
            projectId: testProjectId,
            estimateName: 'New Estimate',
          );

          fakeClock.set(DateTime.parse('2026-02-01T00:00:00.000Z'));

          final createResult = await repository.createEstimation(
            newEstimationDto.toDomain(),
          );
          final createdEstimation = createResult.getRightOrNull()!;
          await pumpEventQueue();

          updates.last.fold((_) => fail('Expected success'), (estimates) {
            expect(estimates.length, equals((defaultPageDatasetSize * 2) + 1));
            expect(
              estimates,
              equals([
                createdEstimation,
                ...allEstimations.sublist(0, defaultPageDatasetSize * 2),
              ]),
            );
          });

          await repository.loadMoreEstimations(testProjectId);
          await pumpEventQueue();

          updates.last.fold((_) => fail('Expected success'), (estimates) {
            expect(estimates.length, equals((defaultPageDatasetSize * 3) + 1));
            expect(estimates, equals([createdEstimation, ...allEstimations]));
          });

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
          expectFailure(
            result,
            (failure) => expect(
              failure,
              EstimationFailure(errorType: EstimationErrorType.notFoundError),
            ),
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
        expectFailure(
          result,
          (failure) => expect(
            failure,
            EstimationFailure(errorType: EstimationErrorType.timeoutError),
          ),
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
          expectFailure(
            result,
            (failure) => expect(
              failure,
              EstimationFailure(errorType: EstimationErrorType.connectionError),
            ),
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
          expectFailure(
            result,
            (failure) => expect(failure, UnexpectedFailure()),
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
          expectFailure(
            result,
            (failure) => expect(
              failure,
              EstimationFailure(errorType: EstimationErrorType.connectionError),
            ),
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
          expectFailure(
            result,
            (failure) => expect(
              failure,
              EstimationFailure(
                errorType: EstimationErrorType.unexpectedDatabaseError,
              ),
            ),
          );
        },
      );

      test(
        'should maintain correct pagination after deleting an estimation',
        () async {
          final totalEstimations = defaultPageDatasetSize * 3;
          final allMaps = seedEstimations(totalEstimations);
          final allEstimations = mapsToDomainEntities(
            allMaps.reversed.toList(),
          );

          final stream = repository.watchEstimations(testProjectId);
          final updates = <Either<Failure, List<CostEstimate>>>[];
          final subscription = stream.listen(updates.add);

          await pumpEventQueue();

          await repository.loadMoreEstimations(testProjectId);
          await pumpEventQueue();

          updates.last.fold((_) => fail('Expected success'), (estimates) {
            expect(estimates.length, equals(defaultPageDatasetSize * 2));
            expect(
              estimates,
              equals(allEstimations.sublist(0, defaultPageDatasetSize * 2)),
            );
          });

          await repository.deleteEstimation('estimate-29', testProjectId);
          await pumpEventQueue();

          updates.last.fold((_) => fail('Expected success'), (estimates) {
            expect(estimates.length, equals((defaultPageDatasetSize * 2) - 1));
            expect(
              estimates,
              equals(
                allEstimations
                    .sublist(0, defaultPageDatasetSize * 2)
                    .where((e) => e.id != 'estimate-29')
                    .toList(),
              ),
            );
          });

          await repository.loadMoreEstimations(testProjectId);
          await pumpEventQueue();

          updates.last.fold((_) => fail('Expected success'), (estimates) {
            expect(estimates.length, equals(totalEstimations - 1));
            expect(
              estimates,
              equals(
                allEstimations.where((e) => e.id != 'estimate-29').toList(),
              ),
            );
          });

          await subscription.cancel();
        },
      );

      test('should refetch estimations when delete fails', () async {
        final maps = seedEstimations(smallDatasetSize);
        final expectedEstimations = mapsToDomainEntities(
          maps.reversed.toList(),
        );

        final stream = repository.watchEstimations(testProjectId);
        final updates = <Either<Failure, List<CostEstimate>>>[];
        final subscription = stream.listen(updates.add);

        await pumpEventQueue();

        expect(updates, hasLength(1));
        expectResult(updates[0], (estimates) {
          expect(estimates, hasLength(smallDatasetSize));
          expect(estimates, equals(expectedEstimations));
        });

        fakeSupabaseWrapper.shouldThrowOnDelete = true;
        fakeSupabaseWrapper.deleteExceptionType = SupabaseExceptionType.timeout;

        final result = await repository.deleteEstimation(
          'estimate-0',
          testProjectId,
        );

        expect(result.isLeft(), isTrue);

        await pumpEventQueue();

        expect(updates, hasLength(3));

        expectResult(updates[1], (estimates) {
          expect(estimates, hasLength(smallDatasetSize - 1));
          expect(
            estimates,
            equals(
              expectedEstimations.where((e) => e.id != 'estimate-0').toList(),
            ),
          );
        });

        expectResult(updates[2], (estimates) {
          expect(estimates, hasLength(smallDatasetSize));
          expect(estimates, equals(expectedEstimations));
        });

        await subscription.cancel();
      });
    });
  });
}
