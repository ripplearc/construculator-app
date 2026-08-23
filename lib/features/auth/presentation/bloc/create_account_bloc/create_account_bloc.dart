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
import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:construculator/libraries/consent/domain/entities/consent_status_entity.dart';
import 'package:construculator/libraries/consent/domain/entities/consent_version_entity.dart';
import 'package:construculator/libraries/consent/domain/repositories/consent_repository.dart';
import 'package:construculator/libraries/consent/domain/types/consent_error_type.dart';
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
  final EnvLoader _envLoader;

  CreateAccountBloc({
    required this._createAccountUseCase,
    required this._getProfessionalRolesUseCase,
    required this._sendOtpUseCase,
    required this._analyticsRepository,
    required this._checkConsentStatusUseCase,
    required this._recordConsentUseCase,
    required this._envLoader,
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

    // Recording targets InMemoryLocalConsentDataSource, which has no
    // server-side write path (CA-971) and loses everything on restart --
    // this is currently the only production code path that writes into it
    // at all, so it must ship inert everywhere the route guard does.
    // CONSENT_GATE_ENABLED already governs the guard in shell_module.dart;
    // turning it off must turn this off too, not just hide the gate UI.
    if (_envLoader.get(consentGateEnabledKey) == 'true') {
      final consentFailure = await _recordSignupConsent();
      if (consentFailure != null) {
        emit(CreateAccountFailure(failure: consentFailure));
        return;
      }
    }

    emit(CreateAccountSuccess());
  }

  // Awaited before CreateAccountSuccess, or ConsentGuard blocks the account
  // just created. Returns the failure to surface, or null when done.
  Future<Failure?> _recordSignupConsent() async {
    final status = await _checkConsentStatusUseCase(
      const ConsentStatusParams(consentType: ConsentType.termsAndPrivacy),
    );

    // The version to record, or the failure to surface instead -- computed
    // as one value up front so the write below has a single call site
    // rather than duplicating the status match.
    final (ConsentVersion?, Failure?) versionOrFailure = switch (status) {
      ConsentNeverGiven(:final requiredVersion) => (requiredVersion, null),
      ConsentOutdated(:final requiredVersion) => (requiredVersion, null),
      // A real prior acceptance: signup has nothing to record. Excludes the
      // synthetic no-user-id marker handled below -- a real acceptance's
      // version always traces to a published row, enforced to be >= 1, so
      // acceptedVersion can only equal ConsentRepository.noUserVersion (0)
      // as that marker, never as a genuine version.
      ConsentSatisfied(:final acceptedVersion)
          when acceptedVersion != ConsentRepository.noUserVersion =>
        (null, null),
      // A prior acceptance exists but couldn't be reconfirmed against the
      // server right now -- the gate's own fail-open leniency. Nothing new
      // to record.
      ConsentUnverified() => (null, null),
      // The synthetic "could not identify the user" marker used to reach
      // this same (null, null) arm, silently reporting success while
      // recording nothing -- reachable for exactly the user this method
      // exists to protect: a brand-new signup, whose session token is
      // minted before createUserProfile runs, making internal_user_id the
      // claim most likely to still be missing. Silently equating "could not
      // identify the user" with "already consented" is the same fail-open
      // shape #537-#543 already fixed upstream.
      ConsentSatisfied() => (
        null,
        const ConsentFailure(errorType: ConsentErrorType.authenticationError),
      ),
      // The requirement itself could not be established (a failed local
      // read, or nothing published yet). Also used to silently return null
      // here; recording an acceptance is genuinely impossible without a
      // version to name, but reporting success while doing nothing is not
      // the same thing as correctly doing nothing.
      ConsentIndeterminate() => (
        null,
        const ConsentFailure(errorType: ConsentErrorType.unexpectedError),
      ),
    };

    final (version, failure) = versionOrFailure;
    if (version == null) return failure;

    final recordResult = await _recordConsentUseCase(
      RecordConsentParams(
        consentType: ConsentType.termsAndPrivacy,
        version: version.version,
      ),
    );

    return recordResult.getLeftOrNull();
  }
}
