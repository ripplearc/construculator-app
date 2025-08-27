// coverage:ignore-file
part of 'create_account_bloc.dart';

/// Abstract class for creating account events
abstract class CreateAccountEvent extends Equatable {
  /// Constructor for creating account events
  const CreateAccountEvent();

  /// List of properties that will be used to compare events
  @override
  List<Object?> get props => [];
}

/// Event for form field changes that triggers validation
class CreateAccountFormFieldChanged extends CreateAccountEvent {
  /// The field that changed
  final CreateAccountFormField field;
  /// The new value of the field
  final String value;
  /// Whether this is an email registration (affects validation logic)
  final bool isEmailRegistration;
  /// The password value for confirm password validation
  final String? passwordValue;
  /// The phone prefix for mobile number validation
  final String? phonePrefix;

  const CreateAccountFormFieldChanged({
    required this.field,
    required this.value,
    required this.isEmailRegistration,
    this.passwordValue,
    this.phonePrefix,
  });

  @override
  List<Object?> get props => [field, value, isEmailRegistration, passwordValue, phonePrefix];
}

/// Event for submitting the create account form
class CreateAccountSubmitted extends CreateAccountEvent {
  /// The email address of the user, can be null if the user is registering with a mobile number
  final String? email;
  /// The first name of the user
  final String firstName;
  /// The last name of the user
  final String lastName;
  /// The mobile number of the user, can be null if the user is registering with an email address
  final String? mobileNumber;
  /// The password of the user
  final String password;
  /// The confirm password of the user
  final String confirmPassword;
  /// The professional role id selected by the user
  final String role;
  /// The country code of the phone number
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

/// Event for loading the professional roles
class CreateAccountGetProfessionalRolesRequested extends CreateAccountEvent {
  const CreateAccountGetProfessionalRolesRequested();

  @override
  List<Object?> get props => [];
}

/// Event for sending OTP to the user
class CreateAccountSendOtpRequested extends CreateAccountEvent{
  /// The address of the user, can be an email address or a phone number
  final String address;
  /// Whether the user is registering with an email address or a phone number
  final bool isEmailRegistration;
  const CreateAccountSendOtpRequested({required this.address,required this.isEmailRegistration});

  @override
  List<Object> get props => [address,isEmailRegistration];
}

/// Otp verification is handled by the OtpVerificationBloc
/// This event is used to notify the CreateAccountBloc that the OTP has been verified
class CreateAccountOtpVerified extends CreateAccountEvent{
  /// The contact address that OTP was sent to
  final String contact;

  const CreateAccountOtpVerified({required this.contact});

  @override
  List<Object> get props => [contact];
}

/// Event for editing the contact address, triggered after user taps on edit contact button on bottom sheet
/// This allows the UI to hide the bottom sheet and focus on the contact input field
class CreateAccountEditContactPressed extends CreateAccountEvent{}