// coverage:ignore-file
part of 'create_account_bloc.dart';

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
  final List<ProfessionalRole> professionalRolesList;
  CreateAccountGetProfessionalRolesSuccess({
    required this.professionalRolesList,
  });

  @override
  List<Object?> get props => [professionalRolesList];
}

/// Failure state for getting professional roles, triggered when getting professional roles fails
class CreateAccountGetProfessionalRolesFailure extends CreateAccountState {
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

/// Success state for verifying contact, triggered when contact is verified successfully
class CreateAccountContactVerified extends CreateAccountState {
  @override
  List<Object?> get props => [];
}

/// Success state for editing contact, triggered when user taps on edit contact button
class CreateAccountEditContactSuccess extends CreateAccountState {
  @override
  List<Object?> get props => [];
}
