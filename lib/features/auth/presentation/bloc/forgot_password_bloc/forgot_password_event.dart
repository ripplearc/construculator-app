// coverage:ignore-file
part of 'forgot_password_bloc.dart';

/// Abstract class for forgot password events
abstract class ForgotPasswordEvent extends Equatable {
  /// Constructor for forgot password events
  const ForgotPasswordEvent();

  /// List of properties that will be used to compare states
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
class ForgotPasswordEditEmailRequested extends ForgotPasswordEvent {
  const ForgotPasswordEditEmailRequested();
}

/// Event triggered when a form field changes, which triggers validation
class ForgotPasswordFormFieldChanged extends ForgotPasswordEvent {
  const ForgotPasswordFormFieldChanged({
    required this.field,
    required this.value,
  });

  /// The field that changed
  final ForgotPasswordFormField field;
  /// The new value of the field
  final String value;

  @override
  List<Object> get props => [field, value];
}