import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/data/validation/auth_validation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:construculator/features/auth/domain/usecases/set_new_password_usecase.dart';
part 'set_new_password_event.dart';
part 'set_new_password_state.dart';

/// Bloc for setting a new password
/// Validates the new password and confirms it with the password confirmation field
class SetNewPasswordBloc
    extends Bloc<SetNewPasswordEvent, SetNewPasswordState> {
  final SetNewPasswordUseCase _setNewPasswordUseCase;

  SetNewPasswordBloc({required SetNewPasswordUseCase setNewPasswordUseCase})
    : _setNewPasswordUseCase = setNewPasswordUseCase,
      super(SetNewPasswordInitial()) {
    on<SetNewPasswordSubmitted>(_onSubmitted);
    on<SetNewPasswordPasswordValidationRequested>(
      _onPasswordValidationRequested,
    );
  }

  void _onPasswordValidationRequested(
    SetNewPasswordPasswordValidationRequested event,
    Emitter<SetNewPasswordState> emit,
  ) {
    switch (event.field) {
      case SetNewPasswordFormField.password:
        // Password validation using AuthValidation
        final validator = AuthValidation.validatePassword(event.value);
        final isValid = validator == null;
        emit(
          SetNewPasswordPasswordValidationSuccess(
            field: event.field,
            isValid: isValid,
            validator: validator,
          ),
        );
        break;

      case SetNewPasswordFormField.passwordConfirmation:
        // Confirm password validation - check if matches password
        if (event.value.isEmpty) {
          emit(
            SetNewPasswordPasswordValidationSuccess(
              field: event.field,
              isValid: false,
              validator: AuthErrorType.passwordRequired,
            ),
          );
        } else if (event.passwordValue != null &&
            event.value != event.passwordValue) {
          emit(
            SetNewPasswordPasswordValidationSuccess(
              field: event.field,
              isValid: false,
              validator: AuthErrorType.passwordsDoNotMatch,
            ),
          );
        } else {
          emit(
            SetNewPasswordPasswordValidationSuccess(
              field: event.field,
              isValid: true,
              validator: null,
            ),
          );
        }
        break;
    }
  }

  Future<void> _onSubmitted(
    SetNewPasswordSubmitted event,
    Emitter<SetNewPasswordState> emit,
  ) async {
    emit(SetNewPasswordLoading());
    final result = await _setNewPasswordUseCase(event.email, event.password);

    result.fold(
      (failure) {
        emit(SetNewPasswordFailure(failure: failure));
      },
      (_) {
        emit(SetNewPasswordSuccess());
      },
    );
  }
}
