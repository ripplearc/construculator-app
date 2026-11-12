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
import 'package:construculator/libraries/estimation/testing/fake_cost_estimates_database.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../utils/fake_app_bootstrap_factory.dart';
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
    final fakeClock = FakeClockImpl();

    setUp(() {
      fakeClock.set(DateTime.parse('2026-06-01T00:00:00.000Z'));
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
      CostEstimate newEstimate({
        String id = '',
        String projectId = testProjectId,
        String createdAt = timestamp2,
      }) => buildEstimationDto(
        id: id,
        projectId: projectId,
        estimateName: estimateName2,
        createdAt: createdAt,
        updatedAt: createdAt,
      ).toDomain();

      test('should give an estimation with no id one on the phone', () async {
        final result = await repository.createEstimation(newEstimate());

        expectResult(result, (created) {
          expect(
            created.id,
            matches(
              RegExp(
                r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
              ),
            ),
          );
          expect(created.estimateName, estimateName2);
          expect(created.projectId, testProjectId);
        });
      });

      test('should keep the id an estimation already has', () async {
        final result = await repository.createEstimation(
          newEstimate(id: estimateId2),
        );

        expect(result.getRightOrNull()!.id, estimateId2);
      });

      test(
        'should write the estimation to the phone, not the server',
        () async {
          await repository.createEstimation(newEstimate(id: estimateId2));

          final write = fakePhoneDatabase.executeCalls.single;
          expect(write.sql, startsWith('INSERT INTO cost_estimates'));
          expect(write.parameters, contains(estimateName2));
          expect(fakeSupabaseWrapper.getMethodCallsFor('insert'), isEmpty);
        },
      );

      test(
        'should show the new estimation first in the watched list at once',
        () async {
          seedEstimationTable([
            buildEstimationMap(
              id: estimateIdDefault,
              projectId: testProjectId,
              createdAt: timestampDefault,
              updatedAt: timestampDefault,
            ),
          ]);
          // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
          final queue = StreamQueue(repository.watchEstimations(testProjectId));
          await queue.next;

          final created = (await repository.createEstimation(
            newEstimate(id: estimateId2),
          )).getRightOrNull()!;

          final shown = (await queue.next).getRightOrNull()!;
          expect(shown.map((e) => e.id), [created.id, estimateIdDefault]);
          await queue.cancel();
        },
      );

      test('should not show the new estimation in another project', () async {
        // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
        final otherQueue = StreamQueue(
          repository.watchEstimations('other-project'),
        );
        await otherQueue.next;

        await repository.createEstimation(newEstimate(id: estimateId2));
        fakePhoneDatabase.seedRows([
          buildEstimationMap(id: 'theirs', projectId: 'other-project'),
        ]);

        final shown = (await otherQueue.next).getRightOrNull()!;
        expect(shown.map((e) => e.id), ['theirs']);
        await otherQueue.cancel();
      });

      test(
        'should return an unexpected failure and show nothing new when the phone write fails',
        () async {
          fakePhoneDatabase.executeError = Exception('disk full');

          final result = await repository.createEstimation(newEstimate());

          expectFailure(
            result,
            (failure) => expect(failure, UnexpectedFailure()),
          );
          fakePhoneDatabase.executeError = null;
          final shown = (await repository.fetchInitialEstimations(
            testProjectId,
          )).getRightOrNull()!;
          expect(shown, isEmpty);
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
      Map<String, dynamic> seedEstimate(String id, {String? createdAt}) {
        final map = buildEstimationMap(
          id: id,
          projectId: testProjectId,
          createdAt: createdAt,
        );
        fakePhoneDatabase.seedRows([map]);
        return map;
      }

      test(
        'should return Right(null) and remove the estimation from the watched list',
        () async {
          seedEstimate('keep', createdAt: timestamp3);
          seedEstimate(estimateIdDefault, createdAt: timestamp2);
          // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
          final queue = StreamQueue(repository.watchEstimations(testProjectId));
          await queue.next;

          final result = await repository.deleteEstimation(
            estimateIdDefault,
            testProjectId,
          );

          expect(result.isRight(), isTrue);
          final shown = (await queue.next).getRightOrNull()!;
          expect(shown.map((e) => e.id), ['keep']);
          await queue.cancel();
        },
      );

      test('should delete only that row on the phone', () async {
        seedEstimate(estimateIdDefault);

        await repository.deleteEstimation(estimateIdDefault, testProjectId);

        final write = fakePhoneDatabase.executeCalls.single;
        expect(write.sql, 'DELETE FROM cost_estimates WHERE id = ?');
        expect(write.parameters, [estimateIdDefault]);
        expect(fakeSupabaseWrapper.getMethodCallsFor('delete'), isEmpty);
      });

      test(
        'should return Right(null) when the phone no longer has the estimation',
        () async {
          final result = await repository.deleteEstimation(
            estimateIdDefault,
            testProjectId,
          );

          expect(result.isRight(), isTrue);
        },
      );

      test(
        'should return an unexpected failure and keep the estimation when the phone write fails',
        () async {
          seedEstimate(estimateIdDefault);
          fakePhoneDatabase.executeError = Exception('disk full');

          final result = await repository.deleteEstimation(
            estimateIdDefault,
            testProjectId,
          );

          expectFailure(
            result,
            (failure) => expect(failure, UnexpectedFailure()),
          );
          fakePhoneDatabase.executeError = null;
          final shown = (await repository.fetchInitialEstimations(
            testProjectId,
          )).getRightOrNull()!;
          expect(shown.map((e) => e.id), [estimateIdDefault]);
        },
      );

      test(
        'should keep hasMore false after deleting from a list that fits one page',
        () async {
          for (var i = 0; i < 3; i++) {
            seedEstimate('e$i', createdAt: '2026-01-0${i + 1}T00:00:00.000Z');
          }
          await repository.fetchInitialEstimations(testProjectId);

          await repository.deleteEstimation('e0', testProjectId);

          expect(repository.hasMoreEstimations(testProjectId), isFalse);
        },
      );
    });

    group('changeLockStatus', () {
      Map<String, dynamic> seedOneEstimate({bool isLocked = false}) {
        final map = buildEstimationMap(
          id: estimateIdDefault,
          projectId: testProjectId,
          isLocked: isLocked,
        );
        fakePhoneDatabase.seedRows([map]);
        return map;
      }

      test(
        'should return the locked estimation and show it in the watched list',
        () async {
          seedOneEstimate();
          // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
          final queue = StreamQueue(repository.watchEstimations(testProjectId));
          await queue.next;

          final result = await repository.changeLockStatus(
            estimationId: estimateIdDefault,
            isLocked: true,
            projectId: testProjectId,
          );

          expectResult(
            result,
            (locked) => expect(locked.lockStatus.isLocked, isTrue),
          );
          final shown = (await queue.next).getRightOrNull()!;
          expect(shown.single.lockStatus.isLocked, isTrue);
          await queue.cancel();
        },
      );

      test(
        'should return the unlocked estimation and show it in the watched list',
        () async {
          seedOneEstimate(isLocked: true);
          // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
          final queue = StreamQueue(repository.watchEstimations(testProjectId));
          await queue.next;

          final result = await repository.changeLockStatus(
            estimationId: estimateIdDefault,
            isLocked: false,
            projectId: testProjectId,
          );

          expectResult(
            result,
            (unlocked) => expect(unlocked.lockStatus.isLocked, isFalse),
          );
          final shown = (await queue.next).getRightOrNull()!;
          expect(shown.single.lockStatus.isLocked, isFalse);
          await queue.cancel();
        },
      );

      test('should write only is_locked to the phone', () async {
        seedOneEstimate();

        await repository.changeLockStatus(
          estimationId: estimateIdDefault,
          isLocked: true,
          projectId: testProjectId,
        );

        final write = fakePhoneDatabase.executeCalls.single;
        expect(
          write.sql,
          'UPDATE cost_estimates SET is_locked = ? WHERE id = ?',
        );
        expect(write.parameters, [1, estimateIdDefault]);
        expect(fakeSupabaseWrapper.getMethodCallsFor('update'), isEmpty);
      });

      test(
        'should return notFoundError and write nothing when the phone has no such estimation',
        () async {
          final result = await repository.changeLockStatus(
            estimationId: estimateIdDefault,
            isLocked: true,
            projectId: testProjectId,
          );

          expectFailure(
            result,
            (failure) => expect(
              failure,
              EstimationFailure(errorType: EstimationErrorType.notFoundError),
            ),
          );
          expect(fakePhoneDatabase.executeCalls, isEmpty);
        },
      );

      test(
        'should return an unexpected failure and keep the lock as it was when the phone write fails',
        () async {
          seedOneEstimate();
          fakePhoneDatabase.executeError = Exception('disk full');

          final result = await repository.changeLockStatus(
            estimationId: estimateIdDefault,
            isLocked: true,
            projectId: testProjectId,
          );

          expectFailure(
            result,
            (failure) => expect(failure, UnexpectedFailure()),
          );
          fakePhoneDatabase.executeError = null;
          final shown = (await repository.fetchInitialEstimations(
            testProjectId,
          )).getRightOrNull()!;
          expect(shown.single.lockStatus.isLocked, isFalse);
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

      test(
        'should return an estimation only the phone has, as the phone has it',
        () async {
          final map = buildEstimationMap(
            id: estimateIdDefault,
            projectId: testProjectId,
            estimateName: 'Created offline',
          );
          fakePhoneDatabase.seedRows([map]);

          final result = await repository.getEstimation(estimateIdDefault);

          expect(
            result.getRightOrNull(),
            equals(CostEstimateDto.fromJson(map).toDomain()),
          );
        },
      );

      test(
        'should prefer the phone row over an older server row for the same estimation',
        () async {
          fakePhoneDatabase.seedRows([
            buildEstimationMap(
              id: estimateIdDefault,
              projectId: testProjectId,
              estimateName: 'Renamed on the phone',
            ),
          ]);
          fakeSupabaseWrapper
              .addTableData(DatabaseConstants.costEstimatesTable, [
                buildEstimationMap(
                  id: estimateIdDefault,
                  projectId: testProjectId,
                  estimateName: 'Old server name',
                ),
              ]);

          final result = await repository.getEstimation(estimateIdDefault);

          expect(result.getRightOrNull()!.estimateName, 'Renamed on the phone');
        },
      );

      test(
        'should ask the server when the phone has no row for the estimation',
        () async {
          fakeSupabaseWrapper
              .addTableData(DatabaseConstants.costEstimatesTable, [
                buildEstimationMap(
                  id: estimateIdDefault,
                  projectId: testProjectId,
                  estimateName: 'Only on the server',
                ),
              ]);

          final result = await repository.getEstimation(estimateIdDefault);

          expect(result.getRightOrNull()!.estimateName, 'Only on the server');
        },
      );

      test(
        'should return a failure when the phone cannot be read, without asking the server',
        () async {
          fakePhoneDatabase.getAllError = Exception('database is locked');
          fakeSupabaseWrapper.addTableData(DatabaseConstants.costEstimatesTable, [
            buildEstimationMap(
              id: estimateIdDefault,
              projectId: testProjectId,
            ),
          ]);

          final result = await repository.getEstimation(estimateIdDefault);

          expect(result.getLeftOrNull(), isA<UnexpectedFailure>());
          expect(fakeSupabaseWrapper.getMethodCallsFor('selectSingle'), isEmpty);
        },
      );

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

      Map<String, dynamic> seedOneEstimate() {
        final map = buildEstimationMap(
          id: estimateIdDefault,
          projectId: testProjectId,
          estimateName: estimateNameDefault,
          createdAt: timestamp2,
          updatedAt: timestamp2,
        );
        fakePhoneDatabase.seedRows([map]);
        return map;
      }

      test(
        'should return the renamed estimation and show it in the watched list',
        () async {
          final expected = CostEstimateDto.fromJson(
            seedOneEstimate(),
          ).toDomain();
          // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
          final queue = StreamQueue(repository.watchEstimations(testProjectId));
          await expectLater(
            queue.next,
            completion(rightEstimations(equals([expected]))),
          );

          final result = await repository.renameEstimation(
            estimationId: estimateIdDefault,
            newName: newEstimateName,
            projectId: testProjectId,
          );

          expectResult(
            result,
            (renamed) => expect(
              renamed,
              equals(expected.copyWith(estimateName: newEstimateName)),
            ),
          );
          await expectLater(
            queue.next,
            completion(
              rightEstimations(
                equals([expected.copyWith(estimateName: newEstimateName)]),
              ),
            ),
          );
          await queue.cancel();
        },
      );

      test(
        'should keep the last edited date of the estimate when it is renamed',
        () async {
          seedOneEstimate();

          final result = await repository.renameEstimation(
            estimationId: estimateIdDefault,
            newName: newEstimateName,
            projectId: testProjectId,
          );

          expect(
            result.getRightOrNull()!.updatedAt,
            DateTime.parse(timestamp2),
          );
        },
      );

      test(
        'should keep the order of a list sorted by last edited date',
        () async {
          final older = buildEstimationMap(
            id: 'older',
            projectId: testProjectId,
            createdAt: timestamp2,
            updatedAt: timestamp2,
          );
          final newer = buildEstimationMap(
            id: 'newer',
            projectId: testProjectId,
            createdAt: timestamp3,
            updatedAt: timestamp3,
          );
          fakePhoneDatabase.seedRows([older, newer]);
          // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
          final queue = StreamQueue(
            repository.watchEstimations(
              testProjectId,
              sortBy: EstimationSortOption.updatedAt,
            ),
          );
          await queue.next;

          await repository.renameEstimation(
            estimationId: 'older',
            newName: newEstimateName,
            projectId: testProjectId,
          );

          final shown = (await queue.next).getRightOrNull()!;
          expect(shown.map((e) => e.id), ['newer', 'older']);
          await queue.cancel();
        },
      );

      test('should write only the new name to the phone', () async {
        seedOneEstimate();

        await repository.renameEstimation(
          estimationId: estimateIdDefault,
          newName: newEstimateName,
          projectId: testProjectId,
        );

        final write = fakePhoneDatabase.executeCalls.single;
        expect(
          write.sql,
          'UPDATE cost_estimates SET estimate_name = ? WHERE id = ?',
        );
        expect(write.parameters, [newEstimateName, estimateIdDefault]);
        expect(fakeSupabaseWrapper.getMethodCallsFor('update'), isEmpty);
      });

      test(
        'should return notFoundError and write nothing when the phone has no such estimation',
        () async {
          final result = await repository.renameEstimation(
            estimationId: estimateIdDefault,
            newName: newEstimateName,
            projectId: testProjectId,
          );

          expectFailure(
            result,
            (failure) => expect(
              failure,
              EstimationFailure(errorType: EstimationErrorType.notFoundError),
            ),
          );
          expect(fakePhoneDatabase.executeCalls, isEmpty);
        },
      );

      test(
        'should return an unexpected failure and keep the old name when the phone write fails',
        () async {
          final expected = CostEstimateDto.fromJson(
            seedOneEstimate(),
          ).toDomain();
          // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
          final queue = StreamQueue(repository.watchEstimations(testProjectId));
          await queue.next;
          fakePhoneDatabase.executeError = Exception('disk full');

          final result = await repository.renameEstimation(
            estimationId: estimateIdDefault,
            newName: newEstimateName,
            projectId: testProjectId,
          );

          expectFailure(
            result,
            (failure) => expect(failure, UnexpectedFailure()),
          );
          fakePhoneDatabase.executeError = null;
          final shown = (await repository.fetchInitialEstimations(
            testProjectId,
          )).getRightOrNull()!;
          expect(shown, [expected]);
          await queue.cancel();
        },
      );
    });

    group('the phone watch', () {
      test(
        'a row the phone holds in a form that cannot be read fails the list instead of hanging',
        () async {
          seedEstimationTable([
            buildEstimationMap(
              id: estimateIdDefault,
              projectId: testProjectId,
              createdAt: 'not-a-date',
            ),
          ]);

          final result = await repository.fetchInitialEstimations(
            testProjectId,
          );

          expect(result.getLeftOrNull(), isA<UnexpectedFailure>());
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
