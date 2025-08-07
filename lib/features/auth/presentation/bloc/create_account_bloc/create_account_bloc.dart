import 'package:construculator/features/auth/domain/usecases/create_account_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/get_professional_roles_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/params/create_account_usecase_params.dart';
import 'package:construculator/features/auth/domain/usecases/send_otp_usecase.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
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
    on<CreateAccountSendOtp>(_onSendOtp);
    on<CreateAccountOtpVerified>(_onOtpVerified);
    on<CreateAccountEditContact>(_onEditContact);
  }

  Future<void> _onEditContact(
    CreateAccountEditContact event,
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
      (failure) => emit(
        CreateAccountGetProfessionalRolesFailure(failure: failure),
      ),
      (roles) => emit(CreateAccountGetProfessionalRolesSuccess(professionalRolesList: roles)),
    );
  }
    Future<void> _onSendOtp(
    CreateAccountSendOtp event,
    Emitter<CreateAccountState> emit,
  ) async {
    emit(CreateAccountOtpSending());
    // verification is only available for email during phone registration and for phone
    // during email registration
    final receiver = event.isEmailRegistration ? OtpReceiver.phone : OtpReceiver.email;
    final result = await _sendOtpUseCase(event.address,receiver);
    result.fold(
      (failure) => emit(
        CreateAccountOtpSendingFailure(failure: failure),
      ),
      (roles) => emit(CreateAccountOtpSendingSuccess(contact: event.address)),
    );
  }
  Future<void> _onSubmitted(
    CreateAccountSubmitted event,
    Emitter<CreateAccountState> emit, 
  ) async {
    emit(CreateAccountLoading());
    final result = await _createAccountUseCase(CreateAccountUseCaseParams(
      email: event.email,
      firstName: event.firstName,
      lastName: event.lastName,
      password: event.password,
      professionalRole: event.role,
      phone: event.mobileNumber,
      countryCode: event.phonePrefix,
    ));
    result.fold(
      (failure) => emit(
        CreateAccountFailure(failure: failure),
      ),
      (roles) => emit(CreateAccountSuccess()),
    );
 }
}
