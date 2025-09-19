import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/data/validation/auth_validation.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:equatable/equatable.dart';
import 'package:construculator/features/auth/domain/usecases/send_otp_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'otp_verification_event.dart';
part 'otp_verification_state.dart';

/// Bloc for verifying an OTP, verifies the OTP and sends the OTP to the user's contact
class OtpVerificationBloc
    extends Bloc<OtpVerificationEvent, OtpVerificationState> {
  final VerifyOtpUseCase _verifyOtpUseCase;
  final SendOtpUseCase _sendOtpUseCase;

  OtpVerificationBloc({
    required VerifyOtpUseCase verifyOtpUseCase,
    required SendOtpUseCase sendOtpUseCase,
  }) : _verifyOtpUseCase = verifyOtpUseCase,
       _sendOtpUseCase = sendOtpUseCase,
       super(OtpVerificationInitial()) {
    on<OtpVerificationOtpChanged>(_onOtpChanged);
    on<OtpVerificationSubmitted>(_onOtpSubmitted);
    on<OtpVerificationResendRequested>(_onResendRequested);
  }

  Future<void> _onOtpSubmitted(
    OtpVerificationSubmitted event,
    Emitter<OtpVerificationState> emit,
  ) async {
    emit(OtpVerificationLoading());
    final result = await _verifyOtpUseCase(
      event.contact,
      event.otp,
      OtpReceiver.email,
    );
    result.fold(
      (failure) => emit(OtpVerificationFailure(failure)),
      (_) => emit(OtpVerificationSuccess(email: event.contact)),
    );
  }

  Future<void> _onResendRequested(
    OtpVerificationResendRequested event,
    Emitter<OtpVerificationState> emit,
  ) async {
    emit(OtpVerificationResendLoading());
    final result = await _sendOtpUseCase(event.contact, OtpReceiver.email);

    result.fold(
      (failure) => emit(OtpVerificationResendFailure(failure)),
      (_) => emit(OtpVerificationOtpResendSuccess()),
    );
  }

  Future<void> _onOtpChanged(
    OtpVerificationOtpChanged event,
    Emitter<OtpVerificationState> emit,
  ) async {
    final otpValidator = AuthValidation.validateOtp(event.otp);
    final otpInvalid = otpValidator != null;
    emit(
      OtpVerificationOtpChangeSuccess(otp: event.otp, otpInvalid: otpInvalid),
    );
  }
}
