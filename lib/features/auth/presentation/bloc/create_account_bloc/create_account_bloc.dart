import 'package:construculator/features/auth/domain/usecases/create_account_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/get_professional_roles_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/params/create_account_usecase_params.dart';
import 'package:construculator/features/auth/domain/usecases/send_otp_usecase.dart';
import 'package:construculator/libraries/auth/data/models/professional_role.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/data/validation/auth_validation.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'create_account_event.dart';
part 'create_account_state.dart';

class CreateAccountBloc extends Bloc<CreateAccountEvent, CreateAccountState> {
  final CreateAccountUseCase _createAccountUseCase;
  final GetProfessionalRolesUseCase _getProfessionalRolesUseCase;
  final SendOtpUseCase _sendOtpUseCase;

  CreateAccountBloc({
    required CreateAccountUseCase createAccountUseCase,
    required GetProfessionalRolesUseCase getProfessionalRolesUseCase,
    required SendOtpUseCase sendOtpUseCase,
  }) : _createAccountUseCase = createAccountUseCase,
       _getProfessionalRolesUseCase = getProfessionalRolesUseCase,
       _sendOtpUseCase = sendOtpUseCase,
       super(CreateAccountInitial()) {
    on<CreateAccountSubmitted>(_onSubmitted);
    on<LoadProfessionalRoles>(_onLoadProfessionalRoles);
    on<CreateAccountSendOtpRequested>(_onSendOtp);
    on<CreateAccountOtpVerified>(_onOtpVerified);
    on<CreateAccountEditContactPressed>(_onEditContact);
    on<CreateAccountFormFieldChanged>(_onFormFieldChanged);
  }

  void _onFormFieldChanged(
    CreateAccountFormFieldChanged event,
    Emitter<CreateAccountState> emit,
  ) {
    switch (event.field) {
      case CreateAccountFormField.firstName:
      case CreateAccountFormField.lastName:
      case CreateAccountFormField.role:
        // Simple required validation - no AuthValidation needed
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
    LoadProfessionalRoles event,
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
    result.fold(
      (failure) => emit(CreateAccountFailure(failure: failure)),
      (roles) => emit(CreateAccountSuccess()),
    );
  }
}
