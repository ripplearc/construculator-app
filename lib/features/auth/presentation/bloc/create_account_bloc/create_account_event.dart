// coverage:ignore-file
part of 'create_account_bloc.dart';

abstract class CreateAccountEvent extends Equatable {
  const CreateAccountEvent();

  @override
  List<Object?> get props => [];
}

class CreateAccountSubmitted extends CreateAccountEvent {
  final String? email;
  final String firstName;
  final String lastName;
  final String? mobileNumber;
  final String password;
  final String confirmPassword;
  final String role;
  final String phonePrefix;

  const CreateAccountSubmitted({
    required this.email,
    required this.firstName,
    required this.lastName,
    this.mobileNumber,
    required this.password,
    required this.confirmPassword,
    required this.role,
    required this.phonePrefix,
  });

  @override
  List<Object?> get props => [
        email,
        firstName,
        lastName,
        mobileNumber,
        password,
        confirmPassword,
        role,
        phonePrefix,
      ];
}

class LoadProfessionalRoles extends CreateAccountEvent {
  const LoadProfessionalRoles();

  @override
  List<Object?> get props => [];
}


class CreateAccountSendOtp extends CreateAccountEvent{
  final String address;
  final bool isEmailRegistration;
  const CreateAccountSendOtp({required this.address,required this.isEmailRegistration});

  @override
  List<Object> get props => [address,isEmailRegistration];
}

class CreateAccountOtpVerified extends CreateAccountEvent{
  final String contact;
  const CreateAccountOtpVerified({required this.contact});

  @override
  List<Object> get props => [contact];
}

class CreateAccountEditContact extends CreateAccountEvent{}