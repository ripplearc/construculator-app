import 'package:construculator/features/dashboard/domain/usecases/watch_recent_estimations_usecase.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/domain/enums/estimation_sort_option.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/estimation/testing/fake_cost_estimation_repository.dart';
import 'package:construculator/libraries/project/testing/fake_current_project_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WatchRecentEstimationsUseCase', () {
    late FakeCostEstimationRepository repository;
    late FakeCurrentProjectNotifier currentProjectNotifier;
    late WatchRecentEstimationsUseCase useCase;

    setUp(() {
      repository = FakeCostEstimationRepository();
      currentProjectNotifier = FakeCurrentProjectNotifier(
        initialProjectId: 'project-123',
      );
      useCase = WatchRecentEstimationsUseCase(
        repository,
        currentProjectNotifier,
      );
    });

    test(
      'delegates to watchEstimations using current project id with updatedAt descending and requested limit',
      () async {
        const params = RecentEstimationsParams(limit: 3);
        const expectedResult = Right<Failure, List<CostEstimate>>([]);
        repository.streamToReturn = Stream.value(expectedResult);

        final resultStream = useCase(params);

        await expectLater(resultStream, emits(expectedResult));
        expect(repository.lastProjectId, 'project-123');
        expect(repository.lastSortBy, EstimationSortOption.updatedAt);
        expect(repository.lastAscending, isFalse);
        expect(repository.lastLimit, 3);
      },
    );

    test('uses the default limit of 5 when not provided', () async {
      currentProjectNotifier.setCurrentProjectId('project-456');
      const params = RecentEstimationsParams();
      const expectedResult = Right<Failure, List<CostEstimate>>([]);
      repository.streamToReturn = Stream.value(expectedResult);

      final resultStream = useCase(params);

      await expectLater(resultStream, emits(expectedResult));
      expect(repository.lastProjectId, 'project-456');
      expect(repository.lastSortBy, EstimationSortOption.updatedAt);
      expect(repository.lastAscending, isFalse);
      expect(repository.lastLimit, 5);
    });

    test('returns failure when there is no current project', () async {
      currentProjectNotifier.setCurrentProjectId(null);

      final resultStream = useCase(const RecentEstimationsParams(limit: 3));

      await expectLater(
        resultStream,
        emits(
          const Left<Failure, List<CostEstimate>>(
            EstimationFailure(errorType: EstimationErrorType.unexpectedError),
          ),
        ),
      );
      expect(repository.lastProjectId, isNull);
      expect(repository.lastSortBy, isNull);
      expect(repository.lastAscending, isNull);
      expect(repository.lastLimit, isNull);
    });

    test('returns failure when current project id is empty string', () async {
      currentProjectNotifier.setCurrentProjectId('');

      final resultStream = useCase(const RecentEstimationsParams(limit: 3));

      await expectLater(
        resultStream,
        emits(
          const Left<Failure, List<CostEstimate>>(
            EstimationFailure(errorType: EstimationErrorType.unexpectedError),
          ),
        ),
      );
      expect(repository.lastProjectId, isNull);
      expect(repository.lastSortBy, isNull);
      expect(repository.lastAscending, isNull);
      expect(repository.lastLimit, isNull);
    });
  });
}
