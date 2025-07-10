// coverage:ignore-file
part of 'enter_password_bloc.dart';

abstract class EnterPasswordState extends Equatable {}

class EnterPasswordInitial extends EnterPasswordState {
  @override
  List<Object?> get props => [];
}

class EnterPasswordSubmitLoading extends EnterPasswordState {
  @override
  List<Object?> get props => [];
}

class EnterPasswordSubmitSuccess extends EnterPasswordState {
  @override
  List<Object?> get props => [];
}

class EnterPasswordSubmitFailure extends EnterPasswordState { 
  final Failure failure;
  EnterPasswordSubmitFailure({required this.failure});
  @override
  List<Object?> get props => [failure];
}
