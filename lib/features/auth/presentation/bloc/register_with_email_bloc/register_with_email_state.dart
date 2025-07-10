// coverage:ignore-file
part of 'register_with_email_bloc.dart';

abstract class RegisterWithEmailState extends Equatable {
  const RegisterWithEmailState();

  @override
  List<Object?> get props => [];
}

/// The initial bloc state, typically when the register_with_email page loads.
class RegisterWithEmailInitial extends RegisterWithEmailState {}

/// State when registration email is being checked for availability
/// Submit button is disabled when the bloc is in this state
class RegisterWithEmailEmailCheckLoading extends RegisterWithEmailState {
  @override
  List<Object?> get props => [];
}

/// State when email availability check returns successfully
class RegisterWithEmailEmailCheckSuccess extends RegisterWithEmailState {
  /// [isEmailRegistered] indicates whether the email is taken or or not
  final bool isEmailRegistered;
  const RegisterWithEmailEmailCheckSuccess({required this.isEmailRegistered});

  @override
  List<Object?> get props => [isEmailRegistered];
}

/// State when an error occurred during the check
class RegisterWithEmailEmailCheckFailure extends RegisterWithEmailState {
  /// [failure] represents the error that occured
  final Failure failure;

  const RegisterWithEmailEmailCheckFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
}

class RegisterWithEmailOtpSendingLoading extends RegisterWithEmailState {
  @override
  List<Object?> get props => [];
}

/// State when submited email for registration is successful
/// When successful, an otp is sent to the provided email
class RegisterWithEmailOtpSendingSuccess extends RegisterWithEmailState {
  const RegisterWithEmailOtpSendingSuccess();

    @override
  List<Object?> get props => [];
}

/// State when email submission for otp fails
class RegisterWithEmailOtpSendingFailure extends RegisterWithEmailState {
  /// [failure] represents the error that occured 
  final Failure failure;

  const RegisterWithEmailOtpSendingFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
} 

/// State when user is editing email
class RegisterWithEmailEditUserEmail extends RegisterWithEmailState {}