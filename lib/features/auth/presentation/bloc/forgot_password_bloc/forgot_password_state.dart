// coverage:ignore-file
part of 'forgot_password_bloc.dart';

/// Enum for form fields that can be validated
enum ForgotPasswordFormField {
  email,
}

/// Abstract class for forgot password states
abstract class ForgotPasswordState extends Equatable {
  /// Constructor for forgot password states
  const ForgotPasswordState();

  /// List of properties that will be used to compare states
  @override
  List<Object?> get props => [];
}

/// State when the forgot password process is initial
class ForgotPasswordInitial extends ForgotPasswordState {
  @override
  List<Object?> get props => [];
}

/// State when the forgot password process is loading, after the user presses the continue button
class ForgotPasswordLoading extends ForgotPasswordState {
  @override
  List<Object?> get props => [];
}

/// State when the forgot password process is successful
class ForgotPasswordSuccess extends ForgotPasswordState {
  @override
  List<Object?> get props => [];
}

/// State when the forgot password process fails
class ForgotPasswordFailure extends ForgotPasswordState {
  /// The failure that occurred during the forgot password process
  final Failure failure;
  const ForgotPasswordFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
}

/// State after the user presses the edit email button
class ForgotPasswordEditEmailSuccess extends ForgotPasswordState {
  @override
  List<Object?> get props => [];
}

/// State when a form field is validated
class ForgotPasswordFormFieldValidated extends ForgotPasswordState {
  /// The field that was validated
  final ForgotPasswordFormField field;
  /// Whether the field is valid
  final bool isValid;
  /// The validation result, if any
  final AuthErrorType? validator;

  const ForgotPasswordFormFieldValidated({
    required this.field,
    required this.isValid,
    this.validator,
  });

  @override
  List<Object?> get props => [field, isValid, validator];
}