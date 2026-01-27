import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/auth/domain/validation/auth_validation.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/config/env_constants.dart';
import 'package:equatable/equatable.dart';
import 'package:construculator/features/auth/domain/usecases/check_email_availability_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/send_otp_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

part 'register_with_email_event.dart';
part 'register_with_email_state.dart';

/// Bloc for registering with email
/// provides functionality to check if email is available and send otp to email
class RegisterWithEmailBloc
    extends Bloc<RegisterWithEmailEvent, RegisterWithEmailState> {
  final CheckEmailAvailabilityUseCase _checkEmailAvailabilityUseCase;
  final SendOtpUseCase _sendOtpUseCase;

  RegisterWithEmailBloc({
    required CheckEmailAvailabilityUseCase checkEmailAvailabilityUseCase,
    required SendOtpUseCase sendOtpUseCase,
  }) : _checkEmailAvailabilityUseCase = checkEmailAvailabilityUseCase,
       _sendOtpUseCase = sendOtpUseCase,
       super(RegisterWithEmailInitial()) {
    on<RegisterWithEmailEmailChanged>(
      _onEmailChanged,
      transformer: (events, mapper) {
        return events.debounceTime(debounceTime).asyncExpand(mapper);
      },
    );
    on<RegisterWithEmailContinuePressed>(_onContinuePressed);
    on<RegisterWithEmailEmailEditRequested>(_onEditEmail);
    on<RegisterWithEmailFormFieldChanged>(_onFormFieldChanged);
  }

  Future<void> _onEditEmail(
    RegisterWithEmailEmailEditRequested event,
    Emitter<RegisterWithEmailState> emit,
  ) async {
    emit(RegisterWithEmailEditUserEmail());
  }

  Future<void> _onEmailChanged(
    RegisterWithEmailEmailChanged event,
    Emitter<RegisterWithEmailState> emit,
  ) async {
    emit(RegisterWithEmailEmailCheckLoading());
    final result = await _checkEmailAvailabilityUseCase(event.email);
    result.fold(
      (failure) => emit(RegisterWithEmailEmailCheckFailure(failure: failure)),
      (result) {
        emit(
          RegisterWithEmailEmailCheckCompleted(
            isEmailRegistered: result.data ?? false,
          ),
        );
      },
    );
  }

  Future<void> _onContinuePressed(
    RegisterWithEmailContinuePressed event,
    Emitter<RegisterWithEmailState> emit,
  ) async {
    emit(RegisterWithEmailOtpSendingLoading());
    final result = await _sendOtpUseCase(event.email, OtpReceiver.email);
    result.fold(
      (failure) => emit(RegisterWithEmailOtpSendingFailure(failure: failure)),
      (_) {
        emit(RegisterWithEmailOtpSendingSuccess());
      },
    );
  }

  void _onFormFieldChanged(
    RegisterWithEmailFormFieldChanged event,
    Emitter<RegisterWithEmailState> emit,
  ) {
    switch (event.field) {
      case RegisterWithEmailFormField.email:
        // Email validation using AuthValidation
        final validator = AuthValidation.validateEmail(event.value);
        final isValid = validator == null;
        emit(
          RegisterWithEmailFormFieldValidated(
            field: event.field,
            isValid: isValid,
            validator: validator,
          ),
        );

        // If email is valid, check availability
        if (isValid && event.value.isNotEmpty) {
          add(RegisterWithEmailEmailChanged(event.value));
        }
        break;
    }
  }
}
