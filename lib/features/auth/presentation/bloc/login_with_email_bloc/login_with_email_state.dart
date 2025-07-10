// coverage:ignore-file
part of 'login_with_email_bloc.dart';

abstract class LoginWithEmailState extends Equatable {}

class LoginWithEmailInitial extends LoginWithEmailState {
  @override
  List<Object?> get props => [];
}
class LoginWithEmailLoading extends LoginWithEmailState {
  @override
  List<Object?> get props => [];
}
class LoginWithEmailSuccess extends LoginWithEmailState {
  @override
  List<Object?> get props => [];
}
class LoginWithEmailFailure extends LoginWithEmailState {
  final Failure failure;
  LoginWithEmailFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
}

class LoginWithEmailAvailabilityLoading extends LoginWithEmailState {
  @override
  List<Object?> get props => [];
}

class LoginWithEmailAvailabilitySuccess extends LoginWithEmailState {
  final bool isEmailRegistered;
  LoginWithEmailAvailabilitySuccess({required this.isEmailRegistered});

  @override
  List<Object?> get props => [isEmailRegistered];
}

class LoginWithEmailAvailabilityFailure extends LoginWithEmailState {
  final Failure failure;
  LoginWithEmailAvailabilityFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
}