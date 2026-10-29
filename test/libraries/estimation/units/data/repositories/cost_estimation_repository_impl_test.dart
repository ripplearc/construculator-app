import 'dart:async';

import 'package:async/async.dart';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/data/models/cost_estimate_dto.dart';
import 'package:construculator/libraries/estimation/data/repositories/cost_estimation_repository_impl.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/domain/enums/estimation_sort_option.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/estimation/estimation_library_module.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../../../utils/fake_cost_estimates_database.dart';
import '../../../helpers/estimation_test_data_map_factory.dart';

void main() {
  const String testProjectId = 'project-123';
  const String otherProjectId = 'other-project-456';
  const String estimateIdDefault = 'estimate-1';
  const String estimateId2 = 'estimate-2';
  const String estimateId3 = 'estimate-3';
  const String userIdDefault = 'user-123';
  const String userId2 = 'user-456';
  const String estimateNameDefault = 'Initial Estimate';
  const String estimateName2 = 'Revised Estimate';
  const String estimateName3 = 'Final Estimate';
  const String estimateDescDefault = 'Initial cost estimate';
  const String estimateDesc2 = 'Updated cost estimate with changes';
  const String estimateDesc3 = 'Final cost estimate';
  const String errorMsgServer = 'Server error occurred';
  const String errorMsgTimeout = 'Request timeout';
  const double totalCostDefault = 100000.0;
  const double totalCost2 = 150000.0;
  const double totalCost3 = 200000.0;
  const String timestampDefault = '2024-01-01T10:00:00.000Z';
  const String timestamp2 = '2024-01-02T14:30:00.000Z';
  const String timestamp3 = '2024-01-03T09:15:00.000Z';

  const int smallDatasetSize = 3;
  const int defaultPageDatasetSize =
      CostEstimationRepositoryImpl.defaultPageSize;
  const int twoPagesDatasetSize = defaultPageDatasetSize * 2;

  Matcher rightEstimations(Matcher matcher) {
    return predicate<Either<Failure, List<CostEstimate>>>((result) {
      final estimations = result.getRightOrNull();
      return estimations != null &&
          matcher.matches(estimations, <Object?, Object?>{});
    });
  }

  Matcher leftFailure(Matcher matcher) {
    return predicate<Either<Failure, List<CostEstimate>>>((result) {
      final failure = result.getLeftOrNull();
      return failure != null && matcher.matches(failure, <Object?, Object?>{});
    });
  }

  group('CostEstimationRepositoryImpl', () {
    late CostEstimationRepositoryImpl repository;
    late FakeSupabaseWrapper fakeSupabaseWrapper;
    final fakePhoneDatabase = FakeCostEstimatesDatabase();
    late FakeClockImpl fakeClock;

    setUp(() {
      fakeClock = FakeClockImpl();
      Modular.init(
        _TestAppModule(
          FakeAppBootstrapFactory.create(
            supabaseWrapper: FakeSupabaseWrapper(clock: fakeClock),
          ),
        ),
      );
      Modular.replaceInstance<PowerSyncDatabaseWrapper>(fakePhoneDatabase);
      fakeSupabaseWrapper =
          Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
      repository =
          Modular.get<CostEstimationRepository>()
              as CostEstimationRepositoryImpl;
      repository.dispose();
      fakeSupabaseWrapper.reset();
      fakePhoneDatabase.reset();
    });

    tearDown(() {
      Modular.destroy();
    });

    tearDownAll(() {
      fakePhoneDatabase.dispose();
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
      fakePhoneDatabase.seedRows(rows);
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

      test(
        'should watch the phone copy with the project and page limit',
        () async {
          await repository.fetchInitialEstimations(testProjectId);

          final watchCall = fakePhoneDatabase.watchCalls.single;
          expect(
            watchCall.sql,
            'SELECT * FROM ${DatabaseConstants.costEstimatesTable} '
            'WHERE ${DatabaseConstants.projectIdColumn} = ? '
            'ORDER BY ${DatabaseConstants.createdAtColumn} DESC LIMIT ?',
          );
          expect(watchCall.parameters, [
            testProjectId,
            CostEstimationRepositoryImpl.defaultPageSize,
          ]);
        },
      );

      test(
        'should use the caller limit as the first page and as the page size',
        () async {
          const callerLimit = 3;
          seedEstimations(defaultPageDatasetSize);

          final initial = await repository.fetchInitialEstimations(
            testProjectId,
            limit: callerLimit,
          );
          final more = await repository.loadMoreEstimations(
            testProjectId,
            limit: callerLimit,
          );

          expectResult(
            initial,
            (estimates) => expect(estimates, hasLength(callerLimit)),
          );
          expectResult(
            more,
            (estimates) => expect(estimates, hasLength(callerLimit * 2)),
          );
          expect(
            fakePhoneDatabase.watchCalls.map((call) => call.parameters.last),
            [callerLimit, callerLimit * 2],
          );
        },
      );

      test('should not read estimations from the server', () async {
        seedEstimationTable([buildEstimationMap(projectId: testProjectId)]);
        fakeSupabaseWrapper.shouldThrowOnSelectPaginated = true;
        fakeSupabaseWrapper.selectPaginatedExceptionType =
            SupabaseExceptionType.socket;

        final result = await repository.fetchInitialEstimations(testProjectId);

        expectResult(result, (estimates) => expect(estimates, hasLength(1)));
        expect(
          fakeSupabaseWrapper.getMethodCallsFor('selectPaginated'),
          isEmpty,
        );
      });

      test(
        'should return unexpected failure when the phone database throws',
        () async {
          fakePhoneDatabase.watchError = StateError('database is locked');

          final result = await repository.fetchInitialEstimations(
            testProjectId,
          );

          expectFailure(
            result,
            (failure) => expect(failure, UnexpectedFailure()),
          );
        },
      );

      test(
        'should return parsing error when a phone row is malformed',
        () async {
          final malformedRow = buildEstimationMap(projectId: testProjectId)
            ..['estimate_name'] = 42;
          fakePhoneDatabase.seedRows([malformedRow]);

          final result = await repository.fetchInitialEstimations(
            testProjectId,
          );

          expectFailure(
            result,
            (failure) => expect(
              failure,
              EstimationFailure(errorType: EstimationErrorType.parsingError),
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
          fakePhoneDatabase.watchError = StateError('database is locked');

          await expectLater(
            repository.watchEstimations(testProjectId),
            emits(leftFailure(equals(UnexpectedFailure()))),
          );
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

          // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
          final queue = StreamQueue(repository.watchEstimations(testProjectId));

          await expectLater(
            queue.next,
            completion(
              rightEstimations(
                equals(allEstimations.sublist(0, defaultPageDatasetSize)),
              ),
            ),
          );

          await repository.loadMoreEstimations(testProjectId);
          await expectLater(
            queue.next,
            completion(
              rightEstimations(
                equals(allEstimations.sublist(0, defaultPageDatasetSize * 2)),
              ),
            ),
          );

          await repository.loadMoreEstimations(testProjectId);
          await expectLater(
            queue.next,
            completion(rightEstimations(equals(allEstimations))),
          );

          await queue.cancel();
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
          final seededMaps = seedEstimations(
            CostEstimationRepositoryImpl.defaultPageSize,
          );

          final initialEstimations = mapsToDomainEntities(
            seededMaps.reversed.toList(),
          );
          // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
          final queue = StreamQueue(repository.watchEstimations(testProjectId));

          await expectLater(
            queue.next,
            completion(rightEstimations(equals(initialEstimations))),
          );

          fakePhoneDatabase.watchError = StateError('database is locked');

          final result = await repository.loadMoreEstimations(testProjectId);

          expectFailure(
            result,
            (failure) => expect(failure, UnexpectedFailure()),
          );

          await expectLater(
            queue.next,
            completion(leftFailure(equals(UnexpectedFailure()))),
          );

          await queue.cancel();
        },
      );

      test(
        'should raise the limit of the phone watch by a page when loading more',
        () async {
          seedEstimations(twoPagesDatasetSize + 5);

          await repository.fetchInitialEstimations(testProjectId);
          await repository.loadMoreEstimations(testProjectId);

          final limits = fakePhoneDatabase.watchCalls
              .map((call) => call.parameters.last)
              .toList();
          expect(limits, [defaultPageDatasetSize, twoPagesDatasetSize]);
        },
      );

      test(
        'should report no more estimations once a larger limit returns fewer rows than asked',
        () async {
          seedEstimations(defaultPageDatasetSize + smallDatasetSize);

          await repository.fetchInitialEstimations(testProjectId);
          expect(repository.hasMoreEstimations(testProjectId), isTrue);

          final result = await repository.loadMoreEstimations(testProjectId);

          expect(repository.hasMoreEstimations(testProjectId), isFalse);
          expectResult(
            result,
            (estimates) => expect(
              estimates,
              hasLength(defaultPageDatasetSize + smallDatasetSize),
            ),
          );
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

      test(
        'fetching with updatedAt must not reset createdAt pagination state',
        () async {
          seedEstimations(defaultPageDatasetSize, includeUpdatedAt: true);

          await repository.fetchInitialEstimations(testProjectId);
          expect(repository.hasMoreEstimations(testProjectId), isTrue);

          await repository.fetchInitialEstimations(
            testProjectId,
            sortBy: EstimationSortOption.updatedAt,
          );

          expect(repository.hasMoreEstimations(testProjectId), isTrue);
          expect(
            repository.hasMoreEstimations(
              testProjectId,
              sortBy: EstimationSortOption.updatedAt,
            ),
            isTrue,
          );
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

        final result1Future = stream1.first;
        final result2Future = stream2.first;
        final result1 = await result1Future;
        final result2 = await result2Future;

        expect(result1, equals(result2));
      });

      test(
        'should isolate two concurrent streams with different sort keys',
        () async {
          seedEstimations(defaultPageDatasetSize, includeUpdatedAt: true);

          final createdAtStream = repository.watchEstimations(
            testProjectId,
            sortBy: EstimationSortOption.createdAt,
          );
          final updatedAtStream = repository.watchEstimations(
            testProjectId,
            sortBy: EstimationSortOption.updatedAt,
          );

          // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
          final createdAtQueue = StreamQueue(createdAtStream);
          // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
          final updatedAtQueue = StreamQueue(updatedAtStream);

          await expectLater(
            createdAtQueue.next,
            completion(rightEstimations(anything)),
          );
          await expectLater(
            updatedAtQueue.next,
            completion(rightEstimations(anything)),
          );

          final orderColumns = fakePhoneDatabase.watchCalls
              .map((call) => call.sql)
              .toList();
          expect(orderColumns, hasLength(2));
          expect(
            orderColumns[0],
            contains('ORDER BY ${DatabaseConstants.createdAtColumn} DESC'),
          );
          expect(
            orderColumns[1],
            contains('ORDER BY ${DatabaseConstants.updatedAtColumn} DESC'),
          );

          await createdAtQueue.cancel();
          await updatedAtQueue.cancel();
        },
      );
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

          // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
          final queue = StreamQueue(repository.watchEstimations(testProjectId));

          await expectLater(
            queue.next,
            completion(
              rightEstimations(
                equals([CostEstimateDto.fromJson(existingMap).toDomain()]),
              ),
            ),
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
          final createdEstimation = newEstimateResult.getRightOrNull()!;

          await expectLater(
            queue.next,
            completion(
              rightEstimations(
                equals([
                  createdEstimation,
                  CostEstimateDto.fromJson(existingMap).toDomain(),
                ]),
              ),
            ),
          );

          await queue.cancel();
        },
      );

      test(
        'should maintain correct pagination after creating a new estimation',
        () async {
          final allMaps = seedEstimations(defaultPageDatasetSize * 3);
          final allEstimations = mapsToDomainEntities(
            allMaps.reversed.toList(),
          );

          // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
          final queue = StreamQueue(repository.watchEstimations(testProjectId));

          await expectLater(
            queue.next,
            completion(
              rightEstimations(
                equals(allEstimations.sublist(0, defaultPageDatasetSize)),
              ),
            ),
          );

          await repository.loadMoreEstimations(testProjectId);

          await expectLater(
            queue.next,
            completion(
              rightEstimations(
                equals(allEstimations.sublist(0, defaultPageDatasetSize * 2)),
              ),
            ),
          );

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

          await repository.loadMoreEstimations(testProjectId);

          await expectLater(
            queue.next,
            completion(
              rightEstimations(
                equals([
                  createdEstimation,
                  ...allEstimations.sublist(0, defaultPageDatasetSize * 2),
                ]),
              ),
            ),
          );
          await expectLater(
            queue.next,
            completion(
              rightEstimations(equals([createdEstimation, ...allEstimations])),
            ),
          );

          await queue.cancel();
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
          // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
          final queue = StreamQueue(stream);

          await expectLater(queue.next, completion(rightEstimations(isEmpty)));

          repository.dispose();

          await queue.cancel();
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

          // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
          final queue = StreamQueue(repository.watchEstimations(testProjectId));

          await expectLater(
            queue.next,
            completion(rightEstimations(hasLength(2))),
          );

          final result = await repository.deleteEstimation(
            estimateIdDefault,
            testProjectId,
          );

          expect(result.isRight(), isTrue);

          await expectLater(
            queue.next,
            completion(rightEstimations(equals([estimation2.toDomain()]))),
          );

          await queue.cancel();
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

          // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
          final queue = StreamQueue(repository.watchEstimations(testProjectId));

          await expectLater(
            queue.next,
            completion(
              rightEstimations(
                equals(allEstimations.sublist(0, defaultPageDatasetSize)),
              ),
            ),
          );

          await repository.loadMoreEstimations(testProjectId);
          await expectLater(
            queue.next,
            completion(
              rightEstimations(
                equals(allEstimations.sublist(0, defaultPageDatasetSize * 2)),
              ),
            ),
          );

          await repository.deleteEstimation('estimate-29', testProjectId);
          await expectLater(
            queue.next,
            completion(
              rightEstimations(
                equals(
                  allEstimations
                      .sublist(0, defaultPageDatasetSize * 2)
                      .where((e) => e.id != 'estimate-29')
                      .toList(),
                ),
              ),
            ),
          );

          await repository.loadMoreEstimations(testProjectId);
          await expectLater(
            queue.next,
            completion(
              rightEstimations(
                equals(
                  allEstimations.where((e) => e.id != 'estimate-29').toList(),
                ),
              ),
            ),
          );

          await queue.cancel();
        },
      );

      test('should refetch estimations when delete fails', () async {
        final maps = seedEstimations(smallDatasetSize);
        final expectedEstimations = mapsToDomainEntities(
          maps.reversed.toList(),
        );

        // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
        final queue = StreamQueue(repository.watchEstimations(testProjectId));

        await expectLater(
          queue.next,
          completion(rightEstimations(equals(expectedEstimations))),
        );

        fakeSupabaseWrapper.shouldThrowOnDelete = true;
        fakeSupabaseWrapper.deleteExceptionType = SupabaseExceptionType.timeout;

        final result = await repository.deleteEstimation(
          'estimate-0',
          testProjectId,
        );

        expect(result.isLeft(), isTrue);

        await expectLater(
          queue.next,
          completion(
            rightEstimations(
              equals(
                expectedEstimations.where((e) => e.id != 'estimate-0').toList(),
              ),
            ),
          ),
        );
        await expectLater(
          queue.next,
          completion(rightEstimations(equals(expectedEstimations))),
        );

        await queue.cancel();
      });

      test(
        'should restore every watched list of the project when delete fails',
        () async {
          final maps = seedEstimations(smallDatasetSize);
          final newestFirst = mapsToDomainEntities(maps.reversed.toList());
          final oldestFirst = mapsToDomainEntities(maps);

          // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
          final newestQueue = StreamQueue(
            repository.watchEstimations(testProjectId),
          );
          // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
          final oldestQueue = StreamQueue(
            repository.watchEstimations(testProjectId, ascending: true),
          );
          await expectLater(
            newestQueue.next,
            completion(rightEstimations(equals(newestFirst))),
          );
          await expectLater(
            oldestQueue.next,
            completion(rightEstimations(equals(oldestFirst))),
          );
          fakeSupabaseWrapper.shouldThrowOnDelete = true;
          fakeSupabaseWrapper.deleteExceptionType =
              SupabaseExceptionType.timeout;

          await repository.deleteEstimation('estimate-0', testProjectId);

          await newestQueue.next;
          await oldestQueue.next;
          await expectLater(
            newestQueue.next,
            completion(rightEstimations(equals(newestFirst))),
          );
          await expectLater(
            oldestQueue.next,
            completion(rightEstimations(equals(oldestFirst))),
          );
          await newestQueue.cancel();
          await oldestQueue.cancel();
        },
      );
    });

    group('changeLockStatus', () {
      test(
        'should return updated estimation and update stream when locking succeeds',
        () async {
          final initialMap = buildEstimationMap(
            id: estimateIdDefault,
            projectId: testProjectId,
            isLocked: false,
          );
          seedEstimationTable([initialMap]);

          // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
          final queue = StreamQueue(repository.watchEstimations(testProjectId));

          await expectLater(
            queue.next,
            completion(
              rightEstimations(
                predicate<List<CostEstimate>>(
                  (estimations) =>
                      estimations.length == 1 &&
                      estimations.first.lockStatus.isLocked == false,
                ),
              ),
            ),
          );

          final result = await repository.changeLockStatus(
            estimationId: estimateIdDefault,
            isLocked: true,
            projectId: testProjectId,
          );

          expect(result.isRight(), isTrue);
          expectResult(result, (updatedEstimation) {
            expect(updatedEstimation.lockStatus.isLocked, isTrue);
          });

          await expectLater(
            queue.next,
            completion(
              rightEstimations(
                predicate<List<CostEstimate>>(
                  (estimations) =>
                      estimations.length == 1 &&
                      estimations.first.lockStatus.isLocked,
                ),
              ),
            ),
          );
          await expectLater(
            queue.next,
            completion(
              rightEstimations(
                predicate<List<CostEstimate>>(
                  (estimations) =>
                      estimations.length == 1 &&
                      estimations.first.lockStatus.isLocked,
                ),
              ),
            ),
          );

          await queue.cancel();
        },
      );

      test(
        'should return updated estimation and update stream when unlocking succeeds',
        () async {
          final initialMap = buildEstimationMap(
            id: estimateIdDefault,
            projectId: testProjectId,
            isLocked: true,
            lockedByUserId: userIdDefault,
            lockedAt: timestampDefault,
          );
          seedEstimationTable([initialMap]);

          // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
          final queue = StreamQueue(repository.watchEstimations(testProjectId));
          await expectLater(
            queue.next,
            completion(
              rightEstimations(
                predicate<List<CostEstimate>>(
                  (estimations) =>
                      estimations.length == 1 &&
                      estimations.first.lockStatus.isLocked,
                ),
              ),
            ),
          );

          final result = await repository.changeLockStatus(
            estimationId: estimateIdDefault,
            isLocked: false,
            projectId: testProjectId,
          );

          expect(result.isRight(), isTrue);
          result.fold((_) => fail('Unlocking failed'), (updatedEstimation) {
            expect(updatedEstimation.lockStatus.isLocked, isFalse);
          });

          await expectLater(
            queue.next,
            completion(
              rightEstimations(
                predicate<List<CostEstimate>>(
                  (estimations) =>
                      estimations.length == 1 &&
                      estimations.first.lockStatus.isLocked == false,
                ),
              ),
            ),
          );
          await expectLater(
            queue.next,
            completion(
              rightEstimations(
                predicate<List<CostEstimate>>(
                  (estimations) =>
                      estimations.length == 1 &&
                      estimations.first.lockStatus.isLocked == false,
                ),
              ),
            ),
          );

          await queue.cancel();
        },
      );

      test(
        'should return timeout failure when data source throws timeout',
        () async {
          fakeSupabaseWrapper.shouldThrowOnUpdate = true;
          fakeSupabaseWrapper.updateExceptionType =
              SupabaseExceptionType.timeout;
          fakeSupabaseWrapper.updateErrorMessage = errorMsgTimeout;

          final result = await repository.changeLockStatus(
            estimationId: estimateIdDefault,
            isLocked: true,
            projectId: testProjectId,
          );

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
        'should return notFoundError when data source throws PGRST116',
        () async {
          fakeSupabaseWrapper.shouldThrowOnUpdate = true;
          fakeSupabaseWrapper.updateExceptionType =
              SupabaseExceptionType.postgrest;
          fakeSupabaseWrapper.postgrestErrorCode =
              PostgresErrorCode.noDataFound;
          fakeSupabaseWrapper.updateErrorMessage = 'No data found';

          final result = await repository.changeLockStatus(
            estimationId: estimateIdDefault,
            isLocked: true,
            projectId: testProjectId,
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

      test(
        'should emit optimistic update to stream before API call completes',
        () async {
          final initialMap = buildEstimationMap(
            id: estimateIdDefault,
            projectId: testProjectId,
            isLocked: false,
          );
          seedEstimationTable([initialMap]);

          // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
          final queue = StreamQueue(repository.watchEstimations(testProjectId));

          await expectLater(
            queue.next,
            completion(
              rightEstimations(
                predicate<List<CostEstimate>>(
                  (estimations) =>
                      estimations.length == 1 &&
                      estimations.first.lockStatus.isLocked == false,
                ),
              ),
            ),
          );

          final resultFuture = repository.changeLockStatus(
            estimationId: estimateIdDefault,
            isLocked: true,
            projectId: testProjectId,
          );

          await expectLater(
            queue.next,
            completion(
              rightEstimations(
                predicate<List<CostEstimate>>(
                  (estimations) =>
                      estimations.length == 1 &&
                      estimations.first.lockStatus.isLocked,
                ),
              ),
            ),
          );

          await resultFuture;

          await expectLater(
            queue.next,
            completion(
              rightEstimations(
                predicate<List<CostEstimate>>(
                  (estimations) =>
                      estimations.length == 1 &&
                      estimations.first.lockStatus.isLocked,
                ),
              ),
            ),
          );

          await queue.cancel();
        },
      );

      test('should revert optimistic update when data source throws', () async {
        final initialMap = buildEstimationMap(
          id: estimateIdDefault,
          projectId: testProjectId,
          isLocked: false,
        );
        seedEstimationTable([initialMap]);

        // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
        final queue = StreamQueue(repository.watchEstimations(testProjectId));

        await expectLater(
          queue.next,
          completion(
            rightEstimations(
              predicate<List<CostEstimate>>(
                (estimations) =>
                    estimations.length == 1 &&
                    estimations.first.lockStatus.isLocked == false,
              ),
            ),
          ),
        );

        fakeSupabaseWrapper.shouldThrowOnUpdate = true;
        fakeSupabaseWrapper.updateExceptionType = SupabaseExceptionType.timeout;
        fakeSupabaseWrapper.updateErrorMessage = errorMsgTimeout;

        final result = await repository.changeLockStatus(
          estimationId: estimateIdDefault,
          isLocked: true,
          projectId: testProjectId,
        );

        expect(result.isLeft(), isTrue);

        await expectLater(
          queue.next,
          completion(
            rightEstimations(
              predicate<List<CostEstimate>>(
                (estimations) =>
                    estimations.length == 1 &&
                    estimations.first.lockStatus.isLocked,
              ),
            ),
          ),
        );
        await expectLater(
          queue.next,
          completion(
            rightEstimations(
              predicate<List<CostEstimate>>(
                (estimations) =>
                    estimations.length == 1 &&
                    estimations.first.lockStatus.isLocked == false,
              ),
            ),
          ),
        );

        await queue.cancel();
      });

      test('should succeed without active stream listeners', () async {
        final initialMap = buildEstimationMap(
          id: estimateIdDefault,
          projectId: testProjectId,
          isLocked: false,
        );
        seedEstimationTable([initialMap]);

        final result = await repository.changeLockStatus(
          estimationId: estimateIdDefault,
          isLocked: true,
          projectId: testProjectId,
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected success'), (updated) {
          expect(updated.lockStatus.isLocked, isTrue);
        });
      });

      test(
        'should call supabaseWrapper with correct parameters when locking',
        () async {
          final initialMap = buildEstimationMap(
            id: estimateIdDefault,
            projectId: testProjectId,
            isLocked: false,
          );
          seedEstimationTable([initialMap]);

          await repository.changeLockStatus(
            estimationId: estimateIdDefault,
            isLocked: true,
            projectId: testProjectId,
          );

          final methodCalls = fakeSupabaseWrapper.getMethodCallsFor('update');
          expect(methodCalls, hasLength(1));

          final call = methodCalls.first;
          expect(
            call,
            equals({
              'method': 'update',
              'table': DatabaseConstants.costEstimatesTable,
              'data': {DatabaseConstants.isLockedColumn: true},
              'filterColumn': DatabaseConstants.idColumn,
              'filterValue': estimateIdDefault,
            }),
          );
        },
      );

      test(
        'should call supabaseWrapper with correct parameters when unlocking',
        () async {
          final initialMap = buildEstimationMap(
            id: estimateIdDefault,
            projectId: testProjectId,
            isLocked: true,
            lockedByUserId: userIdDefault,
            lockedAt: timestampDefault,
          );
          seedEstimationTable([initialMap]);

          await repository.changeLockStatus(
            estimationId: estimateIdDefault,
            isLocked: false,
            projectId: testProjectId,
          );

          final methodCalls = fakeSupabaseWrapper.getMethodCallsFor('update');
          expect(methodCalls, hasLength(1));

          final call = methodCalls.first;
          expect(
            call,
            equals({
              'method': 'update',
              'table': DatabaseConstants.costEstimatesTable,
              'data': {DatabaseConstants.isLockedColumn: false},
              'filterColumn': DatabaseConstants.idColumn,
              'filterValue': estimateIdDefault,
            }),
          );
        },
      );
    });

    group('getEstimation', () {
      test('should return the matching estimation', () async {
        final map = buildEstimationMap(
          id: estimateIdDefault,
          projectId: testProjectId,
          estimateName: estimateNameDefault,
        );
        seedEstimationTable([map]);

        final result = await repository.getEstimation(estimateIdDefault);

        expect(result.isRight(), isTrue);
        expectResult(
          result,
          (estimation) => expect(
            estimation,
            equals(CostEstimateDto.fromJson(map).toDomain()),
          ),
        );
      });

      test('should return notFoundError when no row has the ID', () async {
        seedEstimationTable([]);

        final result = await repository.getEstimation(estimateIdDefault);

        expect(result.isLeft(), isTrue);
        expectFailure(
          result,
          (failure) => expect(
            failure,
            EstimationFailure(errorType: EstimationErrorType.notFoundError),
          ),
        );
      });

      test(
        'should return connection error when data source throws SocketException',
        () async {
          fakeSupabaseWrapper.shouldThrowOnSelect = true;
          fakeSupabaseWrapper.selectExceptionType =
              SupabaseExceptionType.socket;
          fakeSupabaseWrapper.selectErrorMessage = 'Connection failed';

          final result = await repository.getEstimation(estimateIdDefault);

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
        'should return timeout error when data source throws TimeoutException',
        () async {
          fakeSupabaseWrapper.shouldThrowOnSelect = true;
          fakeSupabaseWrapper.selectExceptionType =
              SupabaseExceptionType.timeout;
          fakeSupabaseWrapper.selectErrorMessage = errorMsgTimeout;

          final result = await repository.getEstimation(estimateIdDefault);

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
    });

    group('renameEstimation', () {
      const String newEstimateName = 'Renamed Estimate';

      test(
        'should return updated estimation and update stream when rename succeeds',
        () async {
          fakeClock.set(DateTime.parse(timestamp2));
          final initialMap = buildEstimationMap(
            id: estimateIdDefault,
            projectId: testProjectId,
            estimateName: estimateNameDefault,
            createdAt: timestamp2,
            updatedAt: timestamp2,
          );
          seedEstimationTable([initialMap]);

          final expectedEstimation = CostEstimateDto.fromJson(
            initialMap,
          ).toDomain();
          // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
          final queue = StreamQueue(repository.watchEstimations(testProjectId));

          await expectLater(
            queue.next,
            completion(rightEstimations(equals([expectedEstimation]))),
          );

          final result = await repository.renameEstimation(
            estimationId: estimateIdDefault,
            newName: newEstimateName,
            projectId: testProjectId,
          );

          expect(result.isRight(), isTrue);
          expectResult(result, (updatedEstimation) {
            expect(
              updatedEstimation,
              equals(
                expectedEstimation.copyWith(estimateName: newEstimateName),
              ),
            );
          });
          await expectLater(
            queue.next,
            completion(
              rightEstimations(
                equals([
                  expectedEstimation.copyWith(estimateName: newEstimateName),
                ]),
              ),
            ),
          );
          await expectLater(
            queue.next,
            completion(
              rightEstimations(
                equals([
                  expectedEstimation.copyWith(estimateName: newEstimateName),
                ]),
              ),
            ),
          );

          await queue.cancel();
        },
      );

      test(
        'should emit optimistic update to stream before API call completes',
        () async {
          fakeClock.set(DateTime.parse(timestamp2));
          final initialMap = buildEstimationMap(
            id: estimateIdDefault,
            projectId: testProjectId,
            estimateName: estimateNameDefault,
            createdAt: timestamp2,
            updatedAt: timestamp2,
          );
          seedEstimationTable([initialMap]);

          final expectedEstimation = CostEstimateDto.fromJson(
            initialMap,
          ).toDomain();
          // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
          final queue = StreamQueue(repository.watchEstimations(testProjectId));

          await expectLater(
            queue.next,
            completion(rightEstimations(equals([expectedEstimation]))),
          );

          final resultFuture = repository.renameEstimation(
            estimationId: estimateIdDefault,
            newName: newEstimateName,
            projectId: testProjectId,
          );

          await expectLater(
            queue.next,
            completion(
              rightEstimations(
                equals([
                  expectedEstimation.copyWith(estimateName: newEstimateName),
                ]),
              ),
            ),
          );

          await resultFuture;

          await expectLater(
            queue.next,
            completion(
              rightEstimations(
                equals([
                  expectedEstimation.copyWith(estimateName: newEstimateName),
                ]),
              ),
            ),
          );

          await queue.cancel();
        },
      );

      test(
        'should return notFoundError when data source throws PostgrestException with no data found',
        () async {
          fakeSupabaseWrapper.shouldThrowOnUpdate = true;
          fakeSupabaseWrapper.updateExceptionType =
              SupabaseExceptionType.postgrest;
          fakeSupabaseWrapper.postgrestErrorCode =
              PostgresErrorCode.noDataFound;
          fakeSupabaseWrapper.updateErrorMessage = 'No data found';

          final result = await repository.renameEstimation(
            estimationId: estimateIdDefault,
            newName: newEstimateName,
            projectId: testProjectId,
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

      test('should revert optimistic update when data source throws', () async {
        fakeClock.set(DateTime.parse(timestamp2));
        final initialMap = buildEstimationMap(
          id: estimateIdDefault,
          projectId: testProjectId,
          estimateName: estimateNameDefault,
          createdAt: timestamp2,
          updatedAt: timestamp2,
        );
        seedEstimationTable([initialMap]);

        final expectedEstimation = CostEstimateDto.fromJson(
          initialMap,
        ).toDomain();
        // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
        final queue = StreamQueue(repository.watchEstimations(testProjectId));

        await expectLater(
          queue.next,
          completion(rightEstimations(equals([expectedEstimation]))),
        );

        fakeSupabaseWrapper.shouldThrowOnUpdate = true;
        fakeSupabaseWrapper.updateExceptionType = SupabaseExceptionType.timeout;
        fakeSupabaseWrapper.updateErrorMessage = errorMsgTimeout;

        final result = await repository.renameEstimation(
          estimationId: estimateIdDefault,
          newName: newEstimateName,
          projectId: testProjectId,
        );

        expect(result.isLeft(), isTrue);

        await expectLater(
          queue.next,
          completion(
            rightEstimations(
              equals([
                expectedEstimation.copyWith(estimateName: newEstimateName),
              ]),
            ),
          ),
        );
        await expectLater(
          queue.next,
          completion(rightEstimations(equals([expectedEstimation]))),
        );

        await queue.cancel();
      });

      test(
        'should rollback optimistic rename for updatedAt stream when update fails',
        () async {
          fakeClock.set(DateTime.parse(timestamp2));
          final initialMap = buildEstimationMap(
            id: estimateIdDefault,
            projectId: testProjectId,
            estimateName: estimateNameDefault,
            createdAt: timestamp2,
            updatedAt: timestamp2,
          );
          seedEstimationTable([initialMap]);

          final expectedEstimation = CostEstimateDto.fromJson(
            initialMap,
          ).toDomain();

          // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
          final queue = StreamQueue(
            repository.watchEstimations(
              testProjectId,
              sortBy: EstimationSortOption.updatedAt,
            ),
          );

          await expectLater(
            queue.next,
            completion(rightEstimations(equals([expectedEstimation]))),
          );

          fakeSupabaseWrapper.shouldThrowOnUpdate = true;
          fakeSupabaseWrapper.updateExceptionType =
              SupabaseExceptionType.timeout;
          fakeSupabaseWrapper.updateErrorMessage = errorMsgTimeout;

          final result = await repository.renameEstimation(
            estimationId: estimateIdDefault,
            newName: newEstimateName,
            projectId: testProjectId,
          );

          expect(result.isLeft(), isTrue);

          await expectLater(
            queue.next,
            completion(
              rightEstimations(
                equals([
                  expectedEstimation.copyWith(estimateName: newEstimateName),
                ]),
              ),
            ),
          );
          await expectLater(
            queue.next,
            completion(rightEstimations(equals([expectedEstimation]))),
          );

          await queue.cancel();
        },
      );

      test('should call supabaseWrapper with correct parameters', () async {
        final initialMap = buildEstimationMap(
          id: estimateIdDefault,
          projectId: testProjectId,
          estimateName: estimateNameDefault,
        );
        seedEstimationTable([initialMap]);

        await repository.renameEstimation(
          estimationId: estimateIdDefault,
          newName: newEstimateName,
          projectId: testProjectId,
        );

        final methodCalls = fakeSupabaseWrapper.getMethodCallsFor('update');
        expect(methodCalls, hasLength(1));

        final call = methodCalls.first;
        expect(
          call,
          equals({
            'method': 'update',
            'table': DatabaseConstants.costEstimatesTable,
            'data': {DatabaseConstants.estimateNameColumn: newEstimateName},
            'filterColumn': DatabaseConstants.idColumn,
            'filterValue': estimateIdDefault,
          }),
        );
      });
    });

    group('writes before the phone copy catches up', () {
      const newEstimateName = 'Renamed Estimate';
      const unrelatedEstimateId = 'estimate-unrelated';
      const otherProjectEstimateId = 'estimate-other-project';

      Map<String, dynamic> projectEstimate({
        String? id,
        String? estimateName,
        String? createdAt,
        bool? isLocked,
      }) => buildEstimationMap(
        id: id,
        projectId: testProjectId,
        estimateName: estimateName,
        createdAt: createdAt,
        isLocked: isLocked,
        lockedByUserId: isLocked == true ? userIdDefault : null,
        lockedAt: isLocked == true ? timestampDefault : null,
      );

      Map<String, dynamic> neighbourEstimate() => projectEstimate(
        id: estimateId3,
        estimateName: estimateName3,
        createdAt: '2023-06-01T00:00:00.000Z',
      );

      void syncUnrelatedEstimate() => fakePhoneDatabase.seedRows([
        projectEstimate(
          id: unrelatedEstimateId,
          createdAt: '2023-01-01T00:00:00.000Z',
        ),
      ]);

      void syncOtherProjectEstimate() => fakePhoneDatabase.seedRows([
        buildEstimationMap(
          id: otherProjectEstimateId,
          projectId: otherProjectId,
        ),
      ]);

      CostEstimate estimateIn(
        Either<Failure, List<CostEstimate>> result, [
        String id = estimateIdDefault,
      ]) =>
          result.getRightOrNull()!.firstWhere((estimate) => estimate.id == id);

      List<String> idsIn(Either<Failure, List<CostEstimate>> result) =>
          result.getRightOrNull()!.map((estimate) => estimate.id).toList();

      void expectNeighbourUntouched(
        List<Either<Failure, List<CostEstimate>>> emissions,
      ) {
        for (final emission in emissions) {
          expect(estimateIn(emission, estimateId3).estimateName, estimateName3);
          expect(
            estimateIn(emission, estimateId3).lockStatus.isLocked,
            isFalse,
          );
        }
      }

      Future<StreamQueue<Either<Failure, List<CostEstimate>>>> watchProject(
        String projectId,
        int expectedCount,
      ) async {
        // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
        final queue = StreamQueue(repository.watchEstimations(projectId));
        await expectLater(
          queue.next,
          completion(rightEstimations(hasLength(expectedCount))),
        );
        return queue;
      }

      Future<StreamQueue<Either<Failure, List<CostEstimate>>>> watchSeeded(
        List<Map<String, dynamic>> maps,
      ) {
        seedEstimationTable(maps);
        return watchProject(testProjectId, maps.length);
      }

      group('a rename', () {
        test('does not flip back when the phone copy re-emits', () async {
          final queue = await watchSeeded([
            projectEstimate(),
            neighbourEstimate(),
          ]);

          await repository.renameEstimation(
            estimationId: estimateIdDefault,
            newName: newEstimateName,
            projectId: testProjectId,
          );
          syncUnrelatedEstimate();

          final emissions = await queue.take(3);
          expect(estimateIn(emissions.last).estimateName, newEstimateName);
          expectNeighbourUntouched(emissions);
          await queue.cancel();
        });

        test('stops being re-applied once the phone copy shows it', () async {
          final queue = await watchSeeded([projectEstimate()]);
          await repository.renameEstimation(
            estimationId: estimateIdDefault,
            newName: newEstimateName,
            projectId: testProjectId,
          );
          await queue.take(2);
          fakePhoneDatabase.replaceRow(
            projectEstimate(estimateName: newEstimateName),
          );
          await queue.next;

          const nameChangedElsewhere = 'Renamed on another phone';
          fakePhoneDatabase.replaceRow(
            projectEstimate(estimateName: nameChangedElsewhere),
          );

          expect(
            estimateIn(await queue.next).estimateName,
            nameChangedElsewhere,
          );
          await queue.cancel();
        });

        test('that fails online shows the old name again', () async {
          final queue = await watchSeeded([
            projectEstimate(),
            neighbourEstimate(),
          ]);
          fakeSupabaseWrapper.shouldThrowOnUpdate = true;
          fakeSupabaseWrapper.updateExceptionType =
              SupabaseExceptionType.timeout;

          await repository.renameEstimation(
            estimationId: estimateIdDefault,
            newName: newEstimateName,
            projectId: testProjectId,
          );
          syncUnrelatedEstimate();

          final emissions = await queue.take(3);
          expect(estimateIn(emissions.last).estimateName, estimateNameDefault);
          expectNeighbourUntouched(emissions);
          await queue.cancel();
        });

        test(
          'is shown when the phone copy re-emits before the server answers',
          () async {
            final queue = await watchSeeded([
              projectEstimate(),
              neighbourEstimate(),
            ]);
            fakeSupabaseWrapper.shouldDelayOperations = true;
            fakeSupabaseWrapper.completer = Completer();

            final renaming = repository.renameEstimation(
              estimationId: estimateIdDefault,
              newName: newEstimateName,
              projectId: testProjectId,
            );
            await queue.next;
            syncUnrelatedEstimate();
            final emission = await queue.next;

            expect(estimateIn(emission).estimateName, newEstimateName);
            expectNeighbourUntouched([emission]);
            fakeSupabaseWrapper.completer!.complete();
            await renaming;
            await queue.cancel();
          },
        );
      });

      group('a lock', () {
        test('does not flip back when the phone copy re-emits', () async {
          final queue = await watchSeeded([
            projectEstimate(),
            neighbourEstimate(),
          ]);

          await repository.changeLockStatus(
            estimationId: estimateIdDefault,
            isLocked: true,
            projectId: testProjectId,
          );
          syncUnrelatedEstimate();

          final emissions = await queue.take(3);
          expect(estimateIn(emissions.last).lockStatus.isLocked, isTrue);
          expectNeighbourUntouched(emissions);
          await queue.cancel();
        });

        test('stops being re-applied once the phone copy shows it', () async {
          final queue = await watchSeeded([projectEstimate()]);
          await repository.changeLockStatus(
            estimationId: estimateIdDefault,
            isLocked: true,
            projectId: testProjectId,
          );
          await queue.take(2);
          fakePhoneDatabase.replaceRow(projectEstimate(isLocked: true));
          await queue.next;

          fakePhoneDatabase.replaceRow(projectEstimate(isLocked: false));

          expect(estimateIn(await queue.next).lockStatus.isLocked, isFalse);
          await queue.cancel();
        });

        test(
          'keeps a name the phone copy received while the lock was pending',
          () async {
            final queue = await watchSeeded([projectEstimate()]);
            await repository.changeLockStatus(
              estimationId: estimateIdDefault,
              isLocked: true,
              projectId: testProjectId,
            );
            await queue.take(2);

            const nameChangedElsewhere = 'Renamed on another phone';
            fakePhoneDatabase.replaceRow(
              projectEstimate(estimateName: nameChangedElsewhere),
            );

            final emission = await queue.next;
            expect(estimateIn(emission).estimateName, nameChangedElsewhere);
            expect(estimateIn(emission).lockStatus.isLocked, isTrue);
            await queue.cancel();
          },
        );

        test('that fails online shows it unlocked again', () async {
          final queue = await watchSeeded([
            projectEstimate(),
            neighbourEstimate(),
          ]);
          fakeSupabaseWrapper.shouldThrowOnUpdate = true;
          fakeSupabaseWrapper.updateExceptionType =
              SupabaseExceptionType.timeout;

          await repository.changeLockStatus(
            estimationId: estimateIdDefault,
            isLocked: true,
            projectId: testProjectId,
          );
          syncUnrelatedEstimate();

          final emissions = await queue.take(3);
          expect(estimateIn(emissions.last).lockStatus.isLocked, isFalse);
          expectNeighbourUntouched(emissions);
          await queue.cancel();
        });

        test(
          'is shown when the phone copy re-emits before the server answers',
          () async {
            final queue = await watchSeeded([
              projectEstimate(),
              neighbourEstimate(),
            ]);
            fakeSupabaseWrapper.shouldDelayOperations = true;
            fakeSupabaseWrapper.completer = Completer();

            final locking = repository.changeLockStatus(
              estimationId: estimateIdDefault,
              isLocked: true,
              projectId: testProjectId,
            );
            await queue.next;
            syncUnrelatedEstimate();
            final emission = await queue.next;

            expect(estimateIn(emission).lockStatus.isLocked, isTrue);
            expectNeighbourUntouched([emission]);
            fakeSupabaseWrapper.completer!.complete();
            await locking;
            await queue.cancel();
          },
        );
      });

      test(
        'a delete made online does not bring the estimate back when the phone copy re-emits',
        () async {
          final queue = await watchSeeded([
            projectEstimate(),
            projectEstimate(id: estimateId2, createdAt: timestamp2),
          ]);

          await repository.deleteEstimation(estimateIdDefault, testProjectId);
          syncUnrelatedEstimate();

          final emissions = await queue.take(2);
          expect(idsIn(emissions.last), [estimateId2, unrelatedEstimateId]);
          await queue.cancel();
        },
      );

      test(
        'a delete that fails does not hide the estimate when the phone copy re-emits',
        () async {
          final queue = await watchSeeded([
            projectEstimate(),
            projectEstimate(id: estimateId2, createdAt: timestamp2),
          ]);
          fakeSupabaseWrapper.shouldThrowOnDelete = true;
          fakeSupabaseWrapper.deleteExceptionType =
              SupabaseExceptionType.timeout;

          await repository.deleteEstimation(estimateIdDefault, testProjectId);
          await queue.take(2);
          syncUnrelatedEstimate();

          expect(
            idsIn(await queue.next),
            containsAll([estimateIdDefault, estimateId2]),
          );
          await queue.cancel();
        },
      );

      test(
        'a created estimate does not vanish when the phone copy re-emits before it syncs',
        () async {
          final queue = await watchSeeded([projectEstimate()]);
          final created = buildEstimationDto(
            id: estimateId2,
            projectId: testProjectId,
            estimateName: estimateName2,
            createdAt: timestamp2,
            updatedAt: timestamp2,
          ).toDomain();

          final createdId = (await repository.createEstimation(
            created,
          )).getRightOrNull()!.id;
          syncUnrelatedEstimate();

          final emissions = await queue.take(2);
          expect(idsIn(emissions.last), [
            createdId,
            estimateIdDefault,
            unrelatedEstimateId,
          ]);
          await queue.cancel();
        },
      );

      group('with two projects watched', () {
        test(
          'a delete is not cleared by the other project re-emitting',
          () async {
            final queue = await watchSeeded([
              projectEstimate(),
              neighbourEstimate(),
            ]);
            final otherQueue = await watchProject(otherProjectId, 0);
            await repository.deleteEstimation(estimateIdDefault, testProjectId);
            await queue.next;

            syncOtherProjectEstimate();
            await otherQueue.next;
            syncUnrelatedEstimate();

            expect(idsIn(await queue.next), [estimateId3, unrelatedEstimateId]);
            await queue.cancel();
            await otherQueue.cancel();
          },
        );

        test('a created estimate is not shown in the other project', () async {
          final queue = await watchSeeded([projectEstimate()]);
          final otherQueue = await watchProject(otherProjectId, 0);
          final created = buildEstimationDto(
            id: estimateId2,
            projectId: testProjectId,
            estimateName: estimateName2,
            createdAt: timestamp2,
            updatedAt: timestamp2,
          ).toDomain();
          await repository.createEstimation(created);
          await queue.next;

          syncOtherProjectEstimate();

          expect(idsIn(await otherQueue.next), [otherProjectEstimateId]);
          await queue.cancel();
          await otherQueue.cancel();
        });
      });

      group('when nobody watches the project', () {
        test('a pending rename is forgotten', () async {
          final queue = await watchSeeded([projectEstimate()]);
          await repository.renameEstimation(
            estimationId: estimateIdDefault,
            newName: newEstimateName,
            projectId: testProjectId,
          );
          await queue.cancel();

          final reopened = await watchProject(testProjectId, 1);
          fakePhoneDatabase.replaceRow(projectEstimate());
          syncUnrelatedEstimate();

          expect(
            estimateIn(await reopened.next).estimateName,
            estimateNameDefault,
          );
          await reopened.cancel();
        });

        test(
          'a pending rename is kept while another list of the project is watched',
          () async {
            final createdAtQueue = await watchSeeded([projectEstimate()]);
            // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
            final updatedAtQueue = StreamQueue(
              repository.watchEstimations(
                testProjectId,
                sortBy: EstimationSortOption.updatedAt,
              ),
            );
            await updatedAtQueue.next;
            await repository.renameEstimation(
              estimationId: estimateIdDefault,
              newName: newEstimateName,
              projectId: testProjectId,
            );
            await createdAtQueue.cancel();

            syncUnrelatedEstimate();
            await updatedAtQueue.take(2);

            expect(
              estimateIn(await updatedAtQueue.next).estimateName,
              newEstimateName,
            );
            await updatedAtQueue.cancel();
          },
        );

        test(
          'a write made meanwhile is not applied to a list opened later',
          () async {
            seedEstimationTable([projectEstimate()]);
            await repository.renameEstimation(
              estimationId: estimateIdDefault,
              newName: newEstimateName,
              projectId: testProjectId,
            );

            // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
            final queue = StreamQueue(
              repository.watchEstimations(testProjectId),
            );

            expect(
              estimateIn(await queue.next).estimateName,
              estimateNameDefault,
            );
            await queue.cancel();
          },
        );
      });

      test(
        'a lock and a rename of the same estimate are both kept when the phone copy re-emits',
        () async {
          final queue = await watchSeeded([projectEstimate()]);
          await repository.changeLockStatus(
            estimationId: estimateIdDefault,
            isLocked: true,
            projectId: testProjectId,
          );
          await repository.renameEstimation(
            estimationId: estimateIdDefault,
            newName: newEstimateName,
            projectId: testProjectId,
          );
          await queue.take(4);
          syncUnrelatedEstimate();

          final reEmitted = estimateIn(await queue.next);
          expect(reEmitted.estimateName, newEstimateName);
          expect(reEmitted.lockStatus.isLocked, isTrue);
          await queue.cancel();
        },
      );

      test(
        'a fetch with nobody watching releases the phone watch once it has answered',
        () async {
          final released = Completer<void>();
          fakePhoneDatabase.syncStreamUnsubscribeSignal = released;

          await repository.fetchInitialEstimations(testProjectId);

          await released.future;
          expect(fakePhoneDatabase.syncStreamUnsubscribes, isNotEmpty);
        },
      );
    });

    group('writes with other estimates in the list', () {
      const newEstimateName = 'Renamed Estimate';

      Map<String, dynamic> projectEstimate({String? id, String? createdAt}) =>
          buildEstimationMap(
            id: id,
            projectId: testProjectId,
            createdAt: createdAt,
          );

      Map<String, dynamic> neighbourEstimate() => buildEstimationMap(
        id: estimateId3,
        projectId: testProjectId,
        estimateName: estimateName3,
        createdAt: '2023-06-01T00:00:00.000Z',
      );

      CostEstimate estimateIn(
        Either<Failure, List<CostEstimate>> result,
        String id,
      ) => result.getRightOrNull()!.firstWhere((e) => e.id == id);

      void expectNeighbourUntouched(
        Either<Failure, List<CostEstimate>> emission,
      ) {
        final neighbour = estimateIn(emission, estimateId3);
        expect(neighbour.estimateName, estimateName3);
        expect(neighbour.lockStatus.isLocked, isFalse);
      }

      Future<StreamQueue<Either<Failure, List<CostEstimate>>>>
      watchTwoEstimates() async {
        seedEstimationTable([projectEstimate(), neighbourEstimate()]);
        // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
        final queue = StreamQueue(repository.watchEstimations(testProjectId));
        await expectLater(
          queue.next,
          completion(rightEstimations(hasLength(2))),
        );
        return queue;
      }

      test('a rename leaves the other estimates as they were', () async {
        final queue = await watchTwoEstimates();

        await repository.renameEstimation(
          estimationId: estimateIdDefault,
          newName: newEstimateName,
          projectId: testProjectId,
        );

        final emissions = await queue.take(2);
        for (final emission in emissions) {
          expect(
            estimateIn(emission, estimateIdDefault).estimateName,
            newEstimateName,
          );
          expectNeighbourUntouched(emission);
        }
        await queue.cancel();
      });

      test('a lock leaves the other estimates as they were', () async {
        final queue = await watchTwoEstimates();

        await repository.changeLockStatus(
          estimationId: estimateIdDefault,
          isLocked: true,
          projectId: testProjectId,
        );

        final emissions = await queue.take(2);
        for (final emission in emissions) {
          expect(
            estimateIn(emission, estimateIdDefault).lockStatus.isLocked,
            isTrue,
          );
          expectNeighbourUntouched(emission);
        }
        await queue.cancel();
      });

      test('a failed rename puts back only the renamed estimate', () async {
        final queue = await watchTwoEstimates();
        fakeSupabaseWrapper.shouldThrowOnUpdate = true;
        fakeSupabaseWrapper.updateExceptionType = SupabaseExceptionType.timeout;

        await repository.renameEstimation(
          estimationId: estimateIdDefault,
          newName: newEstimateName,
          projectId: testProjectId,
        );

        final emissions = await queue.take(2);
        expect(
          estimateIn(emissions.last, estimateIdDefault).estimateName,
          estimateNameDefault,
        );
        for (final emission in emissions) {
          expectNeighbourUntouched(emission);
        }
        await queue.cancel();
      });

      test(
        'a created estimate is not shown twice when the phone copy has it before the server answers',
        () async {
          seedEstimationTable([projectEstimate()]);
          // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
          final queue = StreamQueue(repository.watchEstimations(testProjectId));
          await expectLater(
            queue.next,
            completion(rightEstimations(hasLength(1))),
          );
          fakeSupabaseWrapper.shouldDelayOperations = true;
          fakeSupabaseWrapper.completer = Completer();
          final created = buildEstimationDto(
            id: estimateId2,
            projectId: testProjectId,
            estimateName: estimateName2,
            createdAt: timestamp2,
            updatedAt: timestamp2,
          ).toDomain();

          final creating = repository.createEstimation(created);
          fakePhoneDatabase.seedRows([
            projectEstimate(id: '1', createdAt: timestamp2),
          ]);
          await queue.next;
          fakeSupabaseWrapper.completer!.complete();
          final createdId = (await creating).getRightOrNull()!.id;
          final emission = await queue.next;

          expect(createdId, '1');
          expect(
            emission.getRightOrNull()!.where((e) => e.id == createdId),
            hasLength(1),
          );
          await queue.cancel();
        },
      );

      test('a second fetch does not leave the first caller waiting', () async {
        final activationGate = Completer<void>();
        fakePhoneDatabase.syncStreamActivationGate = activationGate;

        final first = repository.fetchInitialEstimations(testProjectId);
        final second = repository.fetchInitialEstimations(testProjectId);

        await expectLater(first, completion(rightEstimations(isEmpty)));
        activationGate.complete();
        await second;
      });
    });
  });
}

class _TestAppModule extends Module {
  final AppBootstrap appBootstrap;

  _TestAppModule(this.appBootstrap);

  @override
  List<Module> get imports => [EstimationLibraryModule(appBootstrap)];
}
