import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/domain/enums/estimation_sort_option.dart';
import 'package:construculator/libraries/estimation/testing/never_estimation_repository.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestModule extends Module {
  @override
  void binds(Injector i) {
    i.add<NeverEstimationRepository>(NeverEstimationRepository.new);
  }
}

void main() {
  late NeverEstimationRepository repository;

  setUp(() {
    Modular.init(_TestModule());
    repository = Modular.get<NeverEstimationRepository>();
  });

  tearDown(() {
    Modular.destroy();
  });

  group('NeverEstimationRepository', () {
    test('watchEstimations returns an empty stream', () async {
      final stream = repository.watchEstimations(
        'project-1',
        sortBy: EstimationSortOption.updatedAt,
        ascending: true,
        limit: 5,
      );

      await expectLater(stream, emitsDone);
    });

    test('fetchInitialEstimations returns an empty list', () async {
      final result = await repository.fetchInitialEstimations(
        'project-1',
        sortBy: EstimationSortOption.updatedAt,
        ascending: true,
        limit: 5,
      );

      expect(result.isRight(), isTrue);
      expect(result.getRightOrNull(), isEmpty);
    });

    test('loadMoreEstimations returns an empty list', () async {
      final result = await repository.loadMoreEstimations(
        'project-1',
        sortBy: EstimationSortOption.updatedAt,
        ascending: true,
        limit: 5,
      );

      expect(result.isRight(), isTrue);
      expect(result.getRightOrNull(), isEmpty);
    });

    test('hasMoreEstimations returns false', () {
      expect(
        repository.hasMoreEstimations(
          'project-1',
          sortBy: EstimationSortOption.updatedAt,
          ascending: true,
          limit: 5,
        ),
        isFalse,
      );
    });

    test('createEstimation returns UnexpectedFailure', () async {
      final estimation = CostEstimate.defaultEstimate(
        createdAt: DateTime(2025, 1, 1),
      );

      final result = await repository.createEstimation(estimation);

      expect(result.isLeft(), isTrue);
      expect(
        result.fold((failure) => failure, (_) => null),
        isA<UnexpectedFailure>(),
      );
    });

    test('deleteEstimation returns UnexpectedFailure', () async {
      final result = await repository.deleteEstimation('est-1', 'project-1');

      expect(result.isLeft(), isTrue);
      expect(
        result.fold((failure) => failure, (_) => null),
        isA<UnexpectedFailure>(),
      );
    });

    test('changeLockStatus returns UnexpectedFailure', () async {
      final result = await repository.changeLockStatus(
        estimationId: 'est-1',
        isLocked: true,
        projectId: 'project-1',
      );

      expect(result.isLeft(), isTrue);
      expect(
        result.fold((failure) => failure, (_) => null),
        isA<UnexpectedFailure>(),
      );
    });

    test('renameEstimation returns UnexpectedFailure', () async {
      final result = await repository.renameEstimation(
        estimationId: 'est-1',
        newName: 'Renamed',
        projectId: 'project-1',
      );

      expect(result.isLeft(), isTrue);
      expect(
        result.fold((failure) => failure, (_) => null),
        isA<UnexpectedFailure>(),
      );
    });

    test('dispose does not throw', () {
      expect(() => repository.dispose(), returnsNormally);
    });
  });
}
