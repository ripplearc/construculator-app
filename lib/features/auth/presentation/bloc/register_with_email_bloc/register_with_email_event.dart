// coverage:ignore-file
part of 'register_with_email_bloc.dart';

abstract class RegisterWithEmailEvent extends Equatable {
  const RegisterWithEmailEvent();

  @override
  List<Object> get props => [];
}

class RegisterWithEmailEmailChanged extends RegisterWithEmailEvent {
  final String email;

  const RegisterWithEmailEmailChanged(this.email);

  @override
  List<Object> get props => [email];
}

class RegisterWithEmailContinuePressed extends RegisterWithEmailEvent {
  final String email;

  const RegisterWithEmailContinuePressed(this.email);

  @override
  List<Object> get props => [email];
} 


class RegisterWithEmailEditEmail extends RegisterWithEmailEvent {

  const RegisterWithEmailEditEmail();

  @override
  List<Object> get props => [];
}