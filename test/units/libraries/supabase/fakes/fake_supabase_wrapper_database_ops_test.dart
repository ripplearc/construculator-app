import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';

void main() {
  group('FakeSupabaseWrapper Database Operations', () {
    late FakeSupabaseWrapper fakeWrapper;

    setUp(() {
      fakeWrapper = FakeSupabaseWrapper();
    });

    tearDown(() {
      fakeWrapper.reset();
    });

    group('selectSingle', () {
      test('returns data when a matching record exists', () async {
        fakeWrapper.addTableData('users', [
          {
            'id': '1',
            'email': 'test@example.com',
            'name': 'Test User',
          }
        ]);

        final result = await fakeWrapper.selectSingle(
          table: 'users',
          filterColumn: 'email',
          filterValue: 'test@example.com',
        );

        expect(result, isNotNull);
        expect(result!['id'], equals('1'));
        expect(result['email'], equals('test@example.com'));
        expect(result['name'], equals('Test User'));
      });

      test('returns null when no matching record exists', () async {
        final result = await fakeWrapper.selectSingle(
          table: 'users',
          filterColumn: 'email',
          filterValue: 'notfound@example.com',
        );
        expect(result, isNull);
      });

      test('throws exception when configured to fail select operations', () async {
        fakeWrapper.shouldThrowOnSelect = true;
        fakeWrapper.selectErrorMessage = 'Database error';

        expect(
          () async => await fakeWrapper.selectSingle(
            table: 'users',
            filterColumn: 'id',
            filterValue: '1',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Database error'),
          )),
        );
      });

      test('returns null when configured to return null on select', () async {
        fakeWrapper.shouldReturnNullOnSelect = true;

        final result = await fakeWrapper.selectSingle(
          table: 'users',
          filterColumn: 'id',
          filterValue: '1',
        );
        expect(result, isNull);
      });
    });

    group('insert', () {
      test('adds data to table and returns it with generated fields', () async {
        final insertData = {
          'email': 'new@example.com',
          'name': 'New User',
        };

        final result = await fakeWrapper.insert(
          table: 'users',
          data: insertData,
        );

        expect(result['id'], isNotNull);
        expect(result['email'], equals('new@example.com'));
        expect(result['name'], equals('New User'));
        expect(result['created_at'], isNotNull);
        expect(result['updated_at'], isNotNull);
      });

      test('throws exception when configured to fail insert operations', () async {
        fakeWrapper.shouldThrowOnInsert = true;
        fakeWrapper.insertErrorMessage = 'Insert failed';

        expect(
          () async => await fakeWrapper.insert(
            table: 'users',
            data: {'email': 'test@example.com'},
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Insert failed'),
          )),
        );
      });

      test('generates sequential IDs for multiple inserts', () async {
        final result1 = await fakeWrapper.insert(
          table: 'users',
          data: {'email': 'user1@example.com'},
        );
        final result2 = await fakeWrapper.insert(
          table: 'users',
          data: {'email': 'user2@example.com'},
        );

        expect(result1['id'], equals('1'));
        expect(result2['id'], equals('2'));
      });
    });

    group('update', () {
      test('modifies existing record and returns updated data', () async {
        final initialTime = '2023-01-01T00:00:00Z';
        fakeWrapper.addTableData('users', [
          {
            'id': '1',
            'email': 'test@example.com',
            'name': 'Old Name',
            'created_at': initialTime,
            'updated_at': initialTime,
          }
        ]);

        final result = await fakeWrapper.update(
          table: 'users',
          data: {'name': 'New Name'},
          filterColumn: 'id',
          filterValue: '1',
        );

        expect(result['id'], equals('1'));
        expect(result['email'], equals('test@example.com'));
        expect(result['name'], equals('New Name'));
        expect(result['updated_at'], isNot(equals(initialTime)), reason: "updated_at should change after update");
      });

      test('throws exception when trying to update a non-existent record', () async {
        expect(
          () async => await fakeWrapper.update(
            table: 'users',
            data: {'name': 'New Name'},
            filterColumn: 'id',
            filterValue: 'nonexistent',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Record not found'),
          )),
        );
      });

      test('throws exception when configured to fail update operations', () async {
        fakeWrapper.shouldThrowOnUpdate = true;
        fakeWrapper.updateErrorMessage = 'Update failed';

        // Ensure a record exists to attempt to update
        fakeWrapper.addTableData('users', [
          {
            'id': '1',
            'email': 'test@example.com',
            'name': 'Old Name'
          }
        ]);

        expect(
          () async => await fakeWrapper.update(
            table: 'users',
            data: {'name': 'New Name'},
            filterColumn: 'id',
            filterValue: '1',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Update failed'),
          )),
        );
      });
    });
  });
} 