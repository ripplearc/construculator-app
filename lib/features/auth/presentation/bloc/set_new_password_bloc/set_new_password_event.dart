// coverage:ignore-file
part of 'set_new_password_bloc.dart';

abstract class SetNewPasswordEvent extends Equatable {
  const SetNewPasswordEvent();
  @override
  List<Object> get props => [];
}

class SetNewPasswordSubmitted extends SetNewPasswordEvent {
  final String email;
  final String password;
  const SetNewPasswordSubmitted({required this.email, required this.password});
}

class SetNewPasswordPasswordValidationRequested extends SetNewPasswordEvent {
  final SetNewPasswordFormField field;
  final String value;
  final String? passwordValue;

  const SetNewPasswordPasswordValidationRequested({
    required this.field,
    required this.value,
    this.passwordValue,
  });

  @override
  List<Object> get props => [field, value, passwordValue ?? ''];
}
