import 'package:construculator/libraries/errors/failures.dart';
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
    on<LoginEmailChanged>(_onEmailChanged,);
  }

  Future<void> _onEmailChanged(
    LoginEmailChanged event,
    Emitter<LoginWithEmailState> emit,
  ) async {
    emit(LoginWithEmailAvailabilityLoading());
    final result = await _checkEmailAvailabilityUseCase(event.email);
    result.fold(
      (failure) {
        emit(LoginWithEmailAvailabilityFailure(failure: failure));
      },
      (authResult) {
        emit(
          LoginWithEmailAvailabilityLoaded(
            isEmailRegistered: authResult.data ?? true,
          ),
        );
      },
    );
  }
}
