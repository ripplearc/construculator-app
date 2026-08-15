import 'dart:async';

import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/estimation/data/data_source/interfaces/powersync_cost_estimation_data_source.dart';
import 'package:construculator/libraries/estimation/data/models/cost_estimate_dto.dart';
import 'package:construculator/libraries/estimation/domain/enums/estimation_sort_option.dart';
import 'package:construculator/libraries/estimation/estimation_library_module.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/powersync/testing/fake_powersync_database_wrapper.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../helpers/estimation_test_data_map_factory.dart';

class _TestModule extends Module {
  final AppBootstrap appBootstrap;

  _TestModule(this.appBootstrap);

  @override
  List<Module> get imports => [EstimationLibraryModule(appBootstrap)];
}

void main() {
  group('PowerSyncCostEstimationDataSource', () {
    const projectId = testProjectId;
    const syncStreamName = 'user_cost_estimates';
    const defaultWatchSql =
        'SELECT * FROM cost_estimates WHERE project_id = ? '
        'ORDER BY created_at DESC';

    late FakePowerSyncDatabaseWrapper fakeWrapper;
    late PowerSyncCostEstimationDataSource dataSource;

    setUpAll(() {
      fakeWrapper = FakePowerSyncDatabaseWrapper();
    });

    setUp(() {
      Modular.init(_TestModule(FakeAppBootstrapFactory.create()));
      Modular.replaceInstance<PowerSyncDatabaseWrapper>(fakeWrapper);
      dataSource = Modular.get<PowerSyncCostEstimationDataSource>();
    });

    tearDown(() {
      Modular.destroy();
      fakeWrapper.reset();
    });

    tearDownAll(() {
      fakeWrapper.dispose();
    });

    /// A SQLite-shaped row, where `is_locked` is an integer (0/1) rather than
    /// the boolean Supabase returns.
    Map<String, dynamic> sqliteRow({
      String id = estimateIdDefault,
      bool locked = false,
    }) {
      final row = EstimationTestDataMapFactory.createFakeEstimationData(
        id: id,
        lockedByUserId: locked ? userIdDefault : null,
        lockedAt: locked ? timestampDefault : null,
      );
      row['is_locked'] = locked ? 1 : 0;
      return row;
    }

    group('watchEstimations', () {
      test(
        'activates the on-demand sync stream and maps rows to DTOs',
        () async {
          fakeWrapper.emitWatch(defaultWatchSql, [sqliteRow()]);

          final emission = expectLater(
            dataSource.watchEstimations(projectId: projectId),
            emits(
              isA<List<CostEstimateDto>>().having(
                (dtos) => dtos.single.id,
                'id',
                estimateIdDefault,
              ),
            ),
          );

          await emission;
          expect(fakeWrapper.syncStreamCalls, [syncStreamName]);
          expect(fakeWrapper.watchCalls.single.sql, defaultWatchSql);
          expect(fakeWrapper.watchCalls.single.parameters, [projectId]);
        },
      );

      test('decodes is_locked integer encoding to a bool DTO', () async {
        fakeWrapper.emitWatch(defaultWatchSql, [sqliteRow(locked: true)]);

        await expectLater(
          dataSource.watchEstimations(projectId: projectId),
          emits(
            isA<List<CostEstimateDto>>().having(
              (dtos) => dtos.single.isLocked,
              'isLocked',
              isTrue,
            ),
          ),
        );
      });

      test('builds sort, direction and limit into the watch query', () async {
        final subscription = dataSource
            .watchEstimations(
              projectId: projectId,
              sortBy: EstimationSortOption.updatedAt,
              ascending: true,
              limit: 5,
            )
            .listen((_) {});
        addTearDown(subscription.cancel);

        await pumpEventQueue();

        expect(
          fakeWrapper.watchCalls.single.sql,
          'SELECT * FROM cost_estimates WHERE project_id = ? '
          'ORDER BY updated_at ASC LIMIT ?',
        );
        expect(fakeWrapper.watchCalls.single.parameters, [projectId, 5]);
      });

      test(
        'releases the sync stream when the subscription is cancelled',
        () async {
          final subscription = dataSource
              .watchEstimations(projectId: projectId)
              .listen((_) {});
          await pumpEventQueue();

          expect(fakeWrapper.syncStreamCalls, [syncStreamName]);
          expect(fakeWrapper.syncStreamUnsubscribes, isEmpty);

          await subscription.cancel();

          expect(fakeWrapper.syncStreamUnsubscribes, [syncStreamName]);
        },
      );

      test(
        'does not start watch when cancelled while syncStream is still pending',
        () async {
          fakeWrapper.syncStreamActivationGate = Completer<void>();

          final subscription = dataSource
              .watchEstimations(projectId: projectId)
              .listen((_) {});
          await pumpEventQueue();

          expect(fakeWrapper.syncStreamCalls, [syncStreamName]);
          expect(fakeWrapper.watchCalls, isEmpty);

          await subscription.cancel();
          fakeWrapper.syncStreamActivationGate!.complete();
          await pumpEventQueue();

          expect(fakeWrapper.watchCalls, isEmpty);
          expect(fakeWrapper.syncStreamUnsubscribes, [syncStreamName]);
        },
      );

      test('surfaces a sync-stream activation error on the stream', () async {
        final error = Exception('activation failed');
        fakeWrapper.syncStreamError = error;

        await expectLater(
          dataSource.watchEstimations(projectId: projectId),
          emitsError(same(error)),
        );
      });

      test('forwards watch errors to the stream', () async {
        final error = Exception('watch failed');

        final emission = expectLater(
          dataSource.watchEstimations(projectId: projectId),
          emitsError(same(error)),
        );

        await pumpEventQueue();
        fakeWrapper.emitWatchError(defaultWatchSql, error);

        await emission;
      });
    });

    group('watchEstimationById', () {
      const byIdSql = 'SELECT * FROM cost_estimates WHERE id = ? LIMIT 1';

      test(
        'activates the on-demand sync stream and maps the row to a DTO',
        () async {
          fakeWrapper.emitWatch(byIdSql, [sqliteRow()]);

          final emission = expectLater(
            dataSource.watchEstimationById(id: estimateIdDefault),
            emits(
              isA<CostEstimateDto>().having(
                (dto) => dto.id,
                'id',
                estimateIdDefault,
              ),
            ),
          );

          await emission;
          expect(fakeWrapper.syncStreamCalls, [syncStreamName]);
          expect(fakeWrapper.watchCalls.single.sql, byIdSql);
          expect(fakeWrapper.watchCalls.single.parameters, [estimateIdDefault]);
        },
      );

      test('emits null when no row matches the id', () async {
        fakeWrapper.emitWatch(byIdSql, const []);

        await expectLater(
          dataSource.watchEstimationById(id: estimateIdDefault),
          emits(isNull),
        );
      });

      test('decodes is_locked integer encoding to a bool DTO', () async {
        fakeWrapper.emitWatch(byIdSql, [sqliteRow(locked: true)]);

        await expectLater(
          dataSource.watchEstimationById(id: estimateIdDefault),
          emits(
            isA<CostEstimateDto>().having(
              (dto) => dto.isLocked,
              'isLocked',
              isTrue,
            ),
          ),
        );
      });

      test('re-emits null when the watched row is deleted', () async {
        fakeWrapper.emitWatch(byIdSql, [sqliteRow()]);

        final emission = expectLater(
          dataSource.watchEstimationById(id: estimateIdDefault),
          emitsInOrder([isA<CostEstimateDto>(), isNull]),
        );

        await pumpEventQueue();
        fakeWrapper.emitWatch(byIdSql, const []);

        await emission;
      });

      test('emits the row once it syncs down after an empty result', () async {
        fakeWrapper.emitWatch(byIdSql, const []);

        final emission = expectLater(
          dataSource.watchEstimationById(id: estimateIdDefault),
          emitsInOrder([isNull, isA<CostEstimateDto>()]),
        );

        await pumpEventQueue();
        fakeWrapper.emitWatch(byIdSql, [sqliteRow()]);

        await emission;
      });

      test('drops emissions that rebuild an identical DTO', () async {
        fakeWrapper.emitWatch(byIdSql, [sqliteRow()]);

        final emitted = <CostEstimateDto?>[];
        final subscription = dataSource
            .watchEstimationById(id: estimateIdDefault)
            .listen(emitted.add);
        addTearDown(subscription.cancel);

        await pumpEventQueue();
        // An unrelated change to `cost_estimates` re-fires the same row.
        fakeWrapper.emitWatch(byIdSql, [sqliteRow()]);
        await pumpEventQueue();

        expect(emitted, hasLength(1));

        fakeWrapper.emitWatch(byIdSql, [sqliteRow(locked: true)]);
        await pumpEventQueue();

        expect(emitted, hasLength(2));
        expect(emitted.last!.isLocked, isTrue);
      });

      test(
        'releases the sync stream when the subscription is cancelled',
        () async {
          final subscription = dataSource
              .watchEstimationById(id: estimateIdDefault)
              .listen((_) {});
          await pumpEventQueue();

          expect(fakeWrapper.syncStreamCalls, [syncStreamName]);
          expect(fakeWrapper.syncStreamUnsubscribes, isEmpty);

          await subscription.cancel();

          expect(fakeWrapper.syncStreamUnsubscribes, [syncStreamName]);
        },
      );

      test('surfaces a sync-stream activation error on the stream', () async {
        final error = Exception('activation failed');
        fakeWrapper.syncStreamError = error;

        await expectLater(
          dataSource.watchEstimationById(id: estimateIdDefault),
          emitsError(same(error)),
        );
      });

      test('forwards watch errors to the stream', () async {
        final error = Exception('watch failed');

        final emission = expectLater(
          dataSource.watchEstimationById(id: estimateIdDefault),
          emitsError(same(error)),
        );

        await pumpEventQueue();
        fakeWrapper.emitWatchError(byIdSql, error);

        await emission;
      });
    });

    group('getEstimations', () {
      test(
        'returns mapped DTOs from a one-shot read without activating sync',
        () async {
          fakeWrapper.stubGetAll(defaultWatchSql, [sqliteRow()]);

          final result = await dataSource.getEstimations(projectId: projectId);

          expect(result.single.id, estimateIdDefault);
          expect(fakeWrapper.getAllCalls.single.sql, defaultWatchSql);
          expect(fakeWrapper.getAllCalls.single.parameters, [projectId]);
          expect(fakeWrapper.syncStreamCalls, isEmpty);
        },
      );

      test('builds sort, direction and limit into the read query', () async {
        const sortedSql =
            'SELECT * FROM cost_estimates WHERE project_id = ? '
            'ORDER BY updated_at ASC LIMIT ?';
        fakeWrapper.stubGetAll(sortedSql, [sqliteRow()]);

        await dataSource.getEstimations(
          projectId: projectId,
          sortBy: EstimationSortOption.updatedAt,
          ascending: true,
          limit: 5,
        );

        expect(fakeWrapper.getAllCalls.single.sql, sortedSql);
        expect(fakeWrapper.getAllCalls.single.parameters, [projectId, 5]);
      });

      test('rethrows read errors', () async {
        final error = Exception('read failed');
        fakeWrapper.getAllError = error;

        await expectLater(
          dataSource.getEstimations(projectId: projectId),
          throwsA(same(error)),
        );
      });
    });
  });
}
