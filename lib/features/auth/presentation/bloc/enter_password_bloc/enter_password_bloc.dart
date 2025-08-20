import 'package:construculator/libraries/errors/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:construculator/features/auth/domain/usecases/login_usecase.dart';

part 'enter_password_event.dart';
part 'enter_password_state.dart';

/// Bloc for entering a password, submits the password to the server and logs the user in
class EnterPasswordBloc extends Bloc<EnterPasswordEvent, EnterPasswordState> {
  final LoginUseCase _loginUseCase;

  EnterPasswordBloc({required LoginUseCase loginUseCase}) 
      : _loginUseCase = loginUseCase,
        super(EnterPasswordInitial()) {
    on<EnterPasswordSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(
    EnterPasswordSubmitted event,
    Emitter<EnterPasswordState> emit,
  ) async {
    emit(EnterPasswordSubmitLoading());
    final result = await _loginUseCase(event.email, event.password);
    result.fold(
      (failure) => emit(EnterPasswordSubmitFailure(failure: failure)),
      (credential) => emit(EnterPasswordSubmitSuccess()),
    );
  }
} 