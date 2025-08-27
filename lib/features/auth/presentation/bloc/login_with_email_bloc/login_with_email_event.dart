// coverage:ignore-file
part of 'login_with_email_bloc.dart';

/// Abstract class for login with email events
abstract class LoginWithEmailEvent extends Equatable {
  /// Constructor for login with email events
  const LoginWithEmailEvent();

  /// List of properties that will be used to compare states
  @override
  List<Object> get props => [];
}

/// Event triggered when email is changed, which triggers the validation of the email
class LoginEmailAvailabilityCheckRequested extends LoginWithEmailEvent {
  const LoginEmailAvailabilityCheckRequested(this.email);

  /// The email entered by the user
  final String email;

  @override
  List<Object> get props => [email];
}

/// Event triggered when a form field changes, which triggers validation
class LoginWithEmailFormFieldChanged extends LoginWithEmailEvent {
  const LoginWithEmailFormFieldChanged({
    required this.field,
    required this.value,
  });

  /// The field that changed
  final LoginWithEmailFormField field;

  /// The new value of the field
  final String value;

  @override
  List<Object> get props => [field, value];
}
