import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/domain/enums/estimation_sort_option.dart';
import 'package:construculator/libraries/estimation/testing/fake_cost_estimation_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeCostEstimationRepository repository;

  setUp(() {
    repository = FakeCostEstimationRepository();
  });

  group('FakeCostEstimationRepository', () {
    test('watchEstimations returns stream and updates variables', () {
      final stream = repository.watchEstimations(
        'project1',
        sortBy: EstimationSortOption.createdAt,
        ascending: true,
        limit: 10,
      );

      expect(stream, equals(repository.streamToReturn));
      expect(repository.lastProjectId, equals('project1'));
      expect(repository.lastSortBy, equals(EstimationSortOption.createdAt));
      expect(repository.lastAscending, isTrue);
      expect(repository.lastLimit, equals(10));
    });

    test('changeLockStatus throws UnimplementedError', () {
      expect(
        () => repository.changeLockStatus(
          estimationId: '1',
          isLocked: true,
          projectId: 'p1',
        ),
        throwsUnimplementedError,
      );
    });

    test('createEstimation throws UnimplementedError', () {
      final estimation = CostEstimate.defaultEstimate(createdAt: DateTime.now());
      expect(
        () => repository.createEstimation(estimation),
        throwsUnimplementedError,
      );
    });

    test('deleteEstimation throws UnimplementedError', () {
      expect(
        () => repository.deleteEstimation('1', 'p1'),
        throwsUnimplementedError,
      );
    });

    test('dispose does not throw', () {
      expect(() => repository.dispose(), returnsNormally);
    });

    test('fetchInitialEstimations throws UnimplementedError', () {
      expect(
        () => repository.fetchInitialEstimations('p1'),
        throwsUnimplementedError,
      );
    });

    test('hasMoreEstimations throws UnimplementedError', () {
      expect(
        () => repository.hasMoreEstimations('p1'),
        throwsUnimplementedError,
      );
    });

    test('loadMoreEstimations throws UnimplementedError', () {
      expect(
        () => repository.loadMoreEstimations('p1'),
        throwsUnimplementedError,
      );
    });

    test('renameEstimation throws UnimplementedError', () {
      expect(
        () => repository.renameEstimation(
          estimationId: '1',
          newName: 'New Name',
          projectId: 'p1',
        ),
        throwsUnimplementedError,
      );
    });
  });
}
