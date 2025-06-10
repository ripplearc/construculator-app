import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/repositories/supabase_auth_repository.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseWrapper fakeSupabaseWrapper;
  late SupabaseAuthRepository authRepository;

  setUp(() {
    fakeSupabaseWrapper = FakeSupabaseWrapper();
    authRepository = SupabaseAuthRepository(
      supabaseWrapper: fakeSupabaseWrapper,
    );
  });

  tearDown(() {
    // Ensure resources are cleaned up after each test.
    authRepository.dispose();
    fakeSupabaseWrapper.dispose();
    fakeSupabaseWrapper.reset();
  });

  group('Email Registration Check', () {
    test('should confirm existing user email is registered', () async {
      const existingEmail = 'manager@construction.com';
      fakeSupabaseWrapper.addTableData('users', [
        {'id': '123', 'email': existingEmail},
      ]);

      final result = await authRepository.isEmailRegistered(existingEmail);

      expect(result.isSuccess, isTrue);
      expect(result.data, isTrue);

      final methodCalls = fakeSupabaseWrapper.getMethodCallsFor(
        'selectSingle',
      );
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first['table'], equals('users'));
      expect(methodCalls.first['columns'], equals('id'));
      expect(methodCalls.first['filterColumn'], equals('email'));
      expect(methodCalls.first['filterValue'], equals(existingEmail));
    });

    test('should confirm new email is not registered', () async {
      // No user data added, so email won't be found
      const newEmail = 'newuser@construction.com';

      final result = await authRepository.isEmailRegistered(newEmail);

      expect(result.isSuccess, isTrue);
      expect(result.data, isFalse);
    });

    test(
      'should handle database connectivity issues during email check',
      () async {
        fakeSupabaseWrapper.shouldThrowOnSelect = true;
        fakeSupabaseWrapper.selectErrorMessage =
            'Connection to database lost';

        final result = await authRepository.isEmailRegistered(
          'test@example.com',
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorType, equals(AuthErrorType.serverError));
        expect(
          result.errorMessage,
          contains('Connection to database lost'),
        );
      },
    );
  });
} 