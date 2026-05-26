import 'package:construculator/features/auth/domain/usecases/params/create_account_usecase_params.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreateAccountUseCaseParams', () {
    const email = 'john@example.com';
    const firstName = 'John';
    const lastName = 'Doe';
    const role = 'Engineer';
    const password = 'securePassword123';

    group('constructor', () {
      test('creates instance with required fields', () {
        const params = CreateAccountUseCaseParams(
          firstName: firstName,
          lastName: lastName,
          professionalRole: role,
          password: password,
        );

        expect(params.firstName, firstName);
        expect(params.lastName, lastName);
        expect(params.professionalRole, role);
        expect(params.password, password);
        expect(params.email, isNull);
        expect(params.phone, isNull);
        expect(params.countryCode, isNull);
      });

      test('creates instance with email', () {
        const params = CreateAccountUseCaseParams(
          email: email,
          firstName: firstName,
          lastName: lastName,
          professionalRole: role,
          password: password,
        );

        expect(params.email, email);
      });

      test('creates instance with phone and country code', () {
        const params = CreateAccountUseCaseParams(
          phone: '1234567890',
          countryCode: '+1',
          firstName: firstName,
          lastName: lastName,
          professionalRole: role,
          password: password,
        );

        expect(params.phone, '1234567890');
        expect(params.countryCode, '+1');
      });
    });

    group('Equatable', () {
      test('two instances with same values are equal', () {
        const params1 = CreateAccountUseCaseParams(
          email: email,
          firstName: firstName,
          lastName: lastName,
          professionalRole: role,
          password: password,
        );
        const params2 = CreateAccountUseCaseParams(
          email: email,
          firstName: firstName,
          lastName: lastName,
          professionalRole: role,
          password: password,
        );

        expect(params1, equals(params2));
      });

      test('two instances with different emails are not equal', () {
        const params1 = CreateAccountUseCaseParams(
          email: 'a@example.com',
          firstName: firstName,
          lastName: lastName,
          professionalRole: role,
          password: password,
        );
        const params2 = CreateAccountUseCaseParams(
          email: 'b@example.com',
          firstName: firstName,
          lastName: lastName,
          professionalRole: role,
          password: password,
        );

        expect(params1, isNot(equals(params2)));
      });

      test('two instances with different first names are not equal', () {
        const params1 = CreateAccountUseCaseParams(
          firstName: 'Alice',
          lastName: lastName,
          professionalRole: role,
          password: password,
        );
        const params2 = CreateAccountUseCaseParams(
          firstName: 'Bob',
          lastName: lastName,
          professionalRole: role,
          password: password,
        );

        expect(params1, isNot(equals(params2)));
      });

      test('two instances with different passwords are not equal', () {
        const params1 = CreateAccountUseCaseParams(
          firstName: firstName,
          lastName: lastName,
          professionalRole: role,
          password: 'password1',
        );
        const params2 = CreateAccountUseCaseParams(
          firstName: firstName,
          lastName: lastName,
          professionalRole: role,
          password: 'password2',
        );

        expect(params1, isNot(equals(params2)));
      });

      test('instance with email is not equal to instance without email', () {
        const withEmail = CreateAccountUseCaseParams(
          email: email,
          firstName: firstName,
          lastName: lastName,
          professionalRole: role,
          password: password,
        );
        const withoutEmail = CreateAccountUseCaseParams(
          firstName: firstName,
          lastName: lastName,
          professionalRole: role,
          password: password,
        );

        expect(withEmail, isNot(equals(withoutEmail)));
      });
    });
  });
}
