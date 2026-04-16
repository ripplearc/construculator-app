import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/data/models/cost_estimate_dto.dart';
import 'package:construculator/features/estimation/data/repositories/cost_estimation_repository_impl.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_estimation_list_bloc/cost_estimation_list_bloc.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/testing/fake_current_project_notifier.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/clock_test_module.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';
import '../../helpers/estimation_test_data_map_factory.dart';

void main() {
  group('CostEstimationListBloc', () {
    late CostEstimationListBloc bloc;
    late FakeSupabaseWrapper fakeSupabaseWrapper;
    late CostEstimationRepository repository;
    late FakeClockImpl fakeClock;
    late FakeCurrentProjectNotifier fakeCurrentProjectNotifier;
    const String testProjectId = 'test-project-123';
    const String secondProjectId = 'test-project-456';
    const Duration streamDebounceWaitDuration = Duration(milliseconds: 400);

    setUpAll(() {
      fakeClock = FakeClockImpl();
      final bootstrap = FakeAppBootstrapFactory.create(
        supabaseWrapper: FakeSupabaseWrapper(clock: fakeClock),
      );
      Modular.init(_TestModule(bootstrap));
      fakeSupabaseWrapper =
          Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
      repository = Modular.get<CostEstimationRepository>();

      fakeCurrentProjectNotifier = FakeCurrentProjectNotifier(
        initialProjectId: testProjectId,
      );
      Modular.replaceInstance<CurrentProjectNotifier>(
        fakeCurrentProjectNotifier,
      );
    });

    tearDownAll(() {
      Modular.dispose();
    });

    setUp(() {
      fakeSupabaseWrapper.reset();
      fakeCurrentProjectNotifier.reset(projectId: testProjectId);
      bloc = Modular.get<CostEstimationListBloc>();
    });

    tearDown(() {
      repository.dispose();
      bloc.close();
    });

    Map<String, dynamic> buildEstimationMap({
      String? id,
      String? projectId,
      String? estimateName,
      double? totalCost,
      String? createdAt,
      String? updatedAt,
    }) {
      return EstimationTestDataMapFactory.createFakeEstimationData(
        id: id,
        projectId: projectId,
        estimateName: estimateName,
        totalCost: totalCost,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    }

    void seedEstimationTable(List<Map<String, dynamic>> rows) {
      fakeSupabaseWrapper.addTableData(
        DatabaseConstants.costEstimatesTable,
        rows,
      );
    }

    group('Successful loading scenarios', () {
      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should emit loading then loaded state when estimations are available',
        build: () {
          final estimationMap1 = buildEstimationMap(
            id: 'est-1',
            projectId: testProjectId,
            estimateName: 'Test Estimation 1',
            totalCost: 10000.0,
          );
          final estimationMap2 = buildEstimationMap(
            id: 'est-2',
            projectId: testProjectId,
            estimateName: 'Test Estimation 2',
            totalCost: 20000.0,
          );
          seedEstimationTable([estimationMap1, estimationMap2]);
          return bloc;
        },
        act: (bloc) => bloc.add(const CostEstimationListStartWatching()),
        wait: streamDebounceWaitDuration,
        expect: () => [
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListLoaded>()
              .having((state) => state.estimates.length, 'estimates length', 2)
              .having((state) => state.estimates, 'estimates', [
                CostEstimateDto.fromJson(
                  buildEstimationMap(
                    id: 'est-1',
                    projectId: testProjectId,
                    estimateName: 'Test Estimation 1',
                    totalCost: 10000.0,
                  ),
                ).toDomain(),
                CostEstimateDto.fromJson(
                  buildEstimationMap(
                    id: 'est-2',
                    projectId: testProjectId,
                    estimateName: 'Test Estimation 2',
                    totalCost: 20000.0,
                  ),
                ).toDomain(),
              ]),
        ],
      );

      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should emit loading then empty state when no estimations exist',
        build: () {
          seedEstimationTable([]);
          return bloc;
        },
        act: (bloc) => bloc.add(const CostEstimationListStartWatching()),
        wait: streamDebounceWaitDuration,
        expect: () => [
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListEmpty>(),
        ],
      );

      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should handle refresh event and emit correct states',
        build: () {
          final estimationMap = buildEstimationMap(
            id: 'est-1',
            projectId: testProjectId,
            estimateName: 'Refreshed Estimation',
            totalCost: 15000.0,
          );
          seedEstimationTable([estimationMap]);
          return bloc;
        },
        act: (bloc) => bloc.add(const CostEstimationListStartWatching()),
        wait: streamDebounceWaitDuration,
        expect: () => [
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListLoaded>()
              .having((state) => state.estimates.length, 'estimates length', 1)
              .having(
                (state) => state.estimates[0].estimateName,
                'estimate name',
                'Refreshed Estimation',
              ),
        ],
      );
    });

    group('Error handling scenarios', () {
      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should emit loading then error state with connection error when repository returns connection failure',
        build: () {
          fakeSupabaseWrapper.shouldThrowOnSelectPaginated = true;
          fakeSupabaseWrapper.selectPaginatedExceptionType =
              SupabaseExceptionType.socket;
          return bloc;
        },
        act: (bloc) => bloc.add(const CostEstimationListStartWatching()),
        wait: streamDebounceWaitDuration,
        expect: () => [
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListError>()
              .having(
                (state) => state.failure,
                'failure',
                EstimationFailure(
                  errorType: EstimationErrorType.connectionError,
                ),
              )
              .having((state) => state.estimates, 'empty estimates', isEmpty),
        ],
      );

      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should emit loading then error state with parsing error when repository returns parsing failure',
        build: () {
          fakeSupabaseWrapper.shouldThrowOnSelectPaginated = true;
          fakeSupabaseWrapper.selectPaginatedExceptionType =
              SupabaseExceptionType.type;
          return bloc;
        },
        act: (bloc) => bloc.add(const CostEstimationListStartWatching()),
        wait: streamDebounceWaitDuration,
        expect: () => [
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListError>()
              .having(
                (state) => state.failure,
                'failure',
                EstimationFailure(errorType: EstimationErrorType.parsingError),
              )
              .having((state) => state.estimates, 'empty estimates', isEmpty),
        ],
      );

      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should emit loading then error state with timeout error when repository returns timeout failure',
        build: () {
          fakeSupabaseWrapper.shouldThrowOnSelectPaginated = true;
          fakeSupabaseWrapper.selectPaginatedExceptionType =
              SupabaseExceptionType.timeout;
          return bloc;
        },
        act: (bloc) => bloc.add(const CostEstimationListStartWatching()),
        wait: streamDebounceWaitDuration,
        expect: () => [
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListError>()
              .having(
                (state) => state.failure,
                'failure',
                EstimationFailure(errorType: EstimationErrorType.timeoutError),
              )
              .having((state) => state.estimates, 'empty estimates', isEmpty),
        ],
      );
    });

    group('Edge cases', () {
      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should emit error with unexpected failure when start watching with null project id',
        build: () {
          fakeCurrentProjectNotifier.setCurrentProjectId(null);
          return bloc;
        },
        act: (bloc) => bloc.add(const CostEstimationListStartWatching()),
        expect: () => [
          isA<CostEstimationListError>()
              .having((s) => s.failure, 'failure', UnexpectedFailure())
              .having((s) => s.estimates, 'estimates', isEmpty),
        ],
      );

      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should retain existing estimations when stream emits a failure',
        build: () {
          final estimationMap = buildEstimationMap(
            id: 'est-prev-1',
            projectId: testProjectId,
            estimateName: 'Previous Estimation',
            totalCost: 3000.0,
          );
          seedEstimationTable([estimationMap]);
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const CostEstimationListStartWatching());

          await bloc.stream.firstWhere((s) => s is CostEstimationListLoaded);

          fakeSupabaseWrapper.shouldThrowOnSelectPaginated = true;
          fakeSupabaseWrapper.selectPaginatedExceptionType =
              SupabaseExceptionType.unknown;

          await repository.fetchInitialEstimations(testProjectId);
        },
        wait: streamDebounceWaitDuration,
        expect: () => [
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListLoaded>()
              .having((s) => s.estimates.length, 'estimates length', 1)
              .having(
                (s) => s.estimates[0].estimateName,
                'estimate name',
                'Previous Estimation',
              ),
          isA<CostEstimationListError>()
              .having((e) => e.failure, 'failure', UnexpectedFailure())
              .having((e) => e.estimates.length, 'estimates length', 1)
              .having((e) => e.estimates, 'estimates', [
                CostEstimateDto.fromJson(
                  buildEstimationMap(
                    id: 'est-prev-1',
                    projectId: testProjectId,
                    estimateName: 'Previous Estimation',
                    totalCost: 3000.0,
                  ),
                ).toDomain(),
              ]),
        ],
      );

      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should emit unexpected failure and keep loaded estimates when project id becomes null',
        build: () {
          final estimationMap = buildEstimationMap(
            id: 'est-prev-1',
            projectId: testProjectId,
            estimateName: 'Previous Estimation',
            totalCost: 3000.0,
          );
          seedEstimationTable([estimationMap]);
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const CostEstimationListStartWatching());

          await bloc.stream.firstWhere((s) => s is CostEstimationListLoaded);
          fakeCurrentProjectNotifier.setCurrentProjectId(null);
        },
        wait: streamDebounceWaitDuration,
        expect: () => [
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListLoaded>()
              .having((s) => s.estimates.length, 'estimates length', 1)
              .having(
                (s) => s.estimates[0].estimateName,
                'estimate name',
                'Previous Estimation',
              ),
          isA<CostEstimationListError>()
              .having((s) => s.failure, 'failure', UnexpectedFailure())
              .having((s) => s.estimates.length, 'estimates length', 1)
              .having(
                (s) => s.estimates[0].estimateName,
                'estimate name',
                'Previous Estimation',
              ),
        ],
      );
    });

    group('Load more scenarios', () {
      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should emit isLoadingMore then loaded with accumulated estimations',
        build: () {
          final allMaps = List.generate(
            15,
            (i) => buildEstimationMap(
              id: 'est-$i',
              projectId: testProjectId,
              estimateName: 'Estimation $i',
              totalCost: (i + 1) * 1000.0,
            ),
          );
          seedEstimationTable(allMaps);
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const CostEstimationListStartWatching());
          await bloc.stream.firstWhere((s) => s is CostEstimationListLoaded);
          bloc.add(const CostEstimationListLoadMore());
        },
        wait: streamDebounceWaitDuration,
        expect: () => [
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListLoaded>()
              .having(
                (s) => s.estimates.length,
                'first page length',
                CostEstimationRepositoryImpl.defaultPageSize,
              )
              .having((s) => s.hasMore, 'hasMore', isTrue)
              .having((s) => s.isLoadingMore, 'isLoadingMore', isFalse),
          isA<CostEstimationListLoaded>()
              .having((s) => s.isLoadingMore, 'isLoadingMore', isTrue)
              .having(
                (s) => s.estimates.length,
                'estimates during load',
                CostEstimationRepositoryImpl.defaultPageSize,
              ),
          isA<CostEstimationListLoaded>()
              .having((s) => s.isLoadingMore, 'isLoadingMore', isFalse)
              .having((s) => s.hasMore, 'hasMore', isFalse)
              .having(
                (s) => s.estimates.length,
                'estimates after load',
                CostEstimationRepositoryImpl.defaultPageSize,
              ),
          isA<CostEstimationListLoaded>()
              .having((s) => s.estimates.length, 'accumulated length', 15)
              .having((s) => s.hasMore, 'hasMore after load', isFalse)
              .having((s) => s.isLoadingMore, 'isLoadingMore after', isFalse),
        ],
      );

      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should not load more when hasMore is false',
        build: () {
          final maps = List.generate(
            5,
            (i) => buildEstimationMap(
              id: 'est-$i',
              projectId: testProjectId,
              estimateName: 'Estimation $i',
            ),
          );
          seedEstimationTable(maps);
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const CostEstimationListStartWatching());
          await bloc.stream.firstWhere((s) => s is CostEstimationListLoaded);
          bloc.add(const CostEstimationListLoadMore());
        },
        wait: streamDebounceWaitDuration,
        expect: () => [
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListLoaded>()
              .having((s) => s.estimates.length, 'estimates length', 5)
              .having((s) => s.hasMore, 'hasMore', isFalse),
        ],
      );

      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should not load more when state is not CostEstimationListLoaded',
        build: () => bloc,
        act: (bloc) {
          bloc.add(const CostEstimationListLoadMore());
        },
        expect: () => [],
      );

      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should emit loading then error state with preserved estimates when load more fails',
        build: () {
          final allMaps = List.generate(
            CostEstimationRepositoryImpl.defaultPageSize,
            (i) => buildEstimationMap(
              id: 'est-$i',
              projectId: testProjectId,
              estimateName: 'Estimation $i',
              totalCost: (i + 1) * 1000.0,
            ),
          );
          seedEstimationTable(allMaps);
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const CostEstimationListStartWatching());
          await bloc.stream.firstWhere((s) => s is CostEstimationListLoaded);

          fakeSupabaseWrapper.shouldThrowOnSelectPaginated = true;
          fakeSupabaseWrapper.selectPaginatedExceptionType =
              SupabaseExceptionType.timeout;

          bloc.add(const CostEstimationListLoadMore());
        },
        wait: streamDebounceWaitDuration,
        expect: () => [
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListLoaded>()
              .having(
                (s) => s.estimates.length,
                'first page length',
                CostEstimationRepositoryImpl.defaultPageSize,
              )
              .having((s) => s.hasMore, 'hasMore', isTrue),
          isA<CostEstimationListLoaded>().having(
            (s) => s.isLoadingMore,
            'isLoadingMore',
            isTrue,
          ),
          isA<CostEstimationListError>()
              .having(
                (s) => s.estimates.length,
                'preserved estimates',
                CostEstimationRepositoryImpl.defaultPageSize,
              )
              .having(
                (s) => s.failure,
                'failure',
                EstimationFailure(errorType: EstimationErrorType.timeoutError),
              ),
        ],
      );

      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should have hasMore true then false when results are equal to default page size',
        build: () {
          final allMaps = List.generate(
            CostEstimationRepositoryImpl.defaultPageSize,
            (i) => buildEstimationMap(
              id: 'est-$i',
              projectId: testProjectId,
              estimateName: 'Estimation $i',
            ),
          );
          seedEstimationTable(allMaps);
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const CostEstimationListStartWatching());
          await bloc.stream.firstWhere((s) => s is CostEstimationListLoaded);

          bloc.add(const CostEstimationListLoadMore());
        },
        wait: streamDebounceWaitDuration,
        expect: () => [
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListLoaded>()
              .having(
                (s) => s.estimates.length,
                'first page length',
                CostEstimationRepositoryImpl.defaultPageSize,
              )
              .having((s) => s.hasMore, 'hasMore is true initially', isTrue),
          isA<CostEstimationListLoaded>().having(
            (s) => s.isLoadingMore,
            'isLoadingMore is true',
            isTrue,
          ),
          isA<CostEstimationListLoaded>()
              .having((s) => s.isLoadingMore, 'isLoadingMore is false', isFalse)
              .having(
                (s) => s.hasMore,
                'hasMore is false after loadMore',
                isFalse,
              )
              .having(
                (s) => s.estimates.length,
                'estimates length is still same',
                CostEstimationRepositoryImpl.defaultPageSize,
              ),
        ],
      );
    });

    group('Refresh scenarios', () {
      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should re-fetch estimations when refresh event is added',
        build: () {
          final estimationMap = buildEstimationMap(
            id: 'est-1',
            projectId: testProjectId,
            estimateName: 'Original Estimation',
          );
          seedEstimationTable([estimationMap]);
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const CostEstimationListStartWatching());
          await bloc.stream.firstWhere((s) => s is CostEstimationListLoaded);

          fakeSupabaseWrapper.clearTableData(
            DatabaseConstants.costEstimatesTable,
          );
          seedEstimationTable([
            buildEstimationMap(
              id: 'est-1',
              projectId: testProjectId,
              estimateName: 'Original Estimation',
            ),
            buildEstimationMap(
              id: 'est-2',
              projectId: testProjectId,
              estimateName: 'New Estimation',
            ),
          ]);

          bloc.add(const CostEstimationListRefresh());
        },
        wait: streamDebounceWaitDuration,
        expect: () => [
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListLoaded>().having(
            (s) => s.estimates.length,
            'initial count',
            1,
          ),
          isA<CostEstimationListLoaded>().having(
            (s) => s.estimates.length,
            'refreshed count',
            2,
          ),
        ],
      );

      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should not refresh when state is already loading',
        build: () {
          fakeSupabaseWrapper.shouldDelayOperations = true;
          fakeSupabaseWrapper.completer = Completer();
          return bloc;
        },
        act: (bloc) {
          bloc.add(const CostEstimationListStartWatching());
          bloc.add(const CostEstimationListRefresh());
        },
        expect: () => [isA<CostEstimationListLoading>()],
        verify: (_) {
          final calls = fakeSupabaseWrapper.getMethodCallsFor(
            'selectPaginated',
          );
          expect(calls, hasLength(0));
          fakeSupabaseWrapper.completer!.complete();
        },
      );
    });

    group('Stream distinct comparison', () {
      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should compare duplicate failures correctly',
        build: () {
          fakeSupabaseWrapper.shouldThrowOnSelectPaginated = true;
          fakeSupabaseWrapper.selectPaginatedExceptionType =
              SupabaseExceptionType.socket;
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const CostEstimationListStartWatching());
          await bloc.stream.firstWhere((s) => s is CostEstimationListError);
          await repository.fetchInitialEstimations(testProjectId);
        },
        wait: streamDebounceWaitDuration,
        expect: () => [
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListError>(),
        ],
      );

      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should compare duplicate success results correctly',
        build: () {
          final estimationMap = buildEstimationMap(
            id: 'est-1',
            projectId: testProjectId,
          );
          seedEstimationTable([estimationMap]);
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const CostEstimationListStartWatching());
          await bloc.stream.firstWhere((s) => s is CostEstimationListLoaded);
          await repository.fetchInitialEstimations(testProjectId);
        },
        wait: streamDebounceWaitDuration,
        expect: () => [
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListLoaded>(),
        ],
      );
    });

    group('Bloc lifecycle', () {
      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should not react to project changes after close',
        build: () {
          final estimationMap = buildEstimationMap(
            id: 'est-1',
            projectId: testProjectId,
            estimateName: 'Project One Estimate',
          );
          seedEstimationTable([estimationMap]);
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const CostEstimationListStartWatching());
          await bloc.stream.firstWhere((s) => s is CostEstimationListLoaded);

          await bloc.close();

          fakeCurrentProjectNotifier.setCurrentProjectId(secondProjectId);
          await Future<void>.delayed(Duration.zero);
        },
        wait: streamDebounceWaitDuration,
        expect: () => [
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListLoaded>()
              .having((s) => s.estimates.length, 'estimates length', 1)
              .having(
                (s) => s.estimates[0].estimateName,
                'estimate name',
                'Project One Estimate',
              ),
        ],
        verify: (_) {
          final calls = fakeSupabaseWrapper.getMethodCallsFor(
            'selectPaginated',
          );
          expect(calls, hasLength(1));
          expect(fakeCurrentProjectNotifier.projectIdChangedEvents, [
            secondProjectId,
          ]);
        },
      );

      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should re-watch and refetch when current project id changes',
        build: () {
          seedEstimationTable([
            buildEstimationMap(
              id: 'est-project-1',
              projectId: testProjectId,
              estimateName: 'Project One Estimate',
            ),
            buildEstimationMap(
              id: 'est-project-2',
              projectId: secondProjectId,
              estimateName: 'Project Two Estimate',
            ),
          ]);
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const CostEstimationListStartWatching());
          await bloc.stream.firstWhere((s) => s is CostEstimationListLoaded);
          fakeCurrentProjectNotifier.setCurrentProjectId(secondProjectId);
        },
        wait: streamDebounceWaitDuration,
        expect: () => [
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListLoaded>()
              .having((s) => s.estimates.length, 'project 1 length', 1)
              .having(
                (s) => s.estimates[0].estimateName,
                'project 1 estimate name',
                'Project One Estimate',
              ),
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListLoaded>()
              .having((s) => s.estimates.length, 'project 2 length', 1)
              .having(
                (s) => s.estimates[0].estimateName,
                'project 2 estimate name',
                'Project Two Estimate',
              ),
        ],
      );

      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should cancel stream subscription when bloc is fetched again',
        build: () {
          final estimationMap = buildEstimationMap(
            id: 'est-1',
            projectId: testProjectId,
          );
          seedEstimationTable([estimationMap]);
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const CostEstimationListStartWatching());
          await bloc.stream.firstWhere((s) => s is CostEstimationListLoaded);
          bloc.add(const CostEstimationListStartWatching());
        },
        wait: streamDebounceWaitDuration,
        expect: () => [
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListLoaded>(),
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListLoaded>(),
        ],
        verify: (_) async {
          await repository.fetchInitialEstimations(testProjectId);
        },
      );
    });
  });
}

class _TestModule extends Module {
  final AppBootstrap bootstrap;
  _TestModule(this.bootstrap);
  @override
  List<Module> get imports => [ClockTestModule(), EstimationModule(bootstrap)];
}
