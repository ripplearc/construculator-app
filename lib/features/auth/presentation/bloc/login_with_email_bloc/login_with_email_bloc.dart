import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/auth/data/validation/auth_validation.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:construculator/features/auth/domain/usecases/check_email_availability_usecase.dart';

part 'login_with_email_event.dart';
part 'login_with_email_state.dart';

/// Bloc for verifying email availability, checks if the email address is available
class LoginWithEmailBloc
    extends Bloc<LoginWithEmailEvent, LoginWithEmailState> {
  final CheckEmailAvailabilityUseCase _checkEmailAvailabilityUseCase;

  LoginWithEmailBloc({
    required CheckEmailAvailabilityUseCase checkEmailAvailabilityUseCase,
  }) : _checkEmailAvailabilityUseCase = checkEmailAvailabilityUseCase,
       super(LoginWithEmailInitial()) {
    on<LoginEmailAvailabilityCheckRequested>(_onEmailChanged,);
    on<LoginWithEmailFormFieldChanged>(_onFormFieldChanged);
  }

  Future<void> _onEmailChanged(
    LoginEmailAvailabilityCheckRequested event,
    Emitter<LoginWithEmailState> emit,
  ) async {
    emit(LoginWithEmailAvailabilityLoading());
    final result = await _checkEmailAvailabilityUseCase(event.email);
    result.fold(
      (failure) {
        emit(LoginWithEmailAvailabilityCheckFailure(failure: failure));
      },
      (authResult) {
        emit(
          LoginWithEmailAvailabilityCheckSuccess(
            isEmailRegistered: authResult.data ?? true,
          ),
        );
      },
    );
  }

  void _onFormFieldChanged(
    LoginWithEmailFormFieldChanged event,
    Emitter<LoginWithEmailState> emit,
  ) {
    switch (event.field) {
      case LoginWithEmailFormField.email:
        // Email validation using AuthValidation
        final validator = AuthValidation.validateEmail(event.value);
        final isValid = validator == null;
        emit(
          LoginWithEmailFormFieldValidated(
            field: event.field,
            isValid: isValid,
            validator: validator,
          ),
        );
        
        // If email is valid, check availability
        if (isValid && event.value.isNotEmpty) {
          add(LoginEmailAvailabilityCheckRequested(event.value));
        }
        break;
    }
  }
}
