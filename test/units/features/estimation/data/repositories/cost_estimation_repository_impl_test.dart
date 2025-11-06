import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/data/data_source/interfaces/cost_estimation_data_source.dart';
import 'package:construculator/features/estimation/data/repositories/cost_estimation_repository_impl.dart';
import 'package:construculator/features/estimation/data/testing/fake_cost_estimation_data_source.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/estimation_test_data_map_factory.dart';

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
    late FakeCostEstimationDataSource fakeDataSource;
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
      Modular.replaceInstance<CostEstimationDataSource>(
        FakeCostEstimationDataSource(clock: fakeClock),
      );
      fakeDataSource =
          Modular.get<CostEstimationDataSource>()
              as FakeCostEstimationDataSource;
      repository =
          Modular.get<CostEstimationRepository>()
              as CostEstimationRepositoryImpl;
    });

    tearDownAll(() {
      Modular.dispose();
    });

    setUp(() {
      repository.dispose();
      fakeDataSource.reset();
    });

    group('getEstimations', () {
      test('should return cost estimates when data exists', () async {
        final estimation1 = fakeDataSource.createSampleEstimation(
          id: estimateIdDefault,
          projectId: testProjectId,
          estimateName: estimateNameDefault,
          estimateDescription: estimateDescDefault,
          creatorUserId: userIdDefault,
          totalCost: totalCostDefault,
          isLocked: false,
          createdAt: DateTime.parse(timestampDefault),
          updatedAt: DateTime.parse(timestampDefault),
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
          final otherProjectEstimation = fakeDataSource.createSampleEstimation(
            id: estimateIdDefault,
            projectId: otherProjectId,
            estimateName: estimateNameDefault,
          );

          fakeDataSource.addProjectEstimation(
            otherProjectId,
            otherProjectEstimation,
          );

          final result = await repository.getEstimations(testProjectId);

          expect(result.isRight(), isTrue);
          result.fold(
            (_) => fail('Expected success but got failure'),
            (estimates) => expect(estimates, isEmpty),
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

      test(
        'should return unexpected failure when data source throws server exception',
        () async {
          fakeDataSource.shouldThrowOnGetEstimations = true;
          fakeDataSource.getEstimationsExceptionType =
              SupabaseExceptionType.unknown;
          fakeDataSource.getEstimationsErrorMessage = errorMsgServer;

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
          fakeDataSource.shouldThrowOnGetEstimations = true;
          fakeDataSource.getEstimationsExceptionType =
              SupabaseExceptionType.timeout;
          fakeDataSource.getEstimationsErrorMessage = errorMsgTimeout;

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
          fakeDataSource.shouldThrowOnGetEstimations = true;
          fakeDataSource.getEstimationsExceptionType =
              SupabaseExceptionType.socket;
          fakeDataSource.getEstimationsErrorMessage = 'Connection failed';

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
          fakeDataSource.getEstimationsErrorMessage = 'Format error';
          fakeDataSource.getEstimationsExceptionType =
              SupabaseExceptionType.type;
          fakeDataSource.shouldThrowOnGetEstimations = true;

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
          fakeDataSource.shouldThrowOnGetEstimations = true;
          fakeDataSource.getEstimationsExceptionType =
              SupabaseExceptionType.postgrest;
          fakeDataSource.postgrestErrorCode =
              PostgresErrorCode.connectionFailure;
          fakeDataSource.getEstimationsErrorMessage = 'Connection lost';

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
          fakeDataSource.shouldThrowOnGetEstimations = true;
          fakeDataSource.getEstimationsExceptionType =
              SupabaseExceptionType.postgrest;
          fakeDataSource.postgrestErrorCode = PostgresErrorCode.uniqueViolation;
          fakeDataSource.getEstimationsErrorMessage = 'Unique violation';

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
          final estimation1 = fakeDataSource.createSampleEstimation(
            id: estimateIdDefault,
            projectId: testProjectId,
            estimateName: estimateNameDefault,
            estimateDescription: estimateDescDefault,
            creatorUserId: userIdDefault,
            totalCost: totalCostDefault,
            isLocked: false,
            createdAt: DateTime.parse(timestampDefault),
            updatedAt: DateTime.parse(timestampDefault),
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
            creatorUserId: userIdDefault,
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
        final estimation1 = fakeDataSource.createSampleEstimation(
          id: estimateIdDefault,
          projectId: testProjectId,
          estimateName: estimateNameDefault,
        );

        fakeDataSource.addProjectEstimation(testProjectId, estimation1);

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
        fakeDataSource.addProjectEstimations(testProjectId, []);

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
        final estimationDto = fakeDataSource.createSampleEstimation(
          id: estimateIdDefault,
          projectId: testProjectId,
          estimateName: estimateNameDefault,
          estimateDescription: estimateDescDefault,
          creatorUserId: userIdDefault,
          totalCost: totalCostDefault,
        );
        final estimation = estimationDto.toDomain();

        final result = await repository.createEstimation(estimation);

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected success but got failure'),
          (created) => expect(created, equals(estimation)),
        );
      });

      test('should call data source with correct estimation', () async {
        final estimationDto = fakeDataSource.createSampleEstimation(
          projectId: testProjectId,
          estimateName: estimateNameDefault,
        );
        final estimation = estimationDto.toDomain();

        await repository.createEstimation(estimation);

        final methodCalls = fakeDataSource.getMethodCallsFor(
          'createEstimation',
        );
        expect(methodCalls, hasLength(1));
        final estimationJson = methodCalls.first['estimation'];

        expect(estimationJson, estimationDto.toJson());
      });

      test(
        'should return timeout failure when data source throws timeout',
        () async {
          fakeDataSource.shouldThrowOnCreateEstimation = true;
          fakeDataSource.createEstimationExceptionType =
              SupabaseExceptionType.timeout;
          fakeDataSource.createEstimationErrorMessage = errorMsgTimeout;

          final estimationDto = fakeDataSource.createSampleEstimation();
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
          fakeDataSource.shouldThrowOnCreateEstimation = true;
          fakeDataSource.createEstimationExceptionType =
              SupabaseExceptionType.socket;
          fakeDataSource.createEstimationErrorMessage = 'Connection failed';

          final estimationDto = fakeDataSource.createSampleEstimation();
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
          fakeDataSource.shouldThrowOnCreateEstimation = true;
          fakeDataSource.createEstimationExceptionType =
              SupabaseExceptionType.unknown;
          fakeDataSource.createEstimationErrorMessage = errorMsgServer;

          final estimationDto = fakeDataSource.createSampleEstimation();
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
          final existingEstimation = fakeDataSource.createSampleEstimation(
            id: estimateIdDefault,
            projectId: testProjectId,
            estimateName: estimateNameDefault,
          );

          fakeDataSource.addProjectEstimation(
            testProjectId,
            existingEstimation,
          );

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

          final newEstimationDto = fakeDataSource.createSampleEstimation(
            id: estimateId2,
            projectId: testProjectId,
            estimateName: estimateName2,
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
              expect(estimations[0], equals(existingEstimation.toDomain()));
              expect(estimations[1], equals(newEstimation));
            },
          );

          await subscription.cancel();
        },
      );
    });

    group('dispose', () {
      test('should close all stream controllers and clear caches', () async {
        fakeDataSource.addProjectEstimations(testProjectId, []);
        fakeDataSource.addProjectEstimations(otherProjectId, []);

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
          fakeDataSource.addProjectEstimations(testProjectId, []);

          final stream = repository.watchEstimations(testProjectId);
          final subscription = stream.listen((_) {});

          await pumpEventQueue();

          repository.dispose();

          await subscription.cancel();

          expect(() => repository.dispose(), returnsNormally);
        },
      );
    });
  });
}
