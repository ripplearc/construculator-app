// coverage:ignore-file
part of 'forgot_password_bloc.dart';

/// Abstract class for forgot password events
abstract class ForgotPasswordEvent extends Equatable {
  /// Constructor for forgot password events
  const ForgotPasswordEvent();

  /// List of properties that will be used to compare events
  @override
  List<Object> get props => [];
}

/// Event triggered when the user submits the email
class ForgotPasswordSubmitted extends ForgotPasswordEvent {
  /// The email entered by the user
  final String email;

  const ForgotPasswordSubmitted(this.email);
  @override
  List<Object> get props => [email];
} 

/// Event triggered when the user presses the edit email button
class ForgotPasswordEditEmail extends ForgotPasswordEvent {
  const ForgotPasswordEditEmail();
}