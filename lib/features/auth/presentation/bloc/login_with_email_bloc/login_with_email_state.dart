// coverage:ignore-file
part of 'login_with_email_bloc.dart';

/// Abstract class for login with email states
abstract class LoginWithEmailState extends Equatable {
  /// Constructor for login with email states
  const LoginWithEmailState();

  /// List of properties that will be used to compare states
  @override
  List<Object?> get props => [];
}

/// The initial bloc state, typically when the login_with_email page loads.
class LoginWithEmailInitial extends LoginWithEmailState {
  @override
  List<Object?> get props => [];
}

/// State when the login process is loading, after the user enters password 
/// and continue button is pressed
class LoginWithEmailLoading extends LoginWithEmailState {
  @override
  List<Object?> get props => [];
}

/// State when the login process is successful
class LoginWithEmailSuccess extends LoginWithEmailState {
  @override
  List<Object?> get props => [];
}

/// State when the login process fails
class LoginWithEmailFailure extends LoginWithEmailState {
  /// The failure that occurred during the login process
  final Failure failure;
  const LoginWithEmailFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
}

/// State when the email availability is being checked
class LoginWithEmailAvailabilityLoading extends LoginWithEmailState {
  @override
  List<Object?> get props => [];
}

/// State when the email availability is checked successfully
class LoginWithEmailAvailabilityLoaded extends LoginWithEmailState {
  /// Whether the email is registered
  final bool isEmailRegistered;
  const LoginWithEmailAvailabilityLoaded({required this.isEmailRegistered});

  @override
  List<Object?> get props => [isEmailRegistered];
}

/// State when the email availability check fails
class LoginWithEmailAvailabilityFailure extends LoginWithEmailState {
  /// The failure that occurred during the email availability check
  final Failure failure;
  const LoginWithEmailAvailabilityFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
}