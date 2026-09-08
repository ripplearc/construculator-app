import 'package:construculator/features/auth/domain/usecases/params/create_account_usecase_params.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreateAccountUseCaseParams', () {
    const params = CreateAccountUseCaseParams(
      email: 'user@example.com',
      firstName: 'Ada',
      lastName: 'Lovelace',
      professionalRole: 'Engineer',
      password: 's3cret',
    );

    test('stores all required fields', () {
      expect(params.email, 'user@example.com');
      expect(params.firstName, 'Ada');
      expect(params.lastName, 'Lovelace');
      expect(params.professionalRole, 'Engineer');
      expect(params.password, 's3cret');
      expect(params.phone, isNull);
      expect(params.countryCode, isNull);
    });

    test('props includes all fields in declaration order', () {
      expect(params.props, [
        'user@example.com',
        null,
        null,
        'Ada',
        'Lovelace',
        'Engineer',
        's3cret',
      ]);
    });

    test('equality via Equatable', () {
      const other = CreateAccountUseCaseParams(
        email: 'user@example.com',
        firstName: 'Ada',
        lastName: 'Lovelace',
        professionalRole: 'Engineer',
        password: 's3cret',
      );
      expect(params, equals(other));
    });

    test('optional phone and countryCode are stored when provided', () {
      const withPhone = CreateAccountUseCaseParams(
        phone: '+1234567890',
        countryCode: '+1',
        firstName: 'Ada',
        lastName: 'Lovelace',
        professionalRole: 'Engineer',
        password: 's3cret',
      );
      expect(withPhone.phone, '+1234567890');
      expect(withPhone.countryCode, '+1');
    });
  });
}
