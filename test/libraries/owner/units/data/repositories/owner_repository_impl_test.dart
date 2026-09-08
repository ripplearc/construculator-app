import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/global_search/domain/search_error_type.dart';
import 'package:construculator/libraries/owner/domain/repositories/owner_repository.dart';
import 'package:construculator/libraries/owner/owner_library_module.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../utils/fake_app_bootstrap_factory.dart';

class _OwnerRepositoryTestModule extends Module {
  final AppBootstrap appBootstrap;

  _OwnerRepositoryTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [OwnerLibraryModule(appBootstrap)];
}

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

void expectRight<L, R>(Either<L, R> result, void Function(R value) assertions) {
  result.fold((_) => fail('Expected Right but got Left'), assertions);
}

void expectLeft<L, R>(Either<L, R> result, void Function(L error) assertions) {
  result.fold(assertions, (_) => fail('Expected Left but got Right'));
}

void main() {
  group('OwnerRepositoryImpl', () {
    late OwnerRepository repository;
    late FakeSupabaseWrapper fakeSupabaseWrapper;

    setUpAll(() {
      Modular.init(
        _OwnerRepositoryTestModule(
          FakeAppBootstrapFactory.create(
            supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
          ),
        ),
      );
      fakeSupabaseWrapper =
          Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
      repository = Modular.get<OwnerRepository>();
    });

    tearDownAll(() {
      Modular.destroy();
    });

    setUp(() {
      fakeSupabaseWrapper.reset();
    });

    test('getOwners returns domain owners on success', () async {
      fakeSupabaseWrapper.setRpcResponse(
        DatabaseConstants.projectOwnersRpcFunction,
        [
          _ownerRow(id: 'owner-1', firstName: 'John', lastName: 'Doe'),
          _ownerRow(id: 'owner-2', firstName: 'Floyd', lastName: 'Miles'),
        ],
      );

      final result = await repository.getOwners();

      expectRight(result, (owners) {
        expect(owners.length, 2);
        expect(owners.first.id, 'owner-1');
        expect(owners.first.fullName, 'John Doe');
      });
    });

    test('getOwners returns an empty list when no owners exist', () async {
      fakeSupabaseWrapper.setRpcResponse(
        DatabaseConstants.projectOwnersRpcFunction,
        <dynamic>[],
      );

      final result = await repository.getOwners();

      expectRight(result, (owners) => expect(owners, isEmpty));
    });

    test('getOwners maps timeout exceptions to SearchFailure', () async {
      fakeSupabaseWrapper.shouldThrowOnRpc = true;
      fakeSupabaseWrapper.rpcExceptionType = SupabaseExceptionType.timeout;

      final result = await repository.getOwners();

      expectLeft(result, (failure) {
        expect(failure, isA<SearchFailure>());
        expect(
          (failure as SearchFailure).errorType,
          SearchErrorType.timeoutError,
        );
      });
    });

    test('getOwners maps socket exceptions to connection SearchFailure',
        () async {
      fakeSupabaseWrapper.shouldThrowOnRpc = true;
      fakeSupabaseWrapper.rpcExceptionType = SupabaseExceptionType.socket;

      final result = await repository.getOwners();

      expectLeft(result, (failure) {
        expect(failure, isA<SearchFailure>());
        expect(
          (failure as SearchFailure).errorType,
          SearchErrorType.connectionError,
        );
      });
    });

    test(
        'getOwners maps unexpected postgrest exceptions to database SearchFailure',
        () async {
      fakeSupabaseWrapper.shouldThrowOnRpc = true;
      fakeSupabaseWrapper.rpcExceptionType = SupabaseExceptionType.postgrest;

      final result = await repository.getOwners();

      expectLeft(result, (failure) {
        expect(failure, isA<SearchFailure>());
        expect(
          (failure as SearchFailure).errorType,
          SearchErrorType.unexpectedDatabaseError,
        );
      });
    });

    test(
        'getOwners maps postgrest connection-failure codes to connection SearchFailure',
        () async {
      fakeSupabaseWrapper.shouldThrowOnRpc = true;
      fakeSupabaseWrapper.rpcExceptionType = SupabaseExceptionType.postgrest;
      fakeSupabaseWrapper.postgrestErrorCode =
          PostgresErrorCode.connectionFailure;

      final result = await repository.getOwners();

      expectLeft(result, (failure) {
        expect(failure, isA<SearchFailure>());
        expect(
          (failure as SearchFailure).errorType,
          SearchErrorType.connectionError,
        );
      });
    });

    test('getOwners maps unrecognized errors to UnexpectedFailure', () async {
      fakeSupabaseWrapper.shouldThrowOnRpc = true;
      fakeSupabaseWrapper.rpcExceptionType = SupabaseExceptionType.unknown;

      final result = await repository.getOwners();

      expectLeft(result, (failure) => expect(failure, isA<UnexpectedFailure>()));
    });

    test('getOwners maps malformed rows to parsing SearchFailure', () async {
      fakeSupabaseWrapper.setRpcResponse(
        DatabaseConstants.projectOwnersRpcFunction,
        [
          {
            DatabaseConstants.idColumn: 'owner-1',
            DatabaseConstants.credentialIdColumn: null,
            DatabaseConstants.firstNameColumn: 42,
            DatabaseConstants.lastNameColumn: 'Doe',
            DatabaseConstants.professionalRoleColumn: 'Engineer',
            DatabaseConstants.profilePhotoUrlColumn: null,
          },
        ],
      );

      final result = await repository.getOwners();

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
