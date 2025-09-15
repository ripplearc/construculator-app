// coverage:ignore-file
part of 'enter_password_bloc.dart';

/// Abstract class for enter password events
abstract class EnterPasswordEvent extends Equatable {
  /// Constructor for enter password events
  const EnterPasswordEvent();

  /// List of properties that will be used to compare events
  @override
  List<Object> get props => [];
}

/// Event triggered when the user submits the password
class EnterPasswordSubmitted extends EnterPasswordEvent {
  /// The email of the user
  final String email;

  /// The password entered by the user
  final String password;

  const EnterPasswordSubmitted({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}
