import 'dart:async';

import 'package:construculator/features/auth/domain/usecases/create_account_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/get_professional_roles_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/params/create_account_usecase_params.dart';
import 'package:construculator/features/auth/domain/usecases/send_otp_usecase.dart';
import 'package:construculator/libraries/analytics/domain/entities/analytics_event.dart';
import 'package:construculator/libraries/analytics/domain/repositories/analytics_repository.dart';
import 'package:construculator/libraries/analytics/domain/utils/failure_analytics_reason.dart';
import 'package:construculator/libraries/auth/data/models/professional_role.dart';
import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/auth/domain/validation/auth_validation.dart';
import 'package:construculator/libraries/config/env_constants.dart';
import 'package:construculator/libraries/consent/domain/entities/consent_status_entity.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/consent/domain/usecases/check_consent_status_usecase.dart';
import 'package:construculator/libraries/consent/domain/usecases/params/consent_usecase_params.dart';
import 'package:construculator/libraries/consent/domain/usecases/record_consent_usecase.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

part 'create_account_event.dart';
part 'create_account_state.dart';

/// Bloc for creating a new account, orchestrates the flow of the create account process
/// Performs validation on the form fields and sends the OTP to the user's contact
class CreateAccountBloc extends Bloc<CreateAccountEvent, CreateAccountState> {
  final CreateAccountUseCase _createAccountUseCase;
  final GetProfessionalRolesUseCase _getProfessionalRolesUseCase;
  final SendOtpUseCase _sendOtpUseCase;
  final AnalyticsRepository _analyticsRepository;
  final CheckConsentStatusUseCase _checkConsentStatusUseCase;
  final RecordConsentUseCase _recordConsentUseCase;

  CreateAccountBloc({
    required this._createAccountUseCase,
    required this._getProfessionalRolesUseCase,
    required this._sendOtpUseCase,
    required this._analyticsRepository,
    required this._checkConsentStatusUseCase,
    required this._recordConsentUseCase,
  }) : super(CreateAccountInitial()) {
    on<CreateAccountSubmitted>(_onSubmitted);
    on<CreateAccountGetProfessionalRolesRequested>(_onLoadProfessionalRoles);
    on<CreateAccountSendOtpRequested>(_onSendOtp);
    on<CreateAccountOtpVerified>(_onOtpVerified);
    on<CreateAccountEditContactPressed>(_onEditContact);
    on<CreateAccountFormFieldChanged>(
      _onFormFieldChanged,
      transformer: (events, mapper) {
        return events.debounceTime(debounceTime).asyncExpand(mapper);
      },
    );
  }

  void _onFormFieldChanged(
    CreateAccountFormFieldChanged event,
    Emitter<CreateAccountState> emit,
  ) {
    switch (event.field) {
      case CreateAccountFormField.firstName:
      case CreateAccountFormField.lastName:
      case CreateAccountFormField.role:
        final isValid = event.value.isNotEmpty;
        emit(
          CreateAccountFormFieldValidated(
            field: event.field,
            isValid: isValid,
            validator: event.field == CreateAccountFormField.role
                ? AuthErrorType.roleRequired
                : event.field == CreateAccountFormField.firstName
                ? AuthErrorType.firstNameRequired
                : event.field == CreateAccountFormField.lastName
                ? AuthErrorType.lastNameRequired
                : null,
          ),
        );
        break;

      case CreateAccountFormField.email:
        // Email validation using AuthValidation
        final validator = AuthValidation.validateEmail(event.value);
        final isValid = validator == null;
        emit(
          CreateAccountFormFieldValidated(
            field: event.field,
            isValid: isValid,
            validator: validator,
          ),
        );
        break;

      case CreateAccountFormField.mobileNumber:
        // Phone validation using AuthValidation, but only if not empty for email registration
        if (event.isEmailRegistration && event.value.isEmpty) {
          // Phone is optional for email registration
          emit(
            CreateAccountFormFieldValidated(
              field: event.field,
              isValid: true,
              validator: AuthErrorType.phoneRequired,
            ),
          );
        } else {
          final fullPhone = '${event.phonePrefix ?? ''}${event.value}';
          final validator = AuthValidation.validatePhoneNumber(fullPhone);
          final isValid = validator == null;
          emit(
            CreateAccountFormFieldValidated(
              field: event.field,
              isValid: isValid,
              validator: validator,
            ),
          );
        }
        break;

      case CreateAccountFormField.password:
        // Password validation using AuthValidation
        final validator = AuthValidation.validatePassword(event.value);
        final isValid = validator == null;
        emit(
          CreateAccountFormFieldValidated(
            field: event.field,
            isValid: isValid,
            validator: validator,
          ),
        );
        break;

      case CreateAccountFormField.confirmPassword:
        // Confirm password validation - check if matches password
        if (event.value.isEmpty) {
          emit(
            CreateAccountFormFieldValidated(
              field: event.field,
              isValid: false,
              validator: AuthErrorType.passwordRequired,
            ),
          );
        } else if (event.passwordValue != null &&
            event.value != event.passwordValue) {
          emit(
            CreateAccountFormFieldValidated(
              field: event.field,
              isValid: false,
              validator: AuthErrorType.passwordsDoNotMatch,
            ),
          );
        } else {
          emit(
            CreateAccountFormFieldValidated(
              field: event.field,
              isValid: true,
              validator: null,
            ),
          );
        }
        break;
    }
  }

  Future<void> _onEditContact(
    CreateAccountEditContactPressed event,
    Emitter<CreateAccountState> emit,
  ) async {
    emit(CreateAccountEditContactSuccess());
  }

  Future<void> _onOtpVerified(
    CreateAccountOtpVerified event,
    Emitter<CreateAccountState> emit,
  ) async {
    emit(CreateAccountContactVerified());
  }

  Future<void> _onLoadProfessionalRoles(
    CreateAccountGetProfessionalRolesRequested event,
    Emitter<CreateAccountState> emit,
  ) async {
    emit(CreateAccountGetProfessionalRolesLoading());
    final result = await _getProfessionalRolesUseCase();
    result.fold(
      (failure) =>
          emit(CreateAccountGetProfessionalRolesFailure(failure: failure)),
      (roles) => emit(
        CreateAccountGetProfessionalRolesSuccess(professionalRolesList: roles),
      ),
    );
  }

  Future<void> _onSendOtp(
    CreateAccountSendOtpRequested event,
    Emitter<CreateAccountState> emit,
  ) async {
    emit(CreateAccountOtpSending());
    // verification is only available for email during phone registration and for phone
    // during email registration
    final receiver = event.isEmailRegistration
        ? OtpReceiver.phone
        : OtpReceiver.email;
    final result = await _sendOtpUseCase(event.address, receiver);
    result.fold(
      (failure) => emit(CreateAccountOtpSendingFailure(failure: failure)),
      (roles) => emit(CreateAccountOtpSendingSuccess(contact: event.address)),
    );
  }

  Future<void> _onSubmitted(
    CreateAccountSubmitted event,
    Emitter<CreateAccountState> emit,
  ) async {
    emit(CreateAccountLoading());
    final result = await _createAccountUseCase(
      CreateAccountUseCaseParams(
        email: event.email,
        firstName: event.firstName,
        lastName: event.lastName,
        password: event.password,
        professionalRole: event.role,
        phone: event.mobileNumber,
        countryCode: event.phonePrefix,
      ),
    );
    final accountFailure = result.getLeftOrNull();
    if (accountFailure != null) {
      unawaited(
        _analyticsRepository.track(
          AnalyticsEvent(
            name: 'user_registration_failed',
            properties: {'reason': accountFailure.analyticsReason},
          ),
        ),
      );
      emit(CreateAccountFailure(failure: accountFailure));
      return;
    }

    unawaited(
      _analyticsRepository.track(const AnalyticsEvent(name: 'user_registered')),
    );

    final consentFailure = await _recordSignupConsent();
    if (consentFailure != null) {
      emit(CreateAccountFailure(failure: consentFailure));
      return;
    }

    emit(CreateAccountSuccess());
  }

  // Records the user's acceptance of the currently published terms.
  //
  // Awaited rather than fire-and-forget, and awaited *before*
  // [CreateAccountSuccess] is emitted — the success state is what routes the
  // user to the shell, and reaching the shell with no acceptance on file
  // means [ConsentGuard] blocks the account signup just created.
  //
  // The button label and the terms copy the user agreed to are unchanged;
  // what is new is that agreeing now leaves a record.
  //
  // Returns the failure to surface, or null when there is nothing to do.
  Future<Failure?> _recordSignupConsent() async {
    final status = await _checkConsentStatusUseCase(
      const ConsentStatusParams(consentType: ConsentType.termsAndPrivacy),
    );

    final version = switch (status) {
      ConsentNeverGiven(:final requiredVersion) => requiredVersion.version,
      ConsentOutdated(:final requiredVersion) => requiredVersion.version,
      // Already on file, so signup has nothing to record.
      ConsentSatisfied() || ConsentUnverified() => null,
      // The requirement could not be established. Recording an acceptance
      // would mean naming a version we cannot read, so it is skipped; the
      // gate will prompt on the next launch once the requirement is known.
      ConsentIndeterminate() => null,
    };

    if (version == null) return null;

    final recordResult = await _recordConsentUseCase(
      RecordConsentParams(
        consentType: ConsentType.termsAndPrivacy,
        version: version,
      ),
    );

    return recordResult.getLeftOrNull();
  }
}
