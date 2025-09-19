// coverage:ignore-file
part of 'create_account_bloc.dart';

/// Enum for form fields that can be validated
enum CreateAccountFormField {
  firstName,
  lastName,
  role,
  email,
  mobileNumber,
  password,
  confirmPassword,
}

/// Base class for all create account states
abstract class CreateAccountState extends Equatable {}

/// Initial state for create account
class CreateAccountInitial extends CreateAccountState {
  @override
  List<Object?> get props => [];
}

/// Loading state for create account, triggered when user is creating an account
class CreateAccountLoading extends CreateAccountState {
  @override
  List<Object?> get props => [];
}

/// Success state for create account, triggered when user account is created successfully
class CreateAccountSuccess extends CreateAccountState {
  @override
  List<Object?> get props => [];
}

/// Failure state for create account, triggered when user account creation fails
class CreateAccountFailure extends CreateAccountState {
  /// The failure that occurred when creating the account
  final Failure failure;
  CreateAccountFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
}

/// Loading state for getting professional roles, triggered when getting professional roles
class CreateAccountGetProfessionalRolesLoading extends CreateAccountState {
  @override
  List<Object?> get props => [];
}

/// Success state for getting professional roles, triggered when professional roles are fetched successfully
class CreateAccountGetProfessionalRolesSuccess extends CreateAccountState {
  /// The list of professional roles, when successfully loaded
  final List<ProfessionalRole> professionalRolesList;
  CreateAccountGetProfessionalRolesSuccess({
    required this.professionalRolesList,
  });

  @override
  List<Object?> get props => [professionalRolesList];
}

/// Failure state for getting professional roles, triggered when getting professional roles fails
class CreateAccountGetProfessionalRolesFailure extends CreateAccountState {
  /// The failure that occurred when getting professional roles
  final Failure failure;
  CreateAccountGetProfessionalRolesFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
}

/// Loading state for sending OTP, triggered when sending OTP
class CreateAccountOtpSending extends CreateAccountState {
  @override
  List<Object?> get props => [];
}

/// Failure state for sending OTP, triggered when sending OTP fails
class CreateAccountOtpSendingFailure extends CreateAccountState {
  /// The failure that occurred when sending OTP
  final Failure failure;
  CreateAccountOtpSendingFailure({required this.failure});
  @override
  List<Object?> get props => [failure];
}

/// Success state for sending OTP, triggered when OTP is sent successfully
class CreateAccountOtpSendingSuccess extends CreateAccountState {
  /// The contact number that OTP is sent to
  final String contact;
  CreateAccountOtpSendingSuccess({required this.contact});
  @override
  List<Object?> get props => [contact];
}

/// State for verifying contact, triggered after user taps on verify contact button on bottom sheet
class CreateAccountContactVerified extends CreateAccountState {
  @override
  List<Object?> get props => [];
}

/// State for editing contact, triggered after user taps on edit contact button on bottom sheet
class CreateAccountEditContactSuccess extends CreateAccountState {
  @override
  List<Object?> get props => [];
}

/// State for form field validation results
class CreateAccountFormFieldValidated extends CreateAccountState {
  /// The field that was validated
  final CreateAccountFormField field;

  /// Whether the field is valid
  final bool isValid;

  /// The validation error type, null if field is valid or doesn't require AuthValidation
  final AuthErrorType? validator;

  CreateAccountFormFieldValidated({
    required this.field,
    required this.isValid,
    this.validator,
  });

  @override
  List<Object?> get props => [field, isValid, validator];
}
