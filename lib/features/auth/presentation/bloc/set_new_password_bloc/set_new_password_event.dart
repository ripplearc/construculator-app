// coverage:ignore-file
part of 'set_new_password_bloc.dart';

/// Abstract class for set new password events
abstract class SetNewPasswordEvent extends Equatable {
  /// Constructor for set new password events
  const SetNewPasswordEvent();

  /// List of properties that will be used to compare events
  @override
  List<Object> get props => [];
}

/// Event triggered when the user submits the new password
class SetNewPasswordSubmitted extends SetNewPasswordEvent {
  /// The email of the user
  final String email;
  /// The new password entered by the user
  final String password;
  const SetNewPasswordSubmitted({required this.email, required this.password});
}

/// Event triggered as user types in the new password
class SetNewPasswordPasswordValidationRequested extends SetNewPasswordEvent {
  /// The field that was validated
  final SetNewPasswordFormField field;
  /// The value of the field that was validated
  final String value;
  /// The value of the password to confirm against the password value
  final String? passwordValue;

  const SetNewPasswordPasswordValidationRequested({
    required this.field,
    required this.value,
    this.passwordValue,
  });

  @override
  List<Object> get props => [field, value, passwordValue ?? ''];
}
