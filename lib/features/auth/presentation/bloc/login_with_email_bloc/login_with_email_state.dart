// coverage:ignore-file
part of 'login_with_email_bloc.dart';

/// Enum for form fields that can be validated
enum LoginWithEmailFormField { email }

/// Abstract class for login with email states
abstract class LoginWithEmailState extends Equatable {
  /// Constructor for login with email states
  const LoginWithEmailState();

  /// List of properties that will be used to compare defined properties, currently empty.
  @override
  List<Object?> get props => [];
}

/// The initial bloc state, typically when the login_with_email page loads.
class LoginWithEmailInitial extends LoginWithEmailState {
  @override
  List<Object?> get props => [];
}

/// State when the login process is loading, after the user enters password
/// and continue button is pressed
class LoginWithEmailLoading extends LoginWithEmailState {
  @override
  List<Object?> get props => [];
}

/// State when the login process is successful
class LoginWithEmailSuccess extends LoginWithEmailState {
  @override
  List<Object?> get props => [];
}

/// State when the login process fails
class LoginWithEmailFailure extends LoginWithEmailState {
  /// The failure that occurred during the login process
  final Failure failure;
  const LoginWithEmailFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
}

/// State when the email availability is being checked
class LoginWithEmailAvailabilityLoading extends LoginWithEmailState {
  @override
  List<Object?> get props => [];
}

/// State when the email availability is checked successfully
class LoginWithEmailAvailabilityCheckSuccess extends LoginWithEmailState {
  /// Whether the email is registered
  final bool isEmailRegistered;
  const LoginWithEmailAvailabilityCheckSuccess({
    required this.isEmailRegistered,
  });

  @override
  List<Object?> get props => [isEmailRegistered];
}

/// State when the email availability check fails
class LoginWithEmailAvailabilityCheckFailure extends LoginWithEmailState {
  /// The failure that occurred during the email availability check
  final Failure failure;
  const LoginWithEmailAvailabilityCheckFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
}

/// State when a form field is validated
class LoginWithEmailFormFieldValidated extends LoginWithEmailState {
  /// The field that was validated
  final LoginWithEmailFormField field;

  /// Whether the field is valid
  final bool isValid;

  /// The validation result, if any
  final AuthErrorType? validator;

  const LoginWithEmailFormFieldValidated({
    required this.field,
    required this.isValid,
    this.validator,
  });

  @override
  List<Object?> get props => [field, isValid, validator];
}
