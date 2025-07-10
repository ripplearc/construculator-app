import 'package:construculator/features/auth/domain/entities/professional_role.dart';
import 'package:construculator/features/auth/domain/repositories/auth_repository.dart';
import 'package:construculator/features/auth/testing/auth_test_module.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late AuthRepository repository;

  setUp(() {
    Modular.init(AuthTestModule());
    fakeSupabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
    repository = Modular.get<AuthRepository>();
  });

  tearDown(() {
    Modular.destroy();
  });

  group('AuthRepositoryImpl.getProfessionalRoles', () {
    test('returns list of ProfessionalRole on success', () async {
      fakeSupabase.addTableData('professional_roles', [
        {'id': '1', 'name': 'Developer'},
        {'id': '2', 'name': 'Designer'},
      ]);

      final result = await repository.getProfessionalRoles();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right but got Left'), (roles) {
        expect(roles, isA<List<ProfessionalRole>>());
        expect(roles.length, 2);
        expect(roles[0].id, '1');
        expect(roles[0].name, 'Developer');
        expect(roles[1].id, '2');
        expect(roles[1].name, 'Designer');
      });
    });

    test('returns ServerFailure on error', () async {
      fakeSupabase.shouldThrowOnSelect = true;
      final result = await repository.getProfessionalRoles();
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Expected Left but got Right'),
      );
    });
  });
}
