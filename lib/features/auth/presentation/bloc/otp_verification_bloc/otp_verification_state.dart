// coverage:ignore-file
part of 'otp_verification_bloc.dart';

/// This is the state class for the OTP verification bloc.
/// It is used to type the states for the OTP verification bloc.
abstract class OtpVerificationState extends Equatable {
  /// This is the constructor for the OTP verification state.
  const OtpVerificationState();

  /// This is the method to get the properties of the OTP verification state.
  @override
  List<Object> get props => [];
}

/// This is the state class for the OTP verification initial state.
/// It is used to represent the initial state of the OTP verification bloc.
class OtpVerificationInitial extends OtpVerificationState {}

/// This is the state class for the OTP verification loading state.
/// It is used to represent the loading state of the OTP verification
///  bloc when a request is made to verify the OTP.
class OtpVerificationLoading extends OtpVerificationState {}

/// This is the state class for the OTP verification success state.
/// It is used to represent the success state of the OTP verification bloc 
/// when the OTP is verified successfully.
class OtpVerificationSuccess extends OtpVerificationState {
  /// The email address of the user.
  final String email;
  const OtpVerificationSuccess({required this.email});

  @override
  List<Object> get props => [email];
}

/// This is the state class for the OTP verification failure state.
/// It is used to represent the failure state of the OTP verification bloc
///  when the otp verification fails.
class OtpVerificationFailure extends OtpVerificationState {
  /// The failure reason.
  final Failure failure;

  const OtpVerificationFailure(this.failure);

  @override
  List<Object> get props => [failure];
} 


/// This is the state class for the OTP verification resend loading state.
/// It is used to represent the resend loading state of the OTP verification bloc
/// when a request is made to resend the OTP.
class OtpVerificationResendLoading extends OtpVerificationState{}

/// This is the state class for the OTP verification OTP resent state.
/// It is used to represent the OTP resent state of the OTP verification bloc
/// when the OTP is resent successfully.
class OtpVerificationOtpResent extends OtpVerificationState {}

/// This is the state class for the OTP verification resend failure state.
/// It is used to represent the resend failure state of the OTP verification bloc
/// when the OTP resend fails.
class OtpVerificationResendFailure extends OtpVerificationState {
  /// The failure reason.
  final Failure failure;

  const OtpVerificationResendFailure(this.failure);

  @override
  List<Object> get props => [failure];
}

/// This is the state class for the OTP verification OTP change updated state.
/// It is used to represent the OTP change updated state of the OTP verification bloc
/// when the OTP input field is being edited.
class OtpVerificationOtpChangeUpdated extends OtpVerificationState {
  /// The current OTP value.
  final String otp;
  const OtpVerificationOtpChangeUpdated({required this.otp});

  @override
  List<Object> get props => [otp];
}