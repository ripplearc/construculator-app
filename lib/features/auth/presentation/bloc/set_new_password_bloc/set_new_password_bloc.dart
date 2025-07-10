import 'package:construculator/libraries/errors/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:construculator/features/auth/domain/usecases/set_new_password_usecase.dart';
part 'set_new_password_event.dart';
part 'set_new_password_state.dart';

class SetNewPasswordBloc extends Bloc<SetNewPasswordEvent, SetNewPasswordState> {
  final SetNewPasswordUseCase _setNewPasswordUseCase;

  SetNewPasswordBloc({required SetNewPasswordUseCase setNewPasswordUseCase})
      : _setNewPasswordUseCase = setNewPasswordUseCase,
        super(SetNewPasswordInitial()) {
    on<SetNewPasswordSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(SetNewPasswordSubmitted event, Emitter<SetNewPasswordState> emit) async {
    emit(SetNewPasswordLoading());
    final result = await _setNewPasswordUseCase(event.email,event.password);

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