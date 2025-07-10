// coverage:ignore-file
part of 'otp_verification_bloc.dart';

abstract class OtpVerificationEvent extends Equatable {
  const OtpVerificationEvent();

  @override
  List<Object> get props => [];
}

class OtpVerificationSubmitted extends OtpVerificationEvent {
  final String contact;
  final String otp;

  const OtpVerificationSubmitted({required this.contact, required this.otp});

  @override
  List<Object> get props => [contact, otp];
}

class OtpVerificationResendRequested extends OtpVerificationEvent {
  final String contact;

  const OtpVerificationResendRequested({required this.contact});

  @override
  List<Object> get props => [contact];
} 

class OtpVerificationOtpChanged extends OtpVerificationEvent {
  final String otp;

  const OtpVerificationOtpChanged({required this.otp});

  @override
  List<Object> get props => [otp];
} 