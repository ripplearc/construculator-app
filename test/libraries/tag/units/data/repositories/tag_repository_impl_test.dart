import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/global_search/domain/search_error_type.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/tag/domain/repositories/tag_repository.dart';
import 'package:construculator/libraries/tag/tag_library_module.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../utils/fake_app_bootstrap_factory.dart';

class _TagRepositoryTestModule extends Module {
  final AppBootstrap appBootstrap;

  _TagRepositoryTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [TagLibraryModule(appBootstrap)];
}

Map<String, dynamic> _tagRow({required String id, required String name}) {
  return {
    DatabaseConstants.idColumn: id,
    DatabaseConstants.nameColumn: name,
  };
}

void expectRight<L, R>(Either<L, R> result, void Function(R value) assertions) {
  result.fold((_) => fail('Expected Right but got Left'), assertions);
}

void expectLeft<L, R>(Either<L, R> result, void Function(L error) assertions) {
  result.fold(assertions, (_) => fail('Expected Left but got Right'));
}

void main() {
  group('TagRepositoryImpl', () {
    late TagRepository repository;
    late FakeSupabaseWrapper fakeSupabaseWrapper;

    setUpAll(() {
      Modular.init(
        _TagRepositoryTestModule(
          FakeAppBootstrapFactory.create(
            supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
          ),
        ),
      );
      fakeSupabaseWrapper =
          Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
      repository = Modular.get<TagRepository>();
    });

    tearDownAll(() {
      Modular.destroy();
    });

    setUp(() {
      fakeSupabaseWrapper.reset();
    });

    test('getTags returns domain tags on success', () async {
      fakeSupabaseWrapper.addTableData(DatabaseConstants.tagsTable, [
        _tagRow(id: 'tag-1', name: 'Electrical'),
        _tagRow(id: 'tag-2', name: 'Roofing'),
      ]);

      final result = await repository.getTags();

      expectRight(result, (tags) {
        expect(tags.length, 2);
        expect(tags.first.id, 'tag-1');
        expect(tags.first.name, 'Electrical');
      });
    });

    test('getTags returns an empty list when no tags exist', () async {
      final result = await repository.getTags();

      expectRight(result, (tags) => expect(tags, isEmpty));
    });

    test('getTags maps timeout exceptions to SearchFailure', () async {
      fakeSupabaseWrapper.shouldThrowOnSelectMatch = true;
      fakeSupabaseWrapper.selectMatchExceptionType =
          SupabaseExceptionType.timeout;

      final result = await repository.getTags();

      expectLeft(result, (failure) {
        expect(failure, isA<SearchFailure>());
        expect(
          (failure as SearchFailure).errorType,
          SearchErrorType.timeoutError,
        );
      });
    });

    test('getTags maps socket exceptions to connection SearchFailure',
        () async {
      fakeSupabaseWrapper.shouldThrowOnSelectMatch = true;
      fakeSupabaseWrapper.selectMatchExceptionType =
          SupabaseExceptionType.socket;

      final result = await repository.getTags();

      expectLeft(result, (failure) {
        expect(failure, isA<SearchFailure>());
        expect(
          (failure as SearchFailure).errorType,
          SearchErrorType.connectionError,
        );
      });
    });

    test('getTags maps postgrest exceptions to database SearchFailure',
        () async {
      fakeSupabaseWrapper.shouldThrowOnSelectMatch = true;
      fakeSupabaseWrapper.selectMatchExceptionType =
          SupabaseExceptionType.postgrest;

      final result = await repository.getTags();

      expectLeft(result, (failure) {
        expect(failure, isA<SearchFailure>());
        expect(
          (failure as SearchFailure).errorType,
          SearchErrorType.unexpectedDatabaseError,
        );
      });
    });

    test('getTags maps postgres connection error codes to connectionError',
        () async {
      fakeSupabaseWrapper.shouldThrowOnSelectMatch = true;
      fakeSupabaseWrapper.selectMatchExceptionType =
          SupabaseExceptionType.postgrest;
      fakeSupabaseWrapper.postgrestErrorCode =
          PostgresErrorCode.connectionFailure;

      final result = await repository.getTags();

      expectLeft(result, (failure) {
        expect(failure, isA<SearchFailure>());
        expect(
          (failure as SearchFailure).errorType,
          SearchErrorType.connectionError,
        );
      });
    });

    test('getTags maps malformed rows to parsing SearchFailure', () async {
      fakeSupabaseWrapper.addTableData(DatabaseConstants.tagsTable, [
        {DatabaseConstants.idColumn: 'tag-1', DatabaseConstants.nameColumn: 42},
      ]);

      final result = await repository.getTags();

      expectLeft(result, (failure) {
        expect(failure, isA<SearchFailure>());
        expect(
          (failure as SearchFailure).errorType,
          SearchErrorType.parsingError,
        );
      });
    });
  });
}
