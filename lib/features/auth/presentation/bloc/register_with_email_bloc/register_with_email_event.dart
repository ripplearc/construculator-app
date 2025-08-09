// coverage:ignore-file
part of 'register_with_email_bloc.dart';

/// Event for registering with email
abstract class RegisterWithEmailEvent extends Equatable {
  /// Constructor for [RegisterWithEmailEvent]
  const RegisterWithEmailEvent();

  /// List of properties to use for comparison
  @override
  List<Object> get props => [];
}

/// Event for changing email, triggered when user types in email
class RegisterWithEmailEmailChanged extends RegisterWithEmailEvent {
  /// The email to check
  final String email;

  const RegisterWithEmailEmailChanged(this.email);

  @override
  List<Object> get props => [email];
}

/// Event for continuing with email, triggered when user presses continue button
class RegisterWithEmailContinuePressed extends RegisterWithEmailEvent {
  /// The email entered by the user
  final String email;

  const RegisterWithEmailContinuePressed(this.email);

  @override
  List<Object> get props => [email];
} 

/// Event for editing email, triggered when user presses the edit button on the otp bottom sheet
class RegisterWithEmailEditEmail extends RegisterWithEmailEvent {

  const RegisterWithEmailEditEmail();

  @override
  List<Object> get props => [];
}