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
        fakeWrapper.watchInvokedSignal = Completer<void>();

        final subscription = dataSource
            .watchEstimations(
              projectId: projectId,
              sortBy: EstimationSortOption.updatedAt,
              ascending: true,
              limit: 5,
            )
            .listen((_) {});
        addTearDown(subscription.cancel);

        await fakeWrapper.watchInvokedSignal!.future;

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
          fakeWrapper.watchInvokedSignal = Completer<void>();

          final subscription = dataSource
              .watchEstimations(projectId: projectId)
              .listen((_) {});
          await fakeWrapper.watchInvokedSignal!.future;

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
          fakeWrapper.syncStreamInvokedSignal = Completer<void>();

          final subscription = dataSource
              .watchEstimations(projectId: projectId)
              .listen((_) {});
          await fakeWrapper.syncStreamInvokedSignal!.future;

          expect(fakeWrapper.syncStreamCalls, [syncStreamName]);
          expect(fakeWrapper.watchCalls, isEmpty);

          fakeWrapper.syncStreamUnsubscribeSignal = Completer<void>();
          await subscription.cancel();
          fakeWrapper.syncStreamActivationGate!.complete();
          await fakeWrapper.syncStreamUnsubscribeSignal!.future;

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
        fakeWrapper.watchInvokedSignal = Completer<void>();

        final emission = expectLater(
          dataSource.watchEstimations(projectId: projectId),
          emitsError(same(error)),
        );

        await fakeWrapper.watchInvokedSignal!.future;
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
        fakeWrapper.watchInvokedSignal = Completer<void>();
        fakeWrapper.emitWatch(byIdSql, [sqliteRow()]);

        final emission = expectLater(
          dataSource.watchEstimationById(id: estimateIdDefault),
          emitsInOrder([isA<CostEstimateDto>(), isNull]),
        );

        await fakeWrapper.watchInvokedSignal!.future;
        fakeWrapper.emitWatch(byIdSql, const []);

        await emission;
      });

      test('emits the row once it syncs down after an empty result', () async {
        fakeWrapper.watchInvokedSignal = Completer<void>();
        fakeWrapper.emitWatch(byIdSql, const []);

        final emission = expectLater(
          dataSource.watchEstimationById(id: estimateIdDefault),
          emitsInOrder([isNull, isA<CostEstimateDto>()]),
        );

        await fakeWrapper.watchInvokedSignal!.future;
        fakeWrapper.emitWatch(byIdSql, [sqliteRow()]);

        await emission;
      });

      test('drops emissions that rebuild an identical DTO', () async {
        fakeWrapper.watchInvokedSignal = Completer<void>();
        fakeWrapper.emitWatch(byIdSql, [sqliteRow()]);

        final emission = expectLater(
          dataSource.watchEstimationById(id: estimateIdDefault),
          emitsInOrder([
            isA<CostEstimateDto>().having(
              (dto) => dto.isLocked,
              'isLocked',
              isFalse,
            ),
            isA<CostEstimateDto>().having(
              (dto) => dto.isLocked,
              'isLocked',
              isTrue,
            ),
          ]),
        );

        await fakeWrapper.watchInvokedSignal!.future;
        // An unrelated change to `cost_estimates` re-fires the same row — must
        // not produce a second, duplicate emission.
        fakeWrapper.emitWatch(byIdSql, [sqliteRow()]);
        fakeWrapper.emitWatch(byIdSql, [sqliteRow(locked: true)]);

        await emission;
      });

      test(
        'releases the sync stream when the subscription is cancelled',
        () async {
          fakeWrapper.watchInvokedSignal = Completer<void>();

          final subscription = dataSource
              .watchEstimationById(id: estimateIdDefault)
              .listen((_) {});
          await fakeWrapper.watchInvokedSignal!.future;

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
        fakeWrapper.watchInvokedSignal = Completer<void>();

        final emission = expectLater(
          dataSource.watchEstimationById(id: estimateIdDefault),
          emitsError(same(error)),
        );

        await fakeWrapper.watchInvokedSignal!.future;
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
    group('loadEstimationById', () {
      const byIdSql = 'SELECT * FROM cost_estimates WHERE id = ? LIMIT 1';

      test('returns the row the phone holds', () async {
        fakeWrapper.stubGetAll(byIdSql, [sqliteRow(id: 'est-1')]);

        final loaded = await dataSource.loadEstimationById('est-1');

        expect(loaded?.id, 'est-1');
        expect(fakeWrapper.getAllCalls.single.parameters, ['est-1']);
      });

      test('decodes is_locked integer encoding to a bool DTO', () async {
        fakeWrapper.stubGetAll(byIdSql, [sqliteRow(id: 'est-1', locked: true)]);

        final loaded = await dataSource.loadEstimationById('est-1');

        expect(loaded?.isLocked, isTrue);
      });

      test('returns null when the phone has no row with the id', () async {
        expect(await dataSource.loadEstimationById('missing'), isNull);
      });

      test('reads once and does not activate the sync stream', () async {
        fakeWrapper.stubGetAll(byIdSql, [sqliteRow(id: 'est-1')]);

        await dataSource.loadEstimationById('est-1');

        expect(fakeWrapper.syncStreamCalls, isEmpty);
        expect(fakeWrapper.watchCalls, isEmpty);
      });

      test('rethrows read errors', () async {
        final error = Exception('read failed');
        fakeWrapper.getAllError = error;

        await expectLater(
          dataSource.loadEstimationById('est-1'),
          throwsA(same(error)),
        );
      });
    });

    group('writes', () {
      const selectByIdSql = 'SELECT * FROM cost_estimates WHERE id = ? LIMIT 1';

      CostEstimateDto newEstimate({String id = '', bool locked = false}) =>
          CostEstimateDto.fromJson(
            EstimationTestDataMapFactory.createFakeEstimationData(
              id: id,
              isLocked: locked,
            ),
          );

      final uuidV4 = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );

      void phoneHasRow(String id, {bool locked = false}) => fakeWrapper
          .stubGetAll(selectByIdSql, [sqliteRow(id: id, locked: locked)]);

      group('insertEstimationRow', () {
        test('writes one INSERT carrying every column of the row', () async {
          final stored = await dataSource.insertEstimationRow(
            newEstimate(id: 'new-1'),
          );

          final call = fakeWrapper.executeCalls.single;
          expect(fakeWrapper.writeTransactionCallCount, 1);
          expect(call.sql, startsWith('INSERT INTO cost_estimates (id, '));
          expect(call.parameters.first, 'new-1');
          expect(
            call.sql.split('VALUES')[1].split('?').length - 1,
            call.parameters.length,
          );
          expect(stored.id, 'new-1');
          expect(stored.estimateName, estimateNameDefault);
        });

        test('writes every column of the row with its value', () async {
          final estimate = newEstimate(id: 'new-1', locked: true);

          await dataSource.insertEstimationRow(estimate);

          final call = fakeWrapper.executeCalls.single;
          final columns = RegExp(
            r'\((.+)\) VALUES',
          ).firstMatch(call.sql)!.group(1)!.split(', ');
          final written = {
            for (var i = 0; i < columns.length; i++)
              columns[i]: call.parameters[i],
          };
          expect(written, {
            'id': 'new-1',
            ...estimate.toJson(),
            'is_locked': 1,
          });
        });

        test('mints an id when the row has none', () async {
          final first = await dataSource.insertEstimationRow(newEstimate());
          final second = await dataSource.insertEstimationRow(newEstimate());

          expect(first.id, matches(uuidV4));
          expect(second.id, matches(uuidV4));
          expect(second.id, isNot(first.id));
          expect(fakeWrapper.executeCalls.first.parameters.first, first.id);
        });

        test(
          'stores is_locked as 1 for a locked row and 0 otherwise',
          () async {
            await dataSource.insertEstimationRow(newEstimate(locked: true));
            await dataSource.insertEstimationRow(newEstimate());

            final lockedIndex = fakeWrapper.executeCalls.first.sql
                .replaceFirst(RegExp(r'\) VALUES.*'), '')
                .split(', ')
                .indexOf('is_locked');
            expect(fakeWrapper.executeCalls[0].parameters[lockedIndex], 1);
            expect(fakeWrapper.executeCalls[1].parameters[lockedIndex], 0);
          },
        );

        test('rethrows a write error', () async {
          final error = Exception('disk full');
          fakeWrapper.executeError = error;

          await expectLater(
            dataSource.insertEstimationRow(newEstimate()),
            throwsA(same(error)),
          );
        });
      });

      group('updateEstimationNameById', () {
        test('changes only the name of a row the phone has', () async {
          fakeWrapper.stubGetAllSequence(selectByIdSql, [
            [sqliteRow(id: 'est-1')],
            [
              {...sqliteRow(id: 'est-1'), 'estimate_name': 'Renamed'},
            ],
          ]);

          final updated = await dataSource.updateEstimationNameById(
            id: 'est-1',
            newName: 'Renamed',
          );

          expect(updated?.id, 'est-1');
          expect(updated?.estimateName, 'Renamed');
          final call = fakeWrapper.executeCalls.single;
          expect(
            call.sql,
            'UPDATE cost_estimates SET estimate_name = ? WHERE id = ?',
          );
          expect(call.parameters, ['Renamed', 'est-1']);
        });

        test('returns null when the row is gone after the write', () async {
          fakeWrapper.stubGetAllSequence(selectByIdSql, [
            [sqliteRow(id: 'est-1')],
            const [],
          ]);

          final updated = await dataSource.updateEstimationNameById(
            id: 'est-1',
            newName: 'Renamed',
          );

          expect(updated, isNull);
          expect(fakeWrapper.executeCalls, hasLength(1));
        });

        test('writes nothing for a name the row already has', () async {
          phoneHasRow('est-1');

          final updated = await dataSource.updateEstimationNameById(
            id: 'est-1',
            newName: estimateNameDefault,
          );

          expect(updated?.estimateName, estimateNameDefault);
          expect(fakeWrapper.executeCalls, isEmpty);
        });

        test(
          'returns null and writes nothing when the phone lacks the row',
          () async {
            final updated = await dataSource.updateEstimationNameById(
              id: 'missing',
              newName: 'Renamed',
            );

            expect(updated, isNull);
            expect(fakeWrapper.executeCalls, isEmpty);
            expect(fakeWrapper.writeTransactionCallCount, 0);
          },
        );

        test('rethrows a read error before writing', () async {
          final error = Exception('read failed');
          fakeWrapper.getAllError = error;

          await expectLater(
            dataSource.updateEstimationNameById(id: 'est-1', newName: 'X'),
            throwsA(same(error)),
          );
          expect(fakeWrapper.executeCalls, isEmpty);
        });
      });

      group('updateEstimationLockById', () {
        test('locks an unlocked row by writing only is_locked', () async {
          fakeWrapper.stubGetAllSequence(selectByIdSql, [
            [sqliteRow(id: 'est-1')],
            [sqliteRow(id: 'est-1', locked: true)],
          ]);

          final updated = await dataSource.updateEstimationLockById(
            id: 'est-1',
            isLocked: true,
          );

          expect(updated?.isLocked, isTrue);
          final call = fakeWrapper.executeCalls.single;
          expect(
            call.sql,
            'UPDATE cost_estimates SET is_locked = ? WHERE id = ?',
          );
          expect(call.parameters, [1, 'est-1']);
        });

        test('unlocks a locked row by writing only is_locked', () async {
          phoneHasRow('est-1', locked: true);

          await dataSource.updateEstimationLockById(
            id: 'est-1',
            isLocked: false,
          );

          expect(fakeWrapper.executeCalls.single.parameters, [0, 'est-1']);
        });

        test('writes nothing for a lock state the row already has', () async {
          phoneHasRow('est-1', locked: true);

          final updated = await dataSource.updateEstimationLockById(
            id: 'est-1',
            isLocked: true,
          );

          expect(updated?.isLocked, isTrue);
          expect(fakeWrapper.executeCalls, isEmpty);
        });

        test(
          'returns null and writes nothing when the phone lacks the row',
          () async {
            final updated = await dataSource.updateEstimationLockById(
              id: 'missing',
              isLocked: true,
            );

            expect(updated, isNull);
            expect(fakeWrapper.executeCalls, isEmpty);
          },
        );
      });

      group('deleteEstimationRowById', () {
        test('deletes a row the phone has', () async {
          phoneHasRow('est-1');

          final deleted = await dataSource.deleteEstimationRowById('est-1');

          expect(deleted, isTrue);
          final call = fakeWrapper.executeCalls.single;
          expect(call.sql, 'DELETE FROM cost_estimates WHERE id = ?');
          expect(call.parameters, ['est-1']);
        });

        test(
          'writes nothing and returns false when the phone lacks the row',
          () async {
            final deleted = await dataSource.deleteEstimationRowById('missing');

            expect(deleted, isFalse);
            expect(fakeWrapper.executeCalls, isEmpty);
          },
        );

        test('rethrows a write error', () async {
          phoneHasRow('est-1');
          final error = Exception('disk full');
          fakeWrapper.executeError = error;

          await expectLater(
            dataSource.deleteEstimationRowById('est-1'),
            throwsA(same(error)),
          );
        });
      });
    });
  });
}
