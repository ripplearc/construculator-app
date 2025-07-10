// coverage:ignore-file
part of 'login_with_email_bloc.dart';

abstract class LoginWithEmailEvent extends Equatable {
  const LoginWithEmailEvent();

  @override
  List<Object> get props => [];
}

class LoginEmailChanged extends LoginWithEmailEvent {
  const LoginEmailChanged(this.email);

  final String email;

  @override
  List<Object> get props => [email];
}

class LoginEmailSubmitted extends LoginWithEmailEvent {
  final String email;
  const LoginEmailSubmitted(this.email);

  @override
  List<Object> get props => [email];
} 