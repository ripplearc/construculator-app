import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';

void main() {
  group('FakeSupabaseWrapper Test Utilities', () {
    late FakeSupabaseWrapper fakeWrapper;

    setUp(() {
      fakeWrapper = FakeSupabaseWrapper();
    });

    tearDown(() {
      fakeWrapper.reset();
    });

    test('addTableData adds records and clearTableData removes them for a specific table', () async {
      fakeWrapper.addTableData('users', [
        {'id': '1', 'name': 'User 1'},
        {'id': '2', 'name': 'User 2'},
      ]);

      // Note: We can't directly access table data, so we test through selectSingle.
      var user1 = await fakeWrapper.selectSingle(
        table: 'users',
        filterColumn: 'id',
        filterValue: '1',
      );
      expect(user1, isNotNull, reason: "User 1 should be found after addTableData");
      expect(user1!['name'], equals('User 1'));

      fakeWrapper.clearTableData('users');

      user1 = await fakeWrapper.selectSingle(
        table: 'users',
        filterColumn: 'id',
        filterValue: '1',
      );
      expect(user1, isNull, reason: "User 1 should be null after clearTableData");
    });

    test('clearAllData removes data from all tables and resets auth state', () async {
      fakeWrapper.addTableData('users', [{'id': '1', 'name': 'User 1'}]);
      fakeWrapper.addTableData('posts', [{'id': 'p1', 'title': 'Post 1'}]);
      await fakeWrapper.signInWithPassword(email: 'test@example.com', password: 'password');

      fakeWrapper.clearAllData();

      expect(fakeWrapper.currentUser, isNull, reason: "Current user should be null after clearAllData");
      expect(fakeWrapper.isAuthenticated, isFalse, reason: "Should not be authenticated after clearAllData");
      
      final userResult = await fakeWrapper.selectSingle(
        table: 'users',
        filterColumn: 'id',
        filterValue: '1',
      );
      expect(userResult, isNull, reason: "User data should be cleared");

      final postResult = await fakeWrapper.selectSingle(
        table: 'posts',
        filterColumn: 'id',
        filterValue: 'p1',
      );
      expect(postResult, isNull, reason: "Post data should be cleared");
    });

    test('reset reverts all mock configurations, clears data, and auth state', () async {
      // Setup some specific mock states
      await fakeWrapper.signInWithPassword(email: 'user@example.com', password: 'password');
      fakeWrapper.addTableData('users', [{'id': '1', 'name': 'User 1'}]);
      fakeWrapper.shouldThrowOnSignIn = true;
      fakeWrapper.signInErrorMessage = 'Error on sign in';
      fakeWrapper.shouldThrowOnSelect = true;
      fakeWrapper.selectErrorMessage = 'Error on select';

      fakeWrapper.reset();

      // Verify reset state
      expect(fakeWrapper.currentUser, isNull, reason: "Current user should be null after reset");
      expect(fakeWrapper.isAuthenticated, isFalse, reason: "Should not be authenticated after reset");
      expect(fakeWrapper.shouldThrowOnSignIn, isFalse, reason: "shouldThrowOnSignIn flag should be reset");
      expect(fakeWrapper.signInErrorMessage, isNull, reason: "signInErrorMessage should be reset");
      expect(fakeWrapper.shouldThrowOnSelect, isFalse, reason: "shouldThrowOnSelect flag should be reset");
      expect(fakeWrapper.selectErrorMessage, isNull, reason: "selectErrorMessage should be reset");
      
      final userResult = await fakeWrapper.selectSingle(
        table: 'users',
        filterColumn: 'id',
        filterValue: '1',
      );
      expect(userResult, isNull, reason: "User data should be cleared by reset");
    });
  });

  group('FakeSupabaseWrapper: Verifying Method Call Recording', () {
    late FakeSupabaseWrapper fakeWrapper;

    setUp(() {
      fakeWrapper = FakeSupabaseWrapper();
    });

    tearDown(() {
      fakeWrapper.reset(); // Resets method calls among other things
    });

    test('getMethodCalls returns empty list initially and all calls after operations', () async {
      expect(fakeWrapper.getMethodCalls(), isEmpty, reason: "Initially, method calls should be empty.");

      await fakeWrapper.signInWithPassword(email: 'test@example.com', password: 'password');
      await fakeWrapper.selectSingle(table: 'users', filterColumn: 'id', filterValue: 'any');
      fakeWrapper.signOut();

      final calls = fakeWrapper.getMethodCalls();
      expect(calls, hasLength(3));
      expect(calls[0]['method'], equals('signInWithPassword'));
      expect(calls[1]['method'], equals('selectSingle'));
      expect(calls[2]['method'], equals('signOut'));
    });

    test('getLastMethodCall returns null initially and the last call after operations', () async {
      expect(fakeWrapper.getLastMethodCall(), isNull);

      await fakeWrapper.signInWithPassword(email: 'test@example.com', password: 'password');
      var lastCall = fakeWrapper.getLastMethodCall();
      expect(lastCall, isNotNull);
      expect(lastCall!['method'], equals('signInWithPassword'));
      expect(lastCall['email'], equals('test@example.com'));

      await fakeWrapper.selectSingle(table: 'items', filterColumn: 'id', filterValue: '1');
      lastCall = fakeWrapper.getLastMethodCall();
      expect(lastCall, isNotNull);
      expect(lastCall!['method'], equals('selectSingle'));
      expect(lastCall['table'], equals('items'));

      fakeWrapper.signOut();
      lastCall = fakeWrapper.getLastMethodCall();
      expect(lastCall, isNotNull);
      expect(lastCall!['method'], equals('signOut'));
      expect(lastCall['params'], isNull);
    });

    test('getMethodCallsFor returns empty list for uncalled methods and specific calls otherwise', () async {
      expect(fakeWrapper.getMethodCallsFor('signInWithPassword'), isEmpty, reason: "Initially, calls for 'signInWithPassword' should be empty.");
      fakeWrapper.addTableData('users', [{'id': '1', 'name': 'User 1'}]);
      await fakeWrapper.signInWithPassword(email: 'user1@example.com', password: 'password');
      await fakeWrapper.selectSingle(table: 'users', filterColumn: 'id', filterValue: 'any');
      await fakeWrapper.signInWithPassword(email: 'user2@example.com', password: 'password');
      await fakeWrapper.update(table: 'users', data: {'name': 'New Name'}, filterColumn: 'id', filterValue: '1');
      await fakeWrapper.signInWithPassword(email: 'user3@example.com', password: 'password');


      final signInCalls = fakeWrapper.getMethodCallsFor('signInWithPassword');
      expect(signInCalls, hasLength(3), reason: "Should have 3 'signInWithPassword' calls.");
      expect(signInCalls[0]['email'], equals('user1@example.com'));
      expect(signInCalls[1]['email'], equals('user2@example.com'));
      expect(signInCalls[2]['email'], equals('user3@example.com'));

      final selectCalls = fakeWrapper.getMethodCallsFor('selectSingle');
      expect(selectCalls, hasLength(1), reason: "Should have 1 'selectSingle' call.");
      expect(selectCalls[0]['table'], equals('users'));
      
      final updateCalls = fakeWrapper.getMethodCallsFor('update');
      expect(updateCalls, hasLength(1), reason: "Should have 1 'update' call.");
      expect(updateCalls[0]['filterValue'], equals('1'));


      expect(fakeWrapper.getMethodCallsFor('nonExistentMethod'), isEmpty, reason: "Calls for a non-existent method should be empty.");
    });

    test('initialize throws exception when called', () async {
      expect(
        () async => await fakeWrapper.initialize(),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
} 