import 'package:construculator/features/auth/domain/usecases/check_email_availability_usecase.dart';
import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/auth/domain/validation/auth_validation.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'login_with_email_event.dart';
part 'login_with_email_state.dart';

/// Bloc for verifying email availability, checks if the email address is available
class LoginWithEmailBloc
    extends Bloc<LoginWithEmailEvent, LoginWithEmailState> {
  final CheckEmailAvailabilityUseCase _checkEmailAvailabilityUseCase;

  // Monotonically increasing token for availability checks. Checks fired for
  // successive keystrokes execute concurrently, so whichever RPC resolved
  // last used to win the final emit — a stale response for an older input
  // (e.g. "user@example.co" while typing "user@example.com") could overwrite
  // the verdict for the email currently in the field. A completed check
  // whose token is no longer current discards its result instead.
  int _availabilityCheckGeneration = 0;

  LoginWithEmailBloc({
    required this._checkEmailAvailabilityUseCase,
  }) : super(LoginWithEmailInitial()) {
    on<LoginEmailAvailabilityCheckRequested>(_onEmailChanged);
    on<LoginWithEmailFormFieldChanged>(_onFormFieldChanged);
  }

  Future<void> _onEmailChanged(
    LoginEmailAvailabilityCheckRequested event,
    Emitter<LoginWithEmailState> emit,
  ) async {
    final generation = ++_availabilityCheckGeneration;
    emit(LoginWithEmailAvailabilityLoading());
    final result = await _checkEmailAvailabilityUseCase(event.email);
    if (generation != _availabilityCheckGeneration) return;
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
        final validator = AuthValidation.validateEmail(event.value);
        final isValid = validator == null;
        emit(
          LoginWithEmailFormFieldValidated(
            field: event.field,
            isValid: isValid,
            validator: validator,
          ),
        );
        if (isValid && event.value.isNotEmpty) {
          add(LoginEmailAvailabilityCheckRequested(event.value));
        }
        break;
    }
  }
}
