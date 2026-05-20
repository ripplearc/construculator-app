import 'package:equatable/equatable.dart';

/// Input Parameters for the [CreateAccountUseCase]
class CreateAccountUseCaseParams extends Equatable {
  /// The user's email address, this can be null if [registrationType] is [AccountRegistrationType.phoneRegistration]
  final String? email;

  /// The user's phone number, this can be null if [registrationType] is [AccountRegistrationType.emailRegistration]
  final String? phone;

  final String? countryCode;

  /// The user's first name
  final String firstName;

  /// The user's last name
  final String lastName;

  /// The user's professional role
  final String professionalRole;

  /// The user's password
  final String password;

  const CreateAccountUseCaseParams({
    this.email,
    this.phone,
    this.countryCode,
    required this.firstName,
    required this.lastName,
    required this.professionalRole,
    required this.password,
  });

  @override
  List<Object?> get props => [
        email,
        phone,
        countryCode,
        firstName,
        lastName,
        professionalRole,
        password,
      ];
}
