// coverage:ignore-file
part of 'set_new_password_bloc.dart';

abstract class SetNewPasswordState extends Equatable {}

class SetNewPasswordInitial extends SetNewPasswordState {
  @override
  List<Object?> get props => [];
}

class SetNewPasswordLoading extends SetNewPasswordState {
  @override
  List<Object?> get props => [];
}

class SetNewPasswordSuccess extends SetNewPasswordState {
  @override
  List<Object?> get props => [];
}

class SetNewPasswordFailure extends SetNewPasswordState {
  final Failure failure;
  SetNewPasswordFailure({required this.failure});
  
  @override
  List<Object?> get props => [failure];
}
