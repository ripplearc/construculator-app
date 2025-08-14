// coverage:ignore-file
part of 'set_new_password_bloc.dart';

/// Enum for form fields that can be validated
enum SetNewPasswordFormField {
  password,
  passwordConfirmation,
}

abstract class SetNewPasswordState extends Equatable {}

class SetNewPasswordInitial extends SetNewPasswordState {
  @override
  List<Object?> get props => [];
}

class SetNewPasswordLoading extends SetNewPasswordState {
  @override
  List<Object?> get props => [];
}

class SetNewPasswordSuccess extends SetNewPasswordState {
  @override
  List<Object?> get props => [];
}

class SetNewPasswordFailure extends SetNewPasswordState {
  final Failure failure;
  SetNewPasswordFailure({required this.failure});
  
  @override
  List<Object?> get props => [failure];
}

/// State for password validation results
class SetNewPasswordPasswordValidated extends SetNewPasswordState {
  /// The field that was validated
  final SetNewPasswordFormField field;
  /// Whether the field is valid
  final bool isValid;
  /// The validation error type, null if field is valid
  final AuthErrorType? validator;

  SetNewPasswordPasswordValidated({
    required this.field,
    required this.isValid,
    this.validator,
  });

  @override
  List<Object?> get props => [field, isValid, validator];
}
