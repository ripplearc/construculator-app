// coverage:ignore-file
part of 'set_new_password_bloc.dart';

/// Enum for form fields that can be validated
enum SetNewPasswordFormField { password, passwordConfirmation }

/// Abstract class for set new password states
abstract class SetNewPasswordState extends Equatable {
  /// Constructor for set new password states
  const SetNewPasswordState();

  /// List of properties that will be used to compare states
  @override
  List<Object?> get props => [];
}

/// The initial bloc state, typically when the set_new_password page loads.
class SetNewPasswordInitial extends SetNewPasswordState {
  @override
  List<Object?> get props => [];
}

/// State when the set new password process is loading, after the user presses the continue button
class SetNewPasswordLoading extends SetNewPasswordState {
  @override
  List<Object?> get props => [];
}

/// State when the set new password process is successful
class SetNewPasswordSuccess extends SetNewPasswordState {
  @override
  List<Object?> get props => [];
}

/// State when the set new password process fails
class SetNewPasswordFailure extends SetNewPasswordState {
  /// The failure that occurred during the set new password process
  final Failure failure;
  const SetNewPasswordFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
}

/// State for password validation results
class SetNewPasswordPasswordValidationSuccess extends SetNewPasswordState {
  /// The field that was validated
  final SetNewPasswordFormField field;

  /// Whether the field is valid
  final bool isValid;

  /// The validation error type, null if field is valid
  final AuthErrorType? validator;

  const SetNewPasswordPasswordValidationSuccess({
    required this.field,
    required this.isValid,
    this.validator,
  });

  @override
  List<Object?> get props => [field, isValid, validator];
}
