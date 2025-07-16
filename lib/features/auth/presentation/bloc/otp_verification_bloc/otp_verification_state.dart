// coverage:ignore-file
part of 'otp_verification_bloc.dart';

abstract class OtpVerificationState extends Equatable {
  const OtpVerificationState();

  @override
  List<Object> get props => [];
}

class OtpVerificationInitial extends OtpVerificationState {}

class OtpVerificationLoading extends OtpVerificationState {}

class OtpVerificationOtpResent extends OtpVerificationState {}

class OtpVerificationResendLoading extends OtpVerificationState{}

class OtpVerificationResendFailure extends OtpVerificationState {
  final Failure failure;

  const OtpVerificationResendFailure(this.failure);

  @override
  List<Object> get props => [failure];
}

class OtpVerificationSuccess extends OtpVerificationState {
  final String email;
  const OtpVerificationSuccess({required this.email});

  @override
  List<Object> get props => [email];
}

class OtpVerificationFailure extends OtpVerificationState {
  final Failure failure;

  const OtpVerificationFailure(this.failure);

  @override
  List<Object> get props => [failure];
} 

class OtpVerificationOtpChangeUpdated extends OtpVerificationState {
  final String otp;
  const OtpVerificationOtpChangeUpdated({required this.otp});

  @override
  List<Object> get props => [otp];
}