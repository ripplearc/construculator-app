import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/dashboard/domain/usecases/watch_recent_estimations_usecase.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/domain/enums/estimation_sort_option.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/estimation/estimation_library_module.dart';
import 'package:construculator/libraries/estimation/testing/fake_cost_estimation_repository.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/project_library_module.dart';
import 'package:construculator/libraries/project/testing/fake_current_project_notifier.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../utils/fake_app_bootstrap_factory.dart';

class _TestModule extends Module {
  final AppBootstrap appBootstrap;
  _TestModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    ProjectLibraryModule(appBootstrap),
    EstimationLibraryModule(appBootstrap),
  ];

  @override
  void binds(Injector i) {
    i.add<WatchRecentEstimationsUseCase>(
      () => WatchRecentEstimationsUseCase(i(), i()),
    );
  }
}

void main() {
  const testProjectId = 'project-123';

  group('WatchRecentEstimationsUseCase', () {
    late FakeCostEstimationRepository repository;
    late FakeCurrentProjectNotifier currentProjectNotifier;
    late WatchRecentEstimationsUseCase useCase;

    setUpAll(() {
      repository = FakeCostEstimationRepository();
      currentProjectNotifier = FakeCurrentProjectNotifier(
        initialProjectId: testProjectId,
      );
      Modular.init(_TestModule(FakeAppBootstrapFactory.create()));
      Modular.replaceInstance<CostEstimationRepository>(repository);
      Modular.replaceInstance<CurrentProjectNotifier>(currentProjectNotifier);
      useCase = Modular.get<WatchRecentEstimationsUseCase>();
    });

    tearDownAll(() {
      Modular.dispose();
    });

    setUp(() {
      repository.streamToReturn = const Stream.empty();
      repository.lastProjectId = null;
      repository.lastSortBy = null;
      repository.lastAscending = null;
      repository.lastLimit = null;
      currentProjectNotifier.reset(projectId: testProjectId);
    });

    test('RecentEstimationsParams equality considers limit', () {
      expect(
        const RecentEstimationsParams(limit: 3),
        equals(const RecentEstimationsParams(limit: 3)),
      );
      expect(
        const RecentEstimationsParams(limit: 3),
        isNot(equals(const RecentEstimationsParams(limit: 4))),
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
        expect(repository.lastProjectId, testProjectId);
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
