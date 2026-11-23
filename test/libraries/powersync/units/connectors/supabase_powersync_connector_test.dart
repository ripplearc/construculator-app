import 'dart:convert';

import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/powersync/data/connectors/supabase_powersync_connector.dart';
import 'package:construculator/libraries/powersync/models/schema.dart';
import 'package:construculator/libraries/powersync/powersync_module.dart';
import 'package:construculator/libraries/powersync/testing/fake_cost_item_refusal_database.dart';
import 'package:construculator/libraries/powersync/testing/fake_powersync_database.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  final bootstrap = FakeAppBootstrapFactory.create();
  final fakeSupabase = bootstrap.supabaseWrapper as FakeSupabaseWrapper;
  final fakeEnvLoader = bootstrap.envLoader as FakeEnvLoader;

  late PowerSyncBackendConnector connector;
  late FakePowerSyncDatabase fakeDatabase;

  setUp(() {
    Modular.init(_AppModule(bootstrap));
    fakeDatabase = FakePowerSyncDatabase();
    connector = Modular.get<PowerSyncBackendConnector>();
  });

  tearDown(() {
    fakeSupabase.reset();
    fakeEnvLoader.clearEnvVars();
    Modular.destroy();
  });

  void signIn({String id = 'user-1', String email = 'user@example.com'}) {
    fakeSupabase.setCurrentUser(
      FakeUser(id: id, email: email, createdAt: '2000-01-01T00:00:00.000Z'),
    );
  }

  group('SupabasePowerSyncConnector', () {
    group('fetchCredentials', () {
      test('returns null when POWERSYNC_URL is not configured', () async {
        signIn();

        expect(await connector.fetchCredentials(), isNull);
      });

      test('returns null when POWERSYNC_URL is empty', () async {
        fakeEnvLoader.setEnvVar('POWERSYNC_URL', '');
        signIn();

        expect(await connector.fetchCredentials(), isNull);
      });

      test('returns null when user is not authenticated', () async {
        fakeEnvLoader.setEnvVar('POWERSYNC_URL', 'https://ps.example.com');

        expect(await connector.fetchCredentials(), isNull);
      });

      test('returns null when refreshSession throws', () async {
        fakeEnvLoader.setEnvVar('POWERSYNC_URL', 'https://ps.example.com');
        signIn();
        fakeSupabase.shouldThrowOnRefreshSession = true;

        expect(await connector.fetchCredentials(), isNull);
      });

      test(
        'returns credentials with correct endpoint and access token',
        () async {
          const url = 'https://ps.example.com';
          fakeEnvLoader.setEnvVar('POWERSYNC_URL', url);
          signIn(id: 'user-1');

          final credentials = await connector.fetchCredentials();

          expect(credentials, isNotNull);
          expect(credentials!.endpoint, equals(url));
          expect(credentials.token, equals('fake-access-token-user-1'));
        },
      );

      test('refreshes the session before building credentials', () async {
        fakeEnvLoader.setEnvVar('POWERSYNC_URL', 'https://ps.example.com');
        signIn();

        await connector.fetchCredentials();

        expect(fakeSupabase.getMethodCallsFor('refreshSession'), hasLength(1));
      });
    });

    group('uploadData', () {
      test('returns early when no transaction is pending', () async {
        await connector.uploadData(fakeDatabase);

        expect(fakeSupabase.getMethodCalls(), isEmpty);
      });

      test(
        'PUT dispatches upsert with correct table, data, and onConflict',
        () async {
          fakeDatabase.setNextTransaction(
            FakeCrudTransaction([
              CrudEntry(1, UpdateType.put, 'projects', 'proj-1', null, {
                'name': 'Test',
              }),
            ]),
          );

          await connector.uploadData(fakeDatabase);

          final calls = fakeSupabase.getMethodCallsFor('upsert');
          expect(calls, hasLength(1));
          expect(calls.first['table'], equals('projects'));
          expect(calls.first['data'], containsPair('id', 'proj-1'));
          expect(calls.first['onConflict'], equals('id'));
        },
      );

      test(
        'PUT sends the row id, which PowerSync keeps outside opData',
        () async {
          fakeDatabase.setNextTransaction(
            FakeCrudTransaction([
              CrudEntry(1, UpdateType.put, 'your_rates', 'rate-1', null, {
                'item_name': 'Excavator',
              }),
            ]),
          );

          await connector.uploadData(fakeDatabase);

          final data = fakeSupabase.getMethodCallsFor('upsert').single['data'];
          expect(data, containsPair('id', 'rate-1'));
          expect(data, containsPair('item_name', 'Excavator'));
        },
      );

      test(
        'PUT of a trade store row sends its values as a JSON object',
        () async {
          fakeDatabase.setNextTransaction(
            FakeCrudTransaction([
              CrudEntry(
                1,
                UpdateType.put,
                'user_calculator_stores',
                'row-1',
                null,
                {
                  'user_id': 'user-1',
                  'store_kind': 'density',
                  'values': '{"name": "slag", "pounds_per_cubic_yard": 2900}',
                  'unit_system': 'imperial',
                },
              ),
            ]),
          );

          await connector.uploadData(fakeDatabase);

          final data = fakeSupabase.getMethodCallsFor('upsert').single['data'];
          expect(data, containsPair('id', 'row-1'));
          expect(data, containsPair('store_kind', 'density'));
          expect(
            data['values'],
            equals({'name': 'slag', 'pounds_per_cubic_yard': 2900}),
          );
        },
      );

      test('PATCH of a trade store row decodes values and leaves a patch '
          'without them alone', () async {
        fakeSupabase.addTableData('user_calculator_stores', [
          {'id': 'row-1', 'values': '{}'},
          {'id': 'row-2', 'values': '{}'},
        ]);
        fakeDatabase.setNextTransaction(
          FakeCrudTransaction([
            CrudEntry(
              1,
              UpdateType.patch,
              'user_calculator_stores',
              'row-1',
              null,
              {
                'values': '{"seed": "fence", "rails_per_section": 2}',
                'updated_at': '2026-11-02T10:00:00.000Z',
              },
            ),
            CrudEntry(
              2,
              UpdateType.patch,
              'user_calculator_stores',
              'row-2',
              null,
              {'deleted_at': '2026-11-02T10:00:00.000Z'},
            ),
          ]),
        );

        await connector.uploadData(fakeDatabase);

        final calls = fakeSupabase.getMethodCallsFor('update');
        expect(calls, hasLength(2));
        expect(
          calls.first['data']['values'],
          equals({'seed': 'fence', 'rails_per_section': 2}),
        );
        expect(calls.last['data'], {'deleted_at': '2026-11-02T10:00:00.000Z'});
      });

      test(
        'PUT of a cost item sends its calculation as a JSON object',
        () async {
          fakeDatabase.setNextTransaction(
            FakeCrudTransaction([
              CrudEntry(1, UpdateType.put, 'cost_items', 'line-1', null, {
                'estimate_id': 'estimate-1',
                'item_name': 'Plywood',
                'calculation': '{"unit_price": 10.0, "quantity": 2.0}',
              }),
            ]),
          );

          await connector.uploadData(fakeDatabase);

          final data = fakeSupabase.getMethodCallsFor('upsert').single['data'];
          expect(data, containsPair('id', 'line-1'));
          expect(
            data['calculation'],
            equals({'unit_price': 10.0, 'quantity': 2.0}),
          );
        },
      );

      test('PUT of a cost item sends a null for each column the phone left '
          'out, so a cleared field is cleared on the server', () async {
        fakeDatabase.setNextTransaction(
          FakeCrudTransaction([
            CrudEntry(1, UpdateType.put, 'cost_items', 'line-1', null, {
              'estimate_id': 'estimate-1',
              'calculation': '{}',
            }),
          ]),
        );

        await connector.uploadData(fakeDatabase);

        final data =
            fakeSupabase.getMethodCallsFor('upsert').single['data']
                as Map<String, dynamic>;
        final columns = schema.tables
            .singleWhere((table) => table.name == 'cost_items')
            .columns
            .map((column) => column.name);
        expect(data.keys, unorderedEquals([...columns, 'id']));
        expect(data, containsPair('description', null));
        expect(data, containsPair('estimate_id', 'estimate-1'));
        expect(data, containsPair('calculation', isEmpty));
      });

      test('PUT of another table sends only the columns it has', () async {
        fakeDatabase.setNextTransaction(
          FakeCrudTransaction([
            CrudEntry(1, UpdateType.put, 'projects', 'proj-1', null, {
              'project_name': 'House',
            }),
          ]),
        );

        await connector.uploadData(fakeDatabase);

        final data = fakeSupabase.getMethodCallsFor('upsert').single['data'];
        expect(data.keys, unorderedEquals(['project_name', 'id']));
      });

      test('PATCH of a cost item decodes calculation and sends only what '
          'changed', () async {
        fakeSupabase.addTableData('cost_items', [
          {'id': 'line-1', 'item_name': 'Plywood'},
        ]);
        fakeDatabase.setNextTransaction(
          FakeCrudTransaction([
            CrudEntry(1, UpdateType.patch, 'cost_items', 'line-1', null, {
              'calculation': '{"quantity": 3.0}',
            }),
          ]),
        );

        await connector.uploadData(fakeDatabase);

        final data = fakeSupabase.getMethodCallsFor('update').single['data'];
        expect(data, {
          'calculation': {'quantity': 3.0},
        });
      });

      group('a cost line the server refuses or cannot decode', () {
        final refusedAt = DateTime.utc(2026, 11, 18, 9, 30);
        final phoneLine = <String, Object?>{
          'id': 'line-1',
          'estimate_id': 'estimate-1',
          'item_name': 'Plywood',
          'calculation': '{"quantity": 2.0}',
        };
        late FakeCostItemRefusalDatabase phone;
        late SupabasePowerSyncConnector clockedConnector;

        setUp(() {
          phone = FakeCostItemRefusalDatabase()..seedCostItem(phoneLine);
          clockedConnector = SupabasePowerSyncConnector(
            supabaseWrapper: fakeSupabase,
            envLoader: fakeEnvLoader,
            clock: FakeClockImpl(refusedAt),
          );
        });

        void refuseWithRlsDenial({required bool onUpdate}) {
          if (onUpdate) {
            fakeSupabase.shouldThrowOnUpdate = true;
            fakeSupabase.updateExceptionType = SupabaseExceptionType.postgrest;
          } else {
            fakeSupabase.shouldThrowOnUpsert = true;
            fakeSupabase.upsertExceptionType = SupabaseExceptionType.postgrest;
          }
          fakeSupabase.postgrestErrorCode = PostgresErrorCode.rlsViolation;
        }

        CrudEntry putLine() =>
            CrudEntry(1, UpdateType.put, 'cost_items', 'line-1', null, {
              'estimate_id': 'estimate-1',
              'item_name': 'Plywood',
              'calculation': '{"quantity": 2.0}',
            });

        CrudEntry deleteOtherRow() =>
            CrudEntry(2, UpdateType.delete, 'projects', 'proj-1', null, null);

        test('refused with 42501 on a PUT is recorded with the line, the time '
            'and the reason, and the queue moves on', () async {
          refuseWithRlsDenial(onUpdate: false);
          final transaction = FakeCrudTransaction([
            putLine(),
            deleteOtherRow(),
          ]);
          phone.setNextTransaction(transaction);

          await clockedConnector.uploadData(phone);

          final record = phone.refusals['line-1']!;
          expect(record['estimate_id'], 'estimate-1');
          expect(record['reason'], '42501');
          expect(record['refused_at'], '2026-11-18T09:30:00.000Z');
          expect(jsonDecode(record['line']! as String), phoneLine);
          expect(fakeSupabase.getMethodCallsFor('delete'), hasLength(1));
          expect(transaction.isCompleted, isTrue);
        });

        test('refused with 42501 on a PATCH is recorded and the transaction '
            'completes', () async {
          refuseWithRlsDenial(onUpdate: true);
          final transaction = FakeCrudTransaction([
            CrudEntry(1, UpdateType.patch, 'cost_items', 'line-1', null, {
              'calculation': '{"quantity": 3.0}',
            }),
          ]);
          phone.setNextTransaction(transaction);

          await clockedConnector.uploadData(phone);

          expect(phone.refusals.keys, ['line-1']);
          expect(transaction.isCompleted, isTrue);
        });

        for (final text in ['not json', '']) {
          test('a calculation text of "$text" is recorded as not JSON and '
              'the queue moves on', () async {
            final transaction = FakeCrudTransaction([
              CrudEntry(1, UpdateType.put, 'cost_items', 'line-1', null, {
                'estimate_id': 'estimate-1',
                'calculation': text,
              }),
              deleteOtherRow(),
            ]);
            phone.setNextTransaction(transaction);

            await clockedConnector.uploadData(phone);

            expect(
              phone.refusals['line-1']!['reason'],
              'calculation is not JSON',
            );
            expect(fakeSupabase.getMethodCallsFor('upsert'), isEmpty);
            expect(fakeSupabase.getMethodCallsFor('delete'), hasLength(1));
            expect(transaction.isCompleted, isTrue);
          });
        }

        test('a refused DELETE records nothing and the transaction '
            'completes', () async {
          fakeSupabase.shouldThrowOnDelete = true;
          fakeSupabase.deleteExceptionType = SupabaseExceptionType.postgrest;
          fakeSupabase.postgrestErrorCode = PostgresErrorCode.rlsViolation;
          final transaction = FakeCrudTransaction([
            CrudEntry(1, UpdateType.delete, 'cost_items', 'line-1', null, null),
          ]);
          phone.setNextTransaction(transaction);

          await clockedConnector.uploadData(phone);

          expect(phone.refusals, isEmpty);
          expect(transaction.isCompleted, isTrue);
        });

        test('a later upload of the same line that the server accepts removes '
            'its refusal record', () async {
          refuseWithRlsDenial(onUpdate: false);
          phone.setNextTransaction(FakeCrudTransaction([putLine()]));
          await clockedConnector.uploadData(phone);
          fakeSupabase.shouldThrowOnUpsert = false;
          phone.setNextTransaction(FakeCrudTransaction([putLine()]));

          await clockedConnector.uploadData(phone);

          expect(phone.refusals, isEmpty);
        });

        test(
          'a refusal that cannot be recorded does not stop the queue',
          () async {
            refuseWithRlsDenial(onUpdate: false);
            phone.statementError = StateError('disk full');
            final transaction = FakeCrudTransaction([
              putLine(),
              deleteOtherRow(),
            ]);
            phone.setNextTransaction(transaction);

            await clockedConnector.uploadData(phone);

            expect(fakeSupabase.getMethodCallsFor('delete'), hasLength(1));
            expect(transaction.isCompleted, isTrue);
          },
        );

        test('another server error on a cost line is retried: nothing is '
            'recorded and the transaction stays queued', () async {
          fakeSupabase.shouldThrowOnUpsert = true;
          fakeSupabase.upsertExceptionType = SupabaseExceptionType.timeout;
          final transaction = FakeCrudTransaction([putLine()]);
          phone.setNextTransaction(transaction);

          await expectLater(
            clockedConnector.uploadData(phone),
            throwsA(anything),
          );

          expect(phone.refusals, isEmpty);
          expect(transaction.isCompleted, isFalse);
        });

        test('a 42501 on another table records no cost line refusal', () async {
          refuseWithRlsDenial(onUpdate: false);
          final transaction = FakeCrudTransaction([
            CrudEntry(1, UpdateType.put, 'projects', 'proj-1', null, {
              'project_name': 'House',
            }),
          ]);
          phone.setNextTransaction(transaction);

          await clockedConnector.uploadData(phone);

          expect(phone.refusals, isEmpty);
          expect(transaction.isCompleted, isTrue);
        });
      });

      test(
        'a cost item uploaded twice with one id stays one server row',
        () async {
          for (final changeId in [1, 2]) {
            fakeDatabase.setNextTransaction(
              FakeCrudTransaction([
                CrudEntry(
                  changeId,
                  UpdateType.put,
                  'cost_items',
                  'line-1',
                  null,
                  {
                    'estimate_id': 'estimate-1',
                    'item_name': 'Plywood',
                    'calculation': '{}',
                  },
                ),
              ]),
            );
            await connector.uploadData(fakeDatabase);
          }

          final rows = await fakeSupabase.selectMatch(
            table: 'cost_items',
            filters: const {},
          );
          expect(rows.map((row) => row['id']), ['line-1']);
        },
      );

      test('the later of two uploads of one cost item is the one the server '
          'keeps', () async {
        for (final entry in [(1, 'Plywood'), (2, 'Plywood 3/4 in')]) {
          fakeDatabase.setNextTransaction(
            FakeCrudTransaction([
              CrudEntry(
                entry.$1,
                UpdateType.put,
                'cost_items',
                'line-1',
                null,
                {'item_name': entry.$2, 'calculation': '{}'},
              ),
            ]),
          );
          await connector.uploadData(fakeDatabase);
        }

        final rows = await fakeSupabase.selectMatch(
          table: 'cost_items',
          filters: const {},
        );
        expect(rows.single['item_name'], 'Plywood 3/4 in');
      });

      test('another table\'s JSON text is sent as the text it is', () async {
        fakeDatabase.setNextTransaction(
          FakeCrudTransaction([
            CrudEntry(1, UpdateType.put, 'projects', 'proj-1', null, {
              'values': '{"not": "decoded"}',
            }),
          ]),
        );

        await connector.uploadData(fakeDatabase);

        final data = fakeSupabase.getMethodCallsFor('upsert').single['data'];
        expect(data['values'], '{"not": "decoded"}');
      });

      test('PATCH dispatches update with id as filter', () async {
        fakeSupabase.addTableData('projects', [
          {'id': 'proj-1', 'name': 'Original'},
        ]);
        fakeDatabase.setNextTransaction(
          FakeCrudTransaction([
            CrudEntry(1, UpdateType.patch, 'projects', 'proj-1', null, {
              'name': 'Updated',
            }),
          ]),
        );

        await connector.uploadData(fakeDatabase);

        final calls = fakeSupabase.getMethodCallsFor('update');
        expect(calls, hasLength(1));
        expect(calls.first['table'], equals('projects'));
        expect(calls.first['filterColumn'], equals('id'));
        expect(calls.first['filterValue'], equals('proj-1'));
        expect(calls.first['data'], containsPair('name', 'Updated'));
      });

      test('DELETE dispatches delete with id as filter', () async {
        fakeDatabase.setNextTransaction(
          FakeCrudTransaction([
            CrudEntry(1, UpdateType.delete, 'users', 'user-1', null, null),
          ]),
        );

        await connector.uploadData(fakeDatabase);

        final calls = fakeSupabase.getMethodCallsFor('delete');
        expect(calls, hasLength(1));
        expect(calls.first['table'], equals('users'));
        expect(calls.first['filterColumn'], equals('id'));
        expect(calls.first['filterValue'], equals('user-1'));
      });

      test('completes the transaction after all operations succeed', () async {
        final transaction = FakeCrudTransaction([
          CrudEntry(1, UpdateType.put, 'projects', 'proj-1', null, {
            'id': 'proj-1',
          }),
        ]);
        fakeDatabase.setNextTransaction(transaction);

        await connector.uploadData(fakeDatabase);

        expect(transaction.isCompleted, isTrue);
      });

      test(
        'processes all operations before completing the transaction',
        () async {
          fakeSupabase.addTableData('projects', [
            {'id': 'b', 'name': 'Original'},
          ]);
          final transaction = FakeCrudTransaction([
            CrudEntry(1, UpdateType.put, 'projects', 'a', null, {'id': 'a'}),
            CrudEntry(2, UpdateType.patch, 'projects', 'b', null, {
              'name': 'X',
            }),
            CrudEntry(3, UpdateType.delete, 'users', 'c', null, null),
          ]);
          fakeDatabase.setNextTransaction(transaction);

          await connector.uploadData(fakeDatabase);

          expect(fakeSupabase.getMethodCallsFor('upsert'), hasLength(1));
          expect(fakeSupabase.getMethodCallsFor('update'), hasLength(1));
          expect(fakeSupabase.getMethodCallsFor('delete'), hasLength(1));
          expect(transaction.isCompleted, isTrue);
        },
      );

      test('PUT with null opData throws StateError', () async {
        fakeDatabase.setNextTransaction(
          FakeCrudTransaction([
            CrudEntry(1, UpdateType.put, 'projects', 'proj-1', null, null),
          ]),
        );

        await expectLater(
          connector.uploadData(fakeDatabase),
          throwsA(isA<StateError>()),
        );
      });

      test('PATCH with null opData throws StateError', () async {
        fakeDatabase.setNextTransaction(
          FakeCrudTransaction([
            CrudEntry(1, UpdateType.patch, 'projects', 'proj-1', null, null),
          ]),
        );

        await expectLater(
          connector.uploadData(fakeDatabase),
          throwsA(isA<StateError>()),
        );
      });

      group('error handling', () {
        test(
          'RLS denial (42501) completes transaction without rethrowing',
          () async {
            final localDatabase = FakePowerSyncDatabase();
            fakeSupabase.shouldThrowOnUpsert = true;
            fakeSupabase.upsertExceptionType = SupabaseExceptionType.postgrest;
            fakeSupabase.postgrestErrorCode = PostgresErrorCode.rlsViolation;
            fakeSupabase.upsertErrorMessage =
                'permission denied for table projects';
            final transaction = FakeCrudTransaction([
              CrudEntry(1, UpdateType.put, 'projects', 'proj-1', null, {
                'id': 'proj-1',
              }),
            ]);
            localDatabase.setNextTransaction(transaction);

            await connector.uploadData(localDatabase);

            expect(transaction.isCompleted, isTrue);
          },
        );

        for (final (name, code) in [
          (
            'a value that is not valid (23514)',
            PostgresErrorCode.checkViolation,
          ),
          (
            'a duplicate from another phone (23505)',
            PostgresErrorCode.uniqueViolation,
          ),
        ]) {
          test(
            'your_rates refused for $name completes the transaction',
            () async {
              fakeSupabase.shouldThrowOnUpsert = true;
              fakeSupabase.upsertExceptionType =
                  SupabaseExceptionType.postgrest;
              fakeSupabase.postgrestErrorCode = code;
              final transaction = FakeCrudTransaction([
                CrudEntry(1, UpdateType.put, 'your_rates', 'rate-1', null, {
                  'id': 'rate-1',
                }),
              ]);
              fakeDatabase.setNextTransaction(transaction);

              await connector.uploadData(fakeDatabase);

              expect(transaction.isCompleted, isTrue);
            },
          );
        }

        test('a your_rates upsert the server answers with no row is still '
            'retried', () async {
          fakeSupabase.shouldThrowOnUpsert = true;
          fakeSupabase.upsertExceptionType = SupabaseExceptionType.postgrest;
          fakeSupabase.postgrestErrorCode = PostgresErrorCode.noDataFound;
          final transaction = FakeCrudTransaction([
            CrudEntry(1, UpdateType.put, 'your_rates', 'rate-1', null, {
              'id': 'rate-1',
            }),
          ]);
          fakeDatabase.setNextTransaction(transaction);

          await expectLater(
            connector.uploadData(fakeDatabase),
            throwsA(isA<supabase.PostgrestException>()),
          );
          expect(transaction.isCompleted, isFalse);
        });

        test('a duplicate on another table is still retried', () async {
          fakeSupabase.shouldThrowOnUpsert = true;
          fakeSupabase.upsertExceptionType = SupabaseExceptionType.postgrest;
          fakeSupabase.postgrestErrorCode = PostgresErrorCode.uniqueViolation;
          final transaction = FakeCrudTransaction([
            CrudEntry(1, UpdateType.put, 'projects', 'proj-1', null, {
              'id': 'proj-1',
            }),
          ]);
          fakeDatabase.setNextTransaction(transaction);

          await expectLater(
            connector.uploadData(fakeDatabase),
            throwsA(isA<supabase.PostgrestException>()),
          );
          expect(transaction.isCompleted, isFalse);
        });

        group('a trade store default changed on two phones', () {
          Map<String, dynamic> serverRow({
            required String id,
            String seed = 'masonry_8x16in',
            String? deletedAt,
          }) => {
            'id': id,
            'user_id': 'user-1',
            'store_kind': 'masonry_piece',
            'values': {'seed': seed, 'width_ticks': 512},
            'unit_system': 'imperial',
            'deleted_at': deletedAt,
          };

          final secondPhoneChange = {
            'user_id': 'user-1',
            'store_kind': 'masonry_piece',
            'values': '{"seed": "masonry_8x16in", "width_ticks": 384}',
            'unit_system': 'imperial',
          };

          Future<FakeCrudTransaction> uploadSecondPhone(CrudEntry entry) async {
            fakeSupabase.upsertExceptionType = SupabaseExceptionType.postgrest;
            fakeSupabase.updateExceptionType = SupabaseExceptionType.postgrest;
            fakeSupabase.deleteExceptionType = SupabaseExceptionType.postgrest;
            fakeSupabase.postgrestErrorCode = PostgresErrorCode.uniqueViolation;
            final transaction = FakeCrudTransaction([entry]);
            fakeDatabase.setNextTransaction(transaction);
            await connector.uploadData(fakeDatabase);
            return transaction;
          }

          test('the later upload overwrites the live row of that default; a '
              'deleted row of it and another default are left alone', () async {
            fakeSupabase.addTableData('user_calculator_stores', [
              serverRow(id: 'gone', deletedAt: '2026-11-01T10:00:00.000Z'),
              serverRow(id: 'other', seed: 'masonry_4x8in'),
              serverRow(id: 'server-1'),
            ]);
            fakeSupabase.shouldThrowOnUpsert = true;

            final transaction = await uploadSecondPhone(
              CrudEntry(
                1,
                UpdateType.put,
                'user_calculator_stores',
                'phone-2-id',
                null,
                secondPhoneChange,
              ),
            );

            final update = fakeSupabase.getMethodCallsFor('update').single;
            expect(update['filterValue'], 'server-1');
            expect(update['data']['values'], {
              'seed': 'masonry_8x16in',
              'width_ticks': 384,
            });
            expect(update['data'], isNot(contains('id')));
            expect(transaction.isCompleted, isTrue);
          });

          test(
            'a duplicate whose live row the server does not have is skipped, '
            'never retried',
            () async {
              fakeSupabase.addTableData('user_calculator_stores', [
                serverRow(id: 'gone', deletedAt: '2026-11-01T10:00:00.000Z'),
              ]);
              fakeSupabase.shouldThrowOnUpsert = true;

              final transaction = await uploadSecondPhone(
                CrudEntry(
                  1,
                  UpdateType.put,
                  'user_calculator_stores',
                  'phone-2-id',
                  null,
                  secondPhoneChange,
                ),
              );

              expect(fakeSupabase.getMethodCallsFor('update'), isEmpty);
              expect(transaction.isCompleted, isTrue);
            },
          );

          test(
            'a duplicate on a patch that names no user is skipped',
            () async {
              fakeSupabase.shouldThrowOnUpdate = true;

              final transaction = await uploadSecondPhone(
                CrudEntry(
                  1,
                  UpdateType.patch,
                  'user_calculator_stores',
                  'phone-2-id',
                  null,
                  {'values': '{"seed": "fence", "rails_per_section": 2}'},
                ),
              );

              expect(fakeSupabase.getMethodCallsFor('update'), hasLength(1));
              expect(transaction.isCompleted, isTrue);
            },
          );

          test('a duplicate on a delete is still retried', () async {
            fakeSupabase.shouldThrowOnDelete = true;

            await expectLater(
              uploadSecondPhone(
                CrudEntry(
                  1,
                  UpdateType.delete,
                  'user_calculator_stores',
                  'phone-2-id',
                  null,
                  null,
                ),
              ),
              throwsA(isA<supabase.PostgrestException>()),
            );
          });

          test(
            'another refusal of a trade store row is still retried',
            () async {
              fakeSupabase.shouldThrowOnUpsert = true;
              fakeSupabase.upsertExceptionType =
                  SupabaseExceptionType.postgrest;
              fakeSupabase.postgrestErrorCode =
                  PostgresErrorCode.checkViolation;
              final transaction = FakeCrudTransaction([
                CrudEntry(
                  1,
                  UpdateType.put,
                  'user_calculator_stores',
                  'phone-2-id',
                  null,
                  secondPhoneChange,
                ),
              ]);
              fakeDatabase.setNextTransaction(transaction);

              await expectLater(
                connector.uploadData(fakeDatabase),
                throwsA(isA<supabase.PostgrestException>()),
              );
              expect(transaction.isCompleted, isFalse);
            },
          );
        });

        test(
          'a refused your_rates change does not stop the operations after it',
          () async {
            fakeSupabase.shouldThrowOnUpsert = true;
            fakeSupabase.upsertExceptionType = SupabaseExceptionType.postgrest;
            fakeSupabase.postgrestErrorCode = PostgresErrorCode.checkViolation;
            fakeSupabase.addTableData('projects', [
              {'id': 'proj-1', 'name': 'Old'},
            ]);
            final transaction = FakeCrudTransaction([
              CrudEntry(1, UpdateType.put, 'your_rates', 'rate-1', null, {
                'item_name': 'Excavator',
              }),
              CrudEntry(2, UpdateType.patch, 'projects', 'proj-1', null, {
                'name': 'New',
              }),
            ]);
            fakeDatabase.setNextTransaction(transaction);

            await connector.uploadData(fakeDatabase);

            expect(fakeSupabase.getMethodCallsFor('update'), hasLength(1));
            expect(transaction.isCompleted, isTrue);
          },
        );

        group('the same your_rates entry saved on two phones', () {
          Map<String, dynamic> serverRate({
            String? label,
            String method = 'day',
          }) => {
            'id': 'server-1',
            'company_id': 'company-1',
            'category': 'equipment',
            'item_name': 'Mini excavator',
            'rate_amount': 100.0,
            'equipment_method': method,
            'entry_label': label,
          };

          Future<FakeCrudTransaction> uploadSecondPhone({
            String name = '  MINI   excavator ',
            String method = 'day',
            String? label,
          }) async {
            fakeSupabase.shouldThrowOnUpsert = true;
            fakeSupabase.upsertExceptionType = SupabaseExceptionType.postgrest;
            fakeSupabase.postgrestErrorCode = PostgresErrorCode.uniqueViolation;
            final transaction = FakeCrudTransaction([
              CrudEntry(1, UpdateType.put, 'your_rates', 'phone-2-id', null, {
                'company_id': 'company-1',
                'category': 'equipment',
                'item_name': name,
                'rate_amount': 400.0,
                'equipment_method': method,
                'entry_label': label,
              }),
            ]);
            fakeDatabase.setNextTransaction(transaction);
            await connector.uploadData(fakeDatabase);
            return transaction;
          }

          test('the later upload overwrites the earlier one', () async {
            fakeSupabase.addTableData('your_rates', [serverRate()]);

            final transaction = await uploadSecondPhone();

            final update = fakeSupabase.getMethodCallsFor('update').single;
            expect(update['filterValue'], 'server-1');
            expect(update['data'], containsPair('rate_amount', 400.0));
            expect(update['data'], isNot(contains('id')));
            expect(transaction.isCompleted, isTrue);
          });

          test('a different pricing method is not overwritten', () async {
            fakeSupabase.addTableData('your_rates', [
              serverRate(method: 'job'),
            ]);

            final transaction = await uploadSecondPhone();

            expect(fakeSupabase.getMethodCallsFor('update'), isEmpty);
            expect(transaction.isCompleted, isTrue);
          });

          test('a label in different capital letters and spacing is the same '
              'label', () async {
            fakeSupabase.addTableData('your_rates', [
              serverRate(label: 'With operator'),
            ]);

            await uploadSecondPhone(label: '  with   OPERATOR ');

            final update = fakeSupabase.getMethodCallsFor('update').single;
            expect(update['filterValue'], 'server-1');
          });

          test('a label of only spaces is the same as no label', () async {
            fakeSupabase.addTableData('your_rates', [serverRate()]);

            await uploadSecondPhone(label: '   ');

            final update = fakeSupabase.getMethodCallsFor('update').single;
            expect(update['filterValue'], 'server-1');
          });

          test('an accented name matches in other capital letters', () async {
            fakeSupabase.addTableData('your_rates', [
              serverRate()..['item_name'] = 'Élévateur',
            ]);

            await uploadSecondPhone(name: ' éLÉVATEUR ');

            final update = fakeSupabase.getMethodCallsFor('update').single;
            expect(update['filterValue'], 'server-1');
          });

          test('a different label is not overwritten', () async {
            fakeSupabase.addTableData('your_rates', [
              serverRate(label: '20 ton'),
            ]);

            final transaction = await uploadSecondPhone(label: '35 ton');

            expect(fakeSupabase.getMethodCallsFor('update'), isEmpty);
            expect(transaction.isCompleted, isTrue);
          });
        });

        test('a your_rates update for a row the server does not have completes '
            'the transaction', () async {
          fakeSupabase.shouldThrowOnUpdate = true;
          fakeSupabase.updateExceptionType = SupabaseExceptionType.postgrest;
          fakeSupabase.postgrestErrorCode = PostgresErrorCode.noDataFound;
          final transaction = FakeCrudTransaction([
            CrudEntry(1, UpdateType.patch, 'your_rates', 'phone-2-id', null, {
              'rate_amount': 400.0,
            }),
          ]);
          fakeDatabase.setNextTransaction(transaction);

          await connector.uploadData(fakeDatabase);

          expect(transaction.isCompleted, isTrue);
        });

        test('a your_rates insert the server cannot find is still retried, '
            'never skipped', () async {
          fakeSupabase.shouldThrowOnUpsert = true;
          fakeSupabase.upsertExceptionType = SupabaseExceptionType.postgrest;
          fakeSupabase.postgrestErrorCode = PostgresErrorCode.noDataFound;
          final transaction = FakeCrudTransaction([
            CrudEntry(1, UpdateType.put, 'your_rates', 'phone-2-id', null, {
              'company_id': 'company-1',
              'category': 'equipment',
              'item_name': 'Mini excavator',
              'rate_amount': 400.0,
            }),
          ]);
          fakeDatabase.setNextTransaction(transaction);

          await expectLater(
            connector.uploadData(fakeDatabase),
            throwsException,
          );

          expect(transaction.isCompleted, isFalse);
        });

        test('a missing row on another table is still retried', () async {
          fakeSupabase.shouldThrowOnUpdate = true;
          fakeSupabase.updateExceptionType = SupabaseExceptionType.postgrest;
          fakeSupabase.postgrestErrorCode = PostgresErrorCode.noDataFound;
          final transaction = FakeCrudTransaction([
            CrudEntry(1, UpdateType.patch, 'projects', 'proj-1', null, {
              'name': 'Renamed',
            }),
          ]);
          fakeDatabase.setNextTransaction(transaction);

          await expectLater(
            connector.uploadData(fakeDatabase),
            throwsException,
          );

          expect(transaction.isCompleted, isFalse);
        });

        test('a your_rates update refused as a duplicate is skipped, never '
            'turned into an overwrite', () async {
          fakeSupabase.addTableData('your_rates', [
            {
              'id': 'server-1',
              'company_id': 'company-1',
              'category': 'equipment',
              'item_name': 'Mini excavator',
              'equipment_method': 'day',
              'entry_label': null,
            },
          ]);
          fakeSupabase.shouldThrowOnUpdate = true;
          fakeSupabase.updateExceptionType = SupabaseExceptionType.postgrest;
          fakeSupabase.postgrestErrorCode = PostgresErrorCode.uniqueViolation;
          final transaction = FakeCrudTransaction([
            CrudEntry(1, UpdateType.patch, 'your_rates', 'phone-2-id', null, {
              'company_id': 'company-1',
              'category': 'equipment',
              'item_name': 'Mini excavator',
              'equipment_method': 'day',
              'entry_label': null,
              'rate_amount': 400.0,
            }),
          ]);
          fakeDatabase.setNextTransaction(transaction);

          await connector.uploadData(fakeDatabase);

          final updates = fakeSupabase.getMethodCallsFor('update');
          expect(updates, hasLength(1));
          expect(updates.single['filterValue'], 'phone-2-id');
          expect(transaction.isCompleted, isTrue);
        });

        test('a refused your_rates update completes the transaction', () async {
          fakeSupabase.shouldThrowOnUpdate = true;
          fakeSupabase.updateExceptionType = SupabaseExceptionType.postgrest;
          fakeSupabase.postgrestErrorCode = PostgresErrorCode.checkViolation;
          final transaction = FakeCrudTransaction([
            CrudEntry(1, UpdateType.patch, 'your_rates', 'rate-1', null, {
              'rate_amount': -5,
            }),
          ]);
          fakeDatabase.setNextTransaction(transaction);

          await connector.uploadData(fakeDatabase);

          expect(transaction.isCompleted, isTrue);
        });

        test(
          'non-RLS error is rethrown and transaction is not completed',
          () async {
            fakeSupabase.shouldThrowOnUpsert = true;
            final transaction = FakeCrudTransaction([
              CrudEntry(1, UpdateType.put, 'projects', 'proj-1', null, {
                'id': 'proj-1',
              }),
            ]);
            fakeDatabase.setNextTransaction(transaction);

            await expectLater(
              connector.uploadData(fakeDatabase),
              throwsException,
            );

            expect(transaction.isCompleted, isFalse);
          },
        );
      });
    });
  });
}

/// Minimal host module that mirrors how the real [AppModule] composes
/// [PowerSyncModule], so the production module's wiring is exercised directly.
class _AppModule extends Module {
  final AppBootstrap appBootstrap;
  _AppModule(this.appBootstrap);

  @override
  List<Module> get imports => [PowerSyncModule(appBootstrap)];
}
