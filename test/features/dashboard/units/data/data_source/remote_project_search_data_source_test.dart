import 'dart:async';
import 'dart:io';

import 'package:construculator/features/dashboard/data/data_source/remote_project_search_data_source.dart';
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
}) {
  return {
    DatabaseConstants.idColumn: id ?? 'project-1',
    DatabaseConstants.projectNameColumn: projectName ?? 'Test Project',
    DatabaseConstants.descriptionColumn: 'Test description',
    DatabaseConstants.creatorUserIdColumn: creatorUserId ?? 'user-1',
    DatabaseConstants.owningCompanyIdColumn: null,
    DatabaseConstants.exportFolderLinkColumn: null,
    DatabaseConstants.exportStorageProviderColumn: null,
    DatabaseConstants.createdAtColumn: '2024-01-01T00:00:00.000Z',
    DatabaseConstants.updatedAtColumn: '2024-01-01T00:00:00.000Z',
    DatabaseConstants.statusColumn: 'active',
  };
}

void main() {
  group('RemoteProjectSearchDataSource', () {
    late FakeClockImpl clock;
    late FakeSupabaseWrapper supabaseWrapper;
    late RemoteProjectSearchDataSource dataSource;

    setUp(() {
      clock = FakeClockImpl();
      supabaseWrapper = FakeSupabaseWrapper(clock: clock);
      dataSource = RemoteProjectSearchDataSource(
        supabaseWrapper: supabaseWrapper,
      );
    });

    group('fetchProjectsBySearchQuery', () {
      test('returns empty list without calling RPC when query is empty', () async {
        final result = await dataSource.fetchProjectsBySearchQuery('');

        expect(result, isEmpty);
        expect(supabaseWrapper.getMethodCallsFor('rpc'), isEmpty);
      });

      test('returns empty list without calling RPC when query is whitespace', () async {
        final result = await dataSource.fetchProjectsBySearchQuery('   ');

        expect(result, isEmpty);
        expect(supabaseWrapper.getMethodCallsFor('rpc'), isEmpty);
      });

      test('returns parsed list of ProjectDto on success', () async {
        supabaseWrapper.setRpcResponse(
          DatabaseConstants.globalSearchRpcFunction,
          {
            'projects': [
              _fakeProjectData(id: 'p-1', projectName: 'Alpha'),
              _fakeProjectData(id: 'p-2', projectName: 'Beta'),
            ],
            'estimations': [],
            'members': [],
          },
        );

        final result = await dataSource.fetchProjectsBySearchQuery('alpha');

        expect(result, hasLength(2));
        expect(result.first.id, equals('p-1'));
        expect(result.first.projectName, equals('Alpha'));
        expect(result.last.projectName, equals('Beta'));
      });

      test('returns empty list when response has no projects key', () async {
        supabaseWrapper.setRpcResponse(
          DatabaseConstants.globalSearchRpcFunction,
          <String, dynamic>{},
        );

        final result = await dataSource.fetchProjectsBySearchQuery('anything');

        expect(result, isEmpty);
      });

      test('calls global_search RPC with dashboard scope and default pagination', () async {
        supabaseWrapper.setRpcResponse(
          DatabaseConstants.globalSearchRpcFunction,
          {'projects': [], 'estimations': [], 'members': []},
        );

        await dataSource.fetchProjectsBySearchQuery('foundation');

        final calls = supabaseWrapper.getMethodCallsFor('rpc');
        expect(calls, hasLength(1));

        final params = calls.first['params'] as Map<String, dynamic>?;
        expect(params, isNotNull);
        expect(params!['query'], equals('foundation'));
        expect(params['scope'], equals('dashboard'));
        expect(params['offset'], equals(0));
        expect(params['limit'], equals(20));
        expect(params['filter_by_tag'], isNull);
        expect(params['filter_by_date'], isNull);
        expect(params['filter_by_owner'], isNull);
      });

      test('rethrows PostgrestException', () async {
        supabaseWrapper.shouldThrowOnRpc = true;
        supabaseWrapper.rpcExceptionType = SupabaseExceptionType.postgrest;

        await expectLater(
          () => dataSource.fetchProjectsBySearchQuery('test'),
          throwsA(isA<supabase.PostgrestException>()),
        );
      });

      test('rethrows SocketException', () async {
        supabaseWrapper.shouldThrowOnRpc = true;
        supabaseWrapper.rpcExceptionType = SupabaseExceptionType.socket;

        await expectLater(
          () => dataSource.fetchProjectsBySearchQuery('test'),
          throwsA(isA<SocketException>()),
        );
      });

      test('rethrows TimeoutException', () async {
        supabaseWrapper.shouldThrowOnRpc = true;
        supabaseWrapper.rpcExceptionType = SupabaseExceptionType.timeout;

        await expectLater(
          () => dataSource.fetchProjectsBySearchQuery('test'),
          throwsA(isA<TimeoutException>()),
        );
      });
    });
  });
}
