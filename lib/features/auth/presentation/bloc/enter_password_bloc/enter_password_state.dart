// coverage:ignore-file
part of 'enter_password_bloc.dart';

/// Abstract class for enter password states
abstract class EnterPasswordState extends Equatable {
  /// Constructor for enter password states
  const EnterPasswordState();

  /// List of properties that will be used to compare states
  @override
  List<Object?> get props => [];
}

/// The initial bloc state, typically when the enter_password page loads.
class EnterPasswordInitial extends EnterPasswordState {
  @override
  List<Object?> get props => [];
}

/// State when the password is being submitted
class EnterPasswordSubmitLoading extends EnterPasswordState {
  @override
  List<Object?> get props => [];
}

/// State when the password is submitted successfully
class EnterPasswordSubmitSuccess extends EnterPasswordState {
  @override
  List<Object?> get props => [];
}

/// State when the password submission fails
class EnterPasswordSubmitFailure extends EnterPasswordState { 
  /// The failure that occurred during the password submission
  final Failure failure;
  const EnterPasswordSubmitFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
}
