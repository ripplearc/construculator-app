// coverage:ignore-file
part of 'enter_password_bloc.dart';

abstract class EnterPasswordEvent extends Equatable {}

class EnterPasswordSubmitted extends EnterPasswordEvent {
  final String email;
  final String password;
  EnterPasswordSubmitted({required this.email, required this.password});
  @override
  List<Object> get props => [email, password];
}