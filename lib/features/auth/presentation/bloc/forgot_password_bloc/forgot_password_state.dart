// coverage:ignore-file
part of 'forgot_password_bloc.dart';

abstract class ForgotPasswordState extends Equatable {}


class ForgotPasswordLoading extends ForgotPasswordState {
  @override
  List<Object?> get props => [];
}

class ForgotPasswordInitial extends ForgotPasswordState {
  @override
  List<Object?> get props => [];
}

class ForgotPasswordSuccess extends ForgotPasswordState {
  @override
  List<Object?> get props => [];
}

class ForgotPasswordFailure extends ForgotPasswordState {
  final Failure failure;
  ForgotPasswordFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
}
