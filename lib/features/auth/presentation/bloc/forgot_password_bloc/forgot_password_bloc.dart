import 'package:construculator/libraries/errors/failures.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:construculator/features/auth/domain/usecases/reset_password_usecase.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final ResetPasswordUseCase _resetPasswordUseCase;

  ForgotPasswordBloc({required ResetPasswordUseCase resetPasswordUseCase})
      : _resetPasswordUseCase = resetPasswordUseCase,
        super(ForgotPasswordInitial()) {
    on<ForgotPasswordSubmitted>(_onSubmitted);
    on<ForgotPasswordEditEmailRequested>(_onEditEmail);
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
} 