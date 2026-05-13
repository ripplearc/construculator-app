import 'dart:async';
import 'dart:io';

import 'package:construculator/libraries/project/data/data_source/remote_project_search_data_source.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

Map<String, dynamic> _fakeProjectData({
  String? id,
  String? projectName,
  String? creatorUserId,
  String? createdAt,
  String? updatedAt,
  String? status,
}) {
  return {
    DatabaseConstants.idColumn: id ?? 'project-1',
    DatabaseConstants.projectNameColumn: projectName ?? 'Test Project',
    DatabaseConstants.descriptionColumn: 'Test description',
    DatabaseConstants.creatorUserIdColumn: creatorUserId ?? 'user-1',
    DatabaseConstants.owningCompanyIdColumn: null,
    DatabaseConstants.exportFolderLinkColumn: null,
    DatabaseConstants.exportStorageProviderColumn: null,
    DatabaseConstants.createdAtColumn: createdAt ?? '2024-01-01T00:00:00.000Z',
    DatabaseConstants.updatedAtColumn: updatedAt ?? '2024-01-01T00:00:00.000Z',
    DatabaseConstants.statusColumn: status ?? 'active',
  };
}

void main() {
  group('RemoteProjectSearchDataSource', () {
    late FakeClockImpl clock;
    late FakeSupabaseWrapper supabaseWrapper;
    late RemoteProjectSearchDataSource dataSource;

    setUp(() {
      clock = FakeClockImpl(DateTime(2025, 1, 1, 8, 0));
      supabaseWrapper = FakeSupabaseWrapper(clock: clock);
      dataSource = RemoteProjectSearchDataSource(
        supabaseWrapper: supabaseWrapper,
      );
    });

    tearDown(() {
      supabaseWrapper.reset();
    });

    group('fetchProjectsBySearchQuery', () {
      test('returns mapped ProjectDto list when RPC succeeds with data', () async {
        supabaseWrapper.setRpcResponse(
          DatabaseConstants.globalSearchRpcFunction,
          {
            'projects': [
              _fakeProjectData(id: 'p-1', projectName: 'Foundation Work'),
              _fakeProjectData(id: 'p-2', projectName: 'Steel Frame'),
            ],
            'estimations': [],
            'members': [],
          },
        );

        final result = await dataSource.fetchProjectsBySearchQuery(
          userId: 'user-1',
          query: 'foundation',
        );

        expect(result, hasLength(2));
        expect(result.first.id, equals('p-1'));
        expect(result.first.projectName, equals('Foundation Work'));
        expect(result.last.id, equals('p-2'));
        expect(result.last.projectName, equals('Steel Frame'));
      });

      test('returns empty list when RPC returns empty projects array', () async {
        supabaseWrapper.setRpcResponse(
          DatabaseConstants.globalSearchRpcFunction,
          {'projects': [], 'estimations': [], 'members': []},
        );

        final result = await dataSource.fetchProjectsBySearchQuery(
          userId: 'user-1',
          query: 'nothing',
        );

        expect(result, isEmpty);
      });

      test('returns empty list without calling RPC when query is empty', () async {
        final result = await dataSource.fetchProjectsBySearchQuery(
          userId: 'user-1',
          query: '',
        );

        expect(result, isEmpty);
        expect(supabaseWrapper.getMethodCallsFor('rpc'), isEmpty);
      });

      test(
        'returns empty list without calling RPC when query is whitespace only',
        () async {
          final result = await dataSource.fetchProjectsBySearchQuery(
            userId: 'user-1',
            query: '   ',
          );

          expect(result, isEmpty);
          expect(supabaseWrapper.getMethodCallsFor('rpc'), isEmpty);
        },
      );

      test('returns empty list without calling RPC when userId is empty', () async {
        final result = await dataSource.fetchProjectsBySearchQuery(
          userId: '',
          query: 'wall',
        );

        expect(result, isEmpty);
        expect(supabaseWrapper.getMethodCallsFor('rpc'), isEmpty);
      });

      test(
        'returns empty list without calling RPC when userId is whitespace only',
        () async {
          final result = await dataSource.fetchProjectsBySearchQuery(
            userId: '   ',
            query: 'wall',
          );

          expect(result, isEmpty);
          expect(supabaseWrapper.getMethodCallsFor('rpc'), isEmpty);
        },
      );

      test('always passes scope: dashboard in RPC params', () async {
        supabaseWrapper.setRpcResponse(
          DatabaseConstants.globalSearchRpcFunction,
          {'projects': [], 'estimations': [], 'members': []},
        );

        await dataSource.fetchProjectsBySearchQuery(userId: 'user-1', query: 'wall');

        final rpcCalls = supabaseWrapper.getMethodCallsFor('rpc');
        expect(rpcCalls, hasLength(1));
        final params = rpcCalls.first['params'] as Map<String, dynamic>?;
        expect(params, isNotNull);
        expect(params!['scope'], equals(DatabaseConstants.globalSearchDashboardScope));
      });

      test('does not forward userId in RPC params — auth scoping is JWT-based', () async {
        supabaseWrapper.setRpcResponse(
          DatabaseConstants.globalSearchRpcFunction,
          {'projects': [], 'estimations': [], 'members': []},
        );

        await dataSource.fetchProjectsBySearchQuery(userId: 'user-1', query: 'wall');

        final params = supabaseWrapper.getMethodCallsFor('rpc').first['params']
            as Map<String, dynamic>?;
        expect(params, isNotNull);
        expect(params!.containsKey('user_id'), isFalse);
      });

      test('passes limit and offset constants in RPC params', () async {
        supabaseWrapper.setRpcResponse(
          DatabaseConstants.globalSearchRpcFunction,
          {'projects': [], 'estimations': [], 'members': []},
        );

        await dataSource.fetchProjectsBySearchQuery(userId: 'user-1', query: 'wall');

        final params = supabaseWrapper.getMethodCallsFor('rpc').first['params']
            as Map<String, dynamic>?;
        expect(params, isNotNull);
        expect(params!['limit'], equals(DatabaseConstants.globalSearchDefaultLimit));
        expect(params['offset'], equals(DatabaseConstants.globalSearchDefaultOffset));
      });

      test('passes filterByDate as ISO8601 string in RPC params', () async {
        supabaseWrapper.setRpcResponse(
          DatabaseConstants.globalSearchRpcFunction,
          {'projects': [], 'estimations': [], 'members': []},
        );

        final filterDate = DateTime(2024, 6, 1);
        await dataSource.fetchProjectsBySearchQuery(
          userId: 'user-1',
          query: 'wall',
          filterByDate: filterDate,
        );

        final params = supabaseWrapper.getMethodCallsFor('rpc').first['params']
            as Map<String, dynamic>?;
        expect(params!['filter_by_date'], equals(filterDate.toIso8601String()));
      });

      test('passes filterByTag and filterByOwner in RPC params', () async {
        supabaseWrapper.setRpcResponse(
          DatabaseConstants.globalSearchRpcFunction,
          {'projects': [], 'estimations': [], 'members': []},
        );

        await dataSource.fetchProjectsBySearchQuery(
          userId: 'user-1',
          query: 'wall',
          filterByTag: 'structural',
          filterByOwner: 'owner-42',
        );

        final params = supabaseWrapper.getMethodCallsFor('rpc').first['params']
            as Map<String, dynamic>?;
        expect(params!['filter_by_tag'], equals('structural'));
        expect(params['filter_by_owner'], equals('owner-42'));
      });

      test('ignores estimations and members in RPC response', () async {
        supabaseWrapper.setRpcResponse(
          DatabaseConstants.globalSearchRpcFunction,
          {
            'projects': [_fakeProjectData(id: 'p-1')],
            'estimations': [
              {'id': 'e-1', 'estimate_name': 'Some Estimate'},
            ],
            'members': [
              {'id': 'm-1', 'first_name': 'John'},
            ],
          },
        );

        final result = await dataSource.fetchProjectsBySearchQuery(
          userId: 'user-1',
          query: 'wall',
        );

        expect(result, hasLength(1));
        expect(result.first.id, equals('p-1'));
      });

      test('rethrows PostgrestException when RPC throws', () async {
        supabaseWrapper.shouldThrowOnRpc = true;
        supabaseWrapper.rpcExceptionType = SupabaseExceptionType.postgrest;
        supabaseWrapper.rpcErrorMessage = 'DB error';

        await expectLater(
          () => dataSource.fetchProjectsBySearchQuery(userId: 'user-1', query: 'wall'),
          throwsA(isA<supabase.PostgrestException>()),
        );
      });

      test('rethrows SocketException when RPC throws', () async {
        supabaseWrapper.shouldThrowOnRpc = true;
        supabaseWrapper.rpcExceptionType = SupabaseExceptionType.socket;
        supabaseWrapper.rpcErrorMessage = 'Network error';

        await expectLater(
          () => dataSource.fetchProjectsBySearchQuery(userId: 'user-1', query: 'wall'),
          throwsA(isA<SocketException>()),
        );
      });

      test('rethrows TimeoutException when RPC throws', () async {
        supabaseWrapper.shouldThrowOnRpc = true;
        supabaseWrapper.rpcExceptionType = SupabaseExceptionType.timeout;
        supabaseWrapper.rpcErrorMessage = 'Timeout';

        await expectLater(
          () => dataSource.fetchProjectsBySearchQuery(userId: 'user-1', query: 'wall'),
          throwsA(isA<TimeoutException>()),
        );
      });
    });
  });
}
