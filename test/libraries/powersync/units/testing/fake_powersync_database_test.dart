import 'package:construculator/libraries/powersync/testing/fake_powersync_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:powersync/powersync.dart';

void main() {
  group('FakePowerSyncDatabase', () {
    late FakePowerSyncDatabase fakeDatabase;

    setUp(() {
      fakeDatabase = FakePowerSyncDatabase();
    });

    group('connect', () {
      test('records call count and the connector passed', () async {
        final connector = _FakeConnector();

        await fakeDatabase.connect(connector: connector);

        expect(fakeDatabase.connectCallCount, 1);
        expect(fakeDatabase.lastConnector, same(connector));
      });

      test('throws the configured connectError', () async {
        final error = Exception('connect failed');
        fakeDatabase.connectError = error;

        expect(
          () => fakeDatabase.connect(connector: _FakeConnector()),
          throwsA(same(error)),
        );
      });

      test('still records the call even when it throws', () async {
        fakeDatabase.connectError = Exception('connect failed');

        await expectLater(
          fakeDatabase.connect(connector: _FakeConnector()),
          throwsException,
        );

        expect(fakeDatabase.connectCallCount, 1);
      });
    });

    group('disconnect', () {
      test('records call count', () async {
        await fakeDatabase.disconnect();
        await fakeDatabase.disconnect();

        expect(fakeDatabase.disconnectCallCount, 2);
      });
    });

    group('disconnectAndClear', () {
      test('records call count', () async {
        await fakeDatabase.disconnectAndClear();

        expect(fakeDatabase.disconnectAndClearCallCount, 1);
      });
    });

    group('getNextCrudTransaction', () {
      test('returns null when no transaction is queued', () async {
        final transaction = await fakeDatabase.getNextCrudTransaction();

        expect(transaction, isNull);
      });

      test('returns the queued transaction', () async {
        final expected = FakeCrudTransaction([]);
        fakeDatabase.setNextTransaction(expected);

        final transaction = await fakeDatabase.getNextCrudTransaction();

        expect(transaction, equals(expected));
      });

      test('clears the transaction after it is consumed', () async {
        fakeDatabase.setNextTransaction(FakeCrudTransaction([]));

        await fakeDatabase.getNextCrudTransaction();
        final second = await fakeDatabase.getNextCrudTransaction();

        expect(second, isNull);
      });

      test('returns updated transaction after reconfiguration', () async {
        final first = FakeCrudTransaction([]);
        final second = FakeCrudTransaction([]);

        fakeDatabase.setNextTransaction(first);
        fakeDatabase.setNextTransaction(second);

        final transaction = await fakeDatabase.getNextCrudTransaction();

        expect(transaction, equals(second));
      });
    });
  });

  group('FakeCrudTransaction', () {
    CrudEntry makeCrudEntry(String id, String table) => CrudEntry(
          1,
          UpdateType.put,
          table,
          id,
          null,
          {'id': id},
        );

    test('exposes the provided operations via crud', () {
      final ops = [makeCrudEntry('1', 'projects'), makeCrudEntry('2', 'users')];
      final transaction = FakeCrudTransaction(ops);

      expect(transaction.crud, equals(ops));
    });

    test('isCompleted is false before complete is called', () {
      final transaction = FakeCrudTransaction([]);

      expect(transaction.isCompleted, isFalse);
    });

    test('isCompleted is true after complete is called', () async {
      final transaction = FakeCrudTransaction([]);

      await transaction.complete();

      expect(transaction.isCompleted, isTrue);
    });

    test('transactionId is null', () {
      expect(FakeCrudTransaction([]).transactionId, isNull);
    });
  });
}

/// Minimal connector used only to assert it is passed through to [connect].
class _FakeConnector extends PowerSyncBackendConnector {
  @override
  Future<PowerSyncCredentials?> fetchCredentials() async => null;

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {}
}
