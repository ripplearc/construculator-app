import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/tag/data/data_source/remote_tag_data_source.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

Map<String, dynamic> _tagRow({required String id, required String name}) {
  return {
    DatabaseConstants.idColumn: id,
    DatabaseConstants.nameColumn: name,
  };
}

void main() {
  group('RemoteTagDataSource', () {
    late FakeSupabaseWrapper supabaseWrapper;
    late RemoteTagDataSource dataSource;

    setUp(() {
      supabaseWrapper = FakeSupabaseWrapper(clock: FakeClockImpl());
      dataSource = RemoteTagDataSource(supabaseWrapper: supabaseWrapper);
    });

    test('getTags returns all tags mapped to DTOs', () async {
      supabaseWrapper.addTableData(DatabaseConstants.tagsTable, [
        _tagRow(id: 'tag-1', name: 'Roofing'),
        _tagRow(id: 'tag-2', name: 'Plumbing'),
      ]);

      final result = await dataSource.getTags();

      expect(result.length, 2);
      expect(result.first.id, 'tag-2');
      expect(result.first.name, 'Plumbing');
    });

    test('getTags requests rows ordered alphabetically by name', () async {
      supabaseWrapper.addTableData(DatabaseConstants.tagsTable, [
        _tagRow(id: 'tag-1', name: 'Wall'),
        _tagRow(id: 'tag-2', name: 'Carpeting'),
        _tagRow(id: 'tag-3', name: 'Painting'),
      ]);

      final result = await dataSource.getTags();

      final calls = supabaseWrapper.getMethodCallsFor('selectMatch');
      expect(calls.length, 1);
      expect(calls.first['table'], DatabaseConstants.tagsTable);
      expect(calls.first['orderBy'], DatabaseConstants.nameColumn);
      expect(result.map((tag) => tag.name).toList(), [
        'Carpeting',
        'Painting',
        'Wall',
      ]);
    });

    test('getTags returns an empty list when the table is empty', () async {
      final result = await dataSource.getTags();

      expect(result, isEmpty);
    });

    test('getTags rethrows when supabaseWrapper.selectMatch throws', () async {
      supabaseWrapper.shouldThrowOnSelectMatch = true;
      supabaseWrapper.selectMatchExceptionType = SupabaseExceptionType.postgrest;

      await expectLater(
        () => dataSource.getTags(),
        throwsA(isA<supabase.PostgrestException>()),
      );
    });
  });
}
