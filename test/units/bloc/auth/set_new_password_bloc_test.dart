import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/features/auth/presentation/bloc/set_new_password_bloc/set_new_password_bloc.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:construculator/features/auth/testing/auth_test_module.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';

void main() {
  group('SetNewPasswordBloc Tests', () {
    late FakeSupabaseWrapper fakeSupabase;
    late SetNewPasswordBloc bloc;
    const testEmail = 'test@example.com';

    FakeUser createFakeUser(String email) {
      return FakeUser(
        id: 'fake-user-${email.hashCode}',
        email: email,
        createdAt: DateTime.now().toIso8601String(),
      );
    }

    setUp(() {
      Modular.init(AuthTestModule());
      fakeSupabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
      bloc = SetNewPasswordBloc(setNewPasswordUseCase: Modular.get());
    });

    tearDown(() {
      bloc.close();
      fakeSupabase.reset();
      Modular.destroy();
    });

    group('SetNewPasswordSubmitted', () {
      blocTest<SetNewPasswordBloc, SetNewPasswordState>(
        'emits [SetNewPasswordLoading, SetNewPasswordSuccess] when password update succeeds',
        build: () {
          fakeSupabase.setCurrentUser(createFakeUser(testEmail));
          return bloc;
        },
        act:
            (bloc) => bloc.add(
              SetNewPasswordSubmitted(
                email: testEmail,
                password: '@Password123!',
              ),
            ),
        expect: () => [SetNewPasswordLoading(), SetNewPasswordSuccess()],
      );

      blocTest<SetNewPasswordBloc, SetNewPasswordState>(
        'emits [SetNewPasswordLoading, SetNewPasswordFailure] when password is invalid',
        build: () {
          fakeSupabase.shouldThrowOnUpdate = true;
          return bloc;
        },
        act:
            (bloc) => bloc.add(
              SetNewPasswordSubmitted(
                email: testEmail,
                password: 'invalidpass',
              ),
            ),
        expect: () => [SetNewPasswordLoading(), isA<SetNewPasswordFailure>()],
      );
    });
  });
}
