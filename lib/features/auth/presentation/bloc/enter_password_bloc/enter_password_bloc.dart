import 'dart:async';

import 'package:construculator/features/auth/domain/usecases/login_usecase.dart';
import 'package:construculator/libraries/analytics/domain/entities/analytics_event.dart';
import 'package:construculator/libraries/analytics/domain/repositories/analytics_repository.dart';
import 'package:construculator/libraries/analytics/domain/utils/failure_analytics_reason.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'enter_password_event.dart';
part 'enter_password_state.dart';

/// Bloc for entering a password, submits the password to the server and logs the user in
class EnterPasswordBloc extends Bloc<EnterPasswordEvent, EnterPasswordState> {
  final LoginUseCase _loginUseCase;
  final AnalyticsRepository _analyticsRepository;

  EnterPasswordBloc({
    required this._loginUseCase,
    required this._analyticsRepository,
  }) : super(EnterPasswordInitial()) {
    on<EnterPasswordSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(
    EnterPasswordSubmitted event,
    Emitter<EnterPasswordState> emit,
  ) async {
    emit(EnterPasswordSubmitLoading());
    final result = await _loginUseCase(event.email, event.password);
    result.fold(
      (failure) {
        unawaited(
          _analyticsRepository.track(
            AnalyticsEvent(
              name: 'user_login_failed',
              properties: {'reason': failure.analyticsReason},
            ),
          ),
        );
        emit(EnterPasswordSubmitFailure(failure: failure));
      },
      (credential) {
        unawaited(
          _analyticsRepository.track(
            const AnalyticsEvent(name: 'user_logged_in'),
          ),
        );
        emit(EnterPasswordSubmitSuccess());
      },
    );
  }
}
