// coverage:ignore-file
part of 'login_with_email_bloc.dart';

/// Abstract class for login with email events
abstract class LoginWithEmailEvent extends Equatable {
  /// Constructor for login with email events
  const LoginWithEmailEvent();

  /// List of properties that will be used to compare events
  @override
  List<Object> get props => [];
}

/// Event triggered when email is changed, which triggers the validation of the email
class LoginEmailChanged extends LoginWithEmailEvent {
  const LoginEmailChanged(this.email);

  /// The email entered by the user
  final String email;

  @override
  List<Object> get props => [email];
}