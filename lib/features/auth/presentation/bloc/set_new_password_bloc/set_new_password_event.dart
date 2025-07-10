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
