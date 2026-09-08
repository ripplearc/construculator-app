import 'package:construculator/libraries/owner/data/data_source/remote_owner_data_source.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

Map<String, dynamic> _ownerRow({
  required String id,
  required String firstName,
  required String lastName,
  String professionalRole = 'Engineer',
}) {
  return {
    DatabaseConstants.idColumn: id,
    DatabaseConstants.credentialIdColumn: null,
    DatabaseConstants.firstNameColumn: firstName,
    DatabaseConstants.lastNameColumn: lastName,
    DatabaseConstants.professionalRoleColumn: professionalRole,
    DatabaseConstants.profilePhotoUrlColumn: null,
  };
}

void main() {
  group('RemoteOwnerDataSource', () {
    late FakeSupabaseWrapper supabaseWrapper;
    late RemoteOwnerDataSource dataSource;

    setUp(() {
      supabaseWrapper = FakeSupabaseWrapper(clock: FakeClockImpl());
      dataSource = RemoteOwnerDataSource(supabaseWrapper: supabaseWrapper);
    });

    tearDown(() {
      supabaseWrapper.reset();
    });

    test('fetchOwners returns owners mapped to UserProfileDtos', () async {
      supabaseWrapper.setRpcResponse(
        DatabaseConstants.projectOwnersRpcFunction,
        [
          _ownerRow(id: 'owner-1', firstName: 'John', lastName: 'Doe'),
          _ownerRow(id: 'owner-2', firstName: 'Floyd', lastName: 'Miles'),
        ],
      );

      final result = await dataSource.fetchOwners();

      expect(result, hasLength(2));
      expect(result.first.id, 'owner-1');
      expect(result.first.firstName, 'John');
      expect(result.first.lastName, 'Doe');
      expect(result.last.id, 'owner-2');
    });

    test('fetchOwners calls the project owners RPC', () async {
      supabaseWrapper.setRpcResponse(
        DatabaseConstants.projectOwnersRpcFunction,
        [_ownerRow(id: 'owner-1', firstName: 'John', lastName: 'Doe')],
      );

      await dataSource.fetchOwners();

      final calls = supabaseWrapper.getMethodCallsFor('rpc');
      expect(calls, hasLength(1));
      expect(
        calls.first['functionName'],
        DatabaseConstants.projectOwnersRpcFunction,
      );
    });

    test('fetchOwners returns an empty list when the RPC returns no rows', () async {
      supabaseWrapper.setRpcResponse(
        DatabaseConstants.projectOwnersRpcFunction,
        <dynamic>[],
      );

      final result = await dataSource.fetchOwners();

      expect(result, isEmpty);
    });

    test('fetchOwners rethrows when supabaseWrapper.rpc throws', () async {
      supabaseWrapper.shouldThrowOnRpc = true;
      supabaseWrapper.rpcExceptionType = SupabaseExceptionType.postgrest;

      await expectLater(
        () => dataSource.fetchOwners(),
        throwsA(isA<supabase.PostgrestException>()),
      );
    });

    test('fetchOwners skips rows that are not Map<String, dynamic>', () async {
      supabaseWrapper.setRpcResponse(
        DatabaseConstants.projectOwnersRpcFunction,
        <dynamic>[
          'not-a-map',
          _ownerRow(id: 'owner-1', firstName: 'John', lastName: 'Doe'),
          42,
        ],
      );

      final result = await dataSource.fetchOwners();

      expect(result, hasLength(1));
      expect(result.single.id, 'owner-1');
    });

    test('fetchOwners throws when a row is missing a required field', () async {
      supabaseWrapper.setRpcResponse(
        DatabaseConstants.projectOwnersRpcFunction,
        [
          <String, dynamic>{
            DatabaseConstants.idColumn: 'owner-1',
            DatabaseConstants.credentialIdColumn: null,
            // firstName intentionally omitted to trigger a parsing failure.
            DatabaseConstants.lastNameColumn: 'Doe',
            DatabaseConstants.professionalRoleColumn: 'Engineer',
            DatabaseConstants.profilePhotoUrlColumn: null,
          },
        ],
      );

      await expectLater(
        () => dataSource.fetchOwners(),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
