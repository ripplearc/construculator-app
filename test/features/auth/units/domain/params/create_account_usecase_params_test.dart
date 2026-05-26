import 'package:construculator/features/auth/domain/usecases/params/create_account_usecase_params.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreateAccountUseCaseParams', () {
    const _email = 'john@example.com';
    const _firstName = 'John';
    const _lastName = 'Doe';
    const _role = 'Engineer';
    const _password = 'securePassword123';

    group('constructor', () {
      test('creates instance with required fields', () {
        const params = CreateAccountUseCaseParams(
          firstName: _firstName,
          lastName: _lastName,
          professionalRole: _role,
          password: _password,
        );

        expect(params.firstName, _firstName);
        expect(params.lastName, _lastName);
        expect(params.professionalRole, _role);
        expect(params.password, _password);
        expect(params.email, isNull);
        expect(params.phone, isNull);
        expect(params.countryCode, isNull);
      });

      test('creates instance with email', () {
        const params = CreateAccountUseCaseParams(
          email: _email,
          firstName: _firstName,
          lastName: _lastName,
          professionalRole: _role,
          password: _password,
        );

        expect(params.email, _email);
      });

      test('creates instance with phone and country code', () {
        const params = CreateAccountUseCaseParams(
          phone: '1234567890',
          countryCode: '+1',
          firstName: _firstName,
          lastName: _lastName,
          professionalRole: _role,
          password: _password,
        );

        expect(params.phone, '1234567890');
        expect(params.countryCode, '+1');
      });
    });

    group('Equatable', () {
      test('two instances with same values are equal', () {
        const params1 = CreateAccountUseCaseParams(
          email: _email,
          firstName: _firstName,
          lastName: _lastName,
          professionalRole: _role,
          password: _password,
        );
        const params2 = CreateAccountUseCaseParams(
          email: _email,
          firstName: _firstName,
          lastName: _lastName,
          professionalRole: _role,
          password: _password,
        );

        expect(params1, equals(params2));
      });

      test('two instances with different emails are not equal', () {
        const params1 = CreateAccountUseCaseParams(
          email: 'a@example.com',
          firstName: _firstName,
          lastName: _lastName,
          professionalRole: _role,
          password: _password,
        );
        const params2 = CreateAccountUseCaseParams(
          email: 'b@example.com',
          firstName: _firstName,
          lastName: _lastName,
          professionalRole: _role,
          password: _password,
        );

        expect(params1, isNot(equals(params2)));
      });

      test('two instances with different first names are not equal', () {
        const params1 = CreateAccountUseCaseParams(
          firstName: 'Alice',
          lastName: _lastName,
          professionalRole: _role,
          password: _password,
        );
        const params2 = CreateAccountUseCaseParams(
          firstName: 'Bob',
          lastName: _lastName,
          professionalRole: _role,
          password: _password,
        );

        expect(params1, isNot(equals(params2)));
      });

      test('two instances with different passwords are not equal', () {
        const params1 = CreateAccountUseCaseParams(
          firstName: _firstName,
          lastName: _lastName,
          professionalRole: _role,
          password: 'password1',
        );
        const params2 = CreateAccountUseCaseParams(
          firstName: _firstName,
          lastName: _lastName,
          professionalRole: _role,
          password: 'password2',
        );

        expect(params1, isNot(equals(params2)));
      });

      test('instance with email is not equal to instance without email', () {
        const withEmail = CreateAccountUseCaseParams(
          email: _email,
          firstName: _firstName,
          lastName: _lastName,
          professionalRole: _role,
          password: _password,
        );
        const withoutEmail = CreateAccountUseCaseParams(
          firstName: _firstName,
          lastName: _lastName,
          professionalRole: _role,
          password: _password,
        );

        expect(withEmail, isNot(equals(withoutEmail)));
      });
    });
  });
}
