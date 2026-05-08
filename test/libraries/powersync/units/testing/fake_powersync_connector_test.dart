import 'package:construculator/libraries/powersync/testing/fake_powersync_connector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  group('FakePowerSyncConnector', () {
    late FakePowerSyncConnector connector;
    late _MockPowerSyncDatabase mockDatabase;

    setUp(() {
      connector = FakePowerSyncConnector();
      mockDatabase = _MockPowerSyncDatabase();
    });

    group('fetchCredentials', () {
      test('returns null when no credentials are set', () async {
        final credentials = await connector.fetchCredentials();

        expect(credentials, isNull);
      });

      test('returns configured credentials', () async {
        final expectedCredentials = PowerSyncCredentials(
          endpoint: 'https://powersync.example.com',
          token: 'test-token-123',
        );

        connector.setCredentials(expectedCredentials);

        final credentials = await connector.fetchCredentials();

        expect(credentials, equals(expectedCredentials));
        expect(credentials?.endpoint, equals('https://powersync.example.com'));
        expect(credentials?.token, equals('test-token-123'));
      });

      test('returns updated credentials after reconfiguration', () async {
        connector.setCredentials(
          PowerSyncCredentials(
            endpoint: 'https://old.example.com',
            token: 'old-token',
          ),
        );

        final newCredentials = PowerSyncCredentials(
          endpoint: 'https://new.example.com',
          token: 'new-token',
        );
        connector.setCredentials(newCredentials);

        final credentials = await connector.fetchCredentials();

        expect(credentials, equals(newCredentials));
      });
    });

    group('uploadData', () {
      test('completes successfully when no transaction is pending', () async {
        mockDatabase.setNextTransaction(null);

        await connector.uploadData(mockDatabase);

        expect(connector.uploadedTransactions, isEmpty);
        expect(connector.uploadedOperations, isEmpty);
      });

      test('records uploaded transaction and completes it', () async {
        final transaction = _MockCrudTransaction([
          _createMockCrudEntry('1', 'projects'),
          _createMockCrudEntry('2', 'users'),
        ]);

        mockDatabase.setNextTransaction(transaction);

        await connector.uploadData(mockDatabase);

        expect(connector.uploadedTransactions, hasLength(1));
        expect(connector.uploadedTransactions.first, equals(transaction));
        expect(connector.uploadedOperations, hasLength(2));
        expect(transaction.isCompleted, isTrue);
      });

      test('records multiple transactions across uploads', () async {
        final transaction1 = _MockCrudTransaction([
          _createMockCrudEntry('1', 'projects'),
        ]);
        final transaction2 = _MockCrudTransaction([
          _createMockCrudEntry('2', 'users'),
        ]);

        mockDatabase.setNextTransaction(transaction1);
        await connector.uploadData(mockDatabase);

        mockDatabase.setNextTransaction(transaction2);
        await connector.uploadData(mockDatabase);

        expect(connector.uploadedTransactions, hasLength(2));
        expect(connector.uploadedOperations, hasLength(2));
        expect(transaction1.isCompleted, isTrue);
        expect(transaction2.isCompleted, isTrue);
      });

      test('throws configured error and does not complete transaction',
          () async {
        final transaction = _MockCrudTransaction([
          _createMockCrudEntry('1', 'projects'),
        ]);
        final testError = supabase.PostgrestException(
          message: 'Unique violation',
          code: '23505',
        );

        mockDatabase.setNextTransaction(transaction);
        connector.setUploadError(testError);

        expect(
          () => connector.uploadData(mockDatabase),
          throwsA(isA<supabase.PostgrestException>()),
        );

        expect(connector.uploadedTransactions, hasLength(1));
        expect(transaction.isCompleted, isFalse);
      });

      test('completes transaction when completeTransactionOnError is true',
          () async {
        final transaction = _MockCrudTransaction([
          _createMockCrudEntry('1', 'projects'),
        ]);
        final rlsError = supabase.PostgrestException(
          message: 'permission denied',
          code: '42501',
        );

        mockDatabase.setNextTransaction(transaction);
        connector.setUploadError(rlsError, completeTransactionOnError: true);

        expect(
          () => connector.uploadData(mockDatabase),
          throwsA(isA<supabase.PostgrestException>()),
        );

        expect(connector.uploadedTransactions, hasLength(1));
        expect(transaction.isCompleted, isTrue);
      });

      test('resumes normal operation after clearUploadError', () async {
        final transaction = _MockCrudTransaction([
          _createMockCrudEntry('1', 'projects'),
        ]);

        connector.setUploadError(Exception('Test error'));
        connector.clearUploadError();

        mockDatabase.setNextTransaction(transaction);
        await connector.uploadData(mockDatabase);

        expect(transaction.isCompleted, isTrue);
      });
    });

    group('upload tracking', () {
      test('clearUploadHistory removes recorded transactions', () async {
        final transaction = _MockCrudTransaction([
          _createMockCrudEntry('1', 'projects'),
        ]);

        mockDatabase.setNextTransaction(transaction);
        await connector.uploadData(mockDatabase);

        expect(connector.uploadedTransactions, isNotEmpty);
        expect(connector.uploadedOperations, isNotEmpty);

        connector.clearUploadHistory();

        expect(connector.uploadedTransactions, isEmpty);
        expect(connector.uploadedOperations, isEmpty);
      });
    });
  });
}

CrudEntry _createMockCrudEntry(String id, String table) {
  return CrudEntry(
    1,
    UpdateType.put,
    table,
    id,
    null,
    {'id': id},
  );
}

class _MockPowerSyncDatabase implements PowerSyncDatabase {
  CrudTransaction? _nextTransaction;

  void setNextTransaction(CrudTransaction? transaction) {
    _nextTransaction = transaction;
  }

  @override
  Future<CrudTransaction?> getNextCrudTransaction() async {
    return _nextTransaction;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockCrudTransaction implements CrudTransaction {
  final List<CrudEntry> _operations;
  bool _isCompleted = false;

  _MockCrudTransaction(this._operations);

  bool get isCompleted => _isCompleted;

  @override
  List<CrudEntry> get crud => _operations;

  @override
  int? get transactionId => null;

  @override
  Future<void> Function({String? writeCheckpoint}) get complete =>
      ({String? writeCheckpoint}) async {
        _isCompleted = true;
      };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
