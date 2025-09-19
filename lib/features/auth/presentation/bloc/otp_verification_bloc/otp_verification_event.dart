// coverage:ignore-file
part of 'otp_verification_bloc.dart';

/// This is the event class for the OTP verification bloc.
/// It is used to type the events for the OTP verification bloc.
abstract class OtpVerificationEvent extends Equatable {
  /// This is the constructor for the OTP verification event.
  const OtpVerificationEvent();

  /// This is the method to get the properties of the OTP verification event.
  @override
  List<Object> get props => [];
}

/// This is the event class for the OTP verification submitted event.
/// It is triggered when the user submits the OTP verification.
class OtpVerificationSubmitted extends OtpVerificationEvent {
  /// The contact number to verify.
  final String contact;

  /// The OTP for verification.
  final String otp;

  const OtpVerificationSubmitted({required this.contact, required this.otp});

  @override
  List<Object> get props => [contact, otp];
}

/// This is the event class for the OTP verification resend request event.
/// It is triggered when the user requests to resend the OTP verification.
class OtpVerificationResendRequested extends OtpVerificationEvent {
  /// The contact number to send the OTP to.
  final String contact;

  const OtpVerificationResendRequested({required this.contact});

  @override
  List<Object> get props => [contact];
}

/// This is the event class for the OTP verification OTP changed event.
/// It is triggered when the OTP input field is being edited.
class OtpVerificationOtpChanged extends OtpVerificationEvent {
  /// The current OTP value.
  final String otp;

  const OtpVerificationOtpChanged({required this.otp});

  @override
  List<Object> get props => [otp];
}
