import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/auth/data/validation/auth_validation.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:construculator/features/auth/domain/usecases/reset_password_usecase.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

/// Bloc for resetting a password, orchestrates the flow of the reset password process
/// Sends the reset password email to the user
class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final ResetPasswordUseCase _resetPasswordUseCase;

  ForgotPasswordBloc({required ResetPasswordUseCase resetPasswordUseCase})
      : _resetPasswordUseCase = resetPasswordUseCase,
        super(ForgotPasswordInitial()) {
    on<ForgotPasswordSubmitted>(_onSubmitted);
    on<ForgotPasswordEditEmailRequested>(_onEditEmail);
    on<ForgotPasswordFormFieldChanged>(_onFormFieldChanged);
  }

  Future<void> _onEditEmail(
    ForgotPasswordEditEmailRequested event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(ForgotPasswordEditEmailSuccess());
  }

  Future<void> _onSubmitted(ForgotPasswordSubmitted event, Emitter<ForgotPasswordState> emit) async {
    emit(ForgotPasswordLoading());
    final result = await _resetPasswordUseCase(event.email);
    result.fold(
      (failure) {
        emit(ForgotPasswordFailure(failure: failure));
      },
      (_) {
        emit(ForgotPasswordSuccess());
      },
    );
  }

  void _onFormFieldChanged(
    ForgotPasswordFormFieldChanged event,
    Emitter<ForgotPasswordState> emit,
  ) {
    switch (event.field) {
      case ForgotPasswordFormField.email:
        // Email validation using AuthValidation
        final validator = AuthValidation.validateEmail(event.value);
        final isValid = validator == null;
        emit(
          ForgotPasswordFormFieldValidated(
            field: event.field,
            isValid: isValid,
            validator: validator,
          ),
        );
        break;
    }
  }
} 