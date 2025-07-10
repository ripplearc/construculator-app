// coverage:ignore-file
part of 'create_account_bloc.dart';

abstract class CreateAccountState extends Equatable {}

class CreateAccountInitial extends CreateAccountState {
  @override
  List<Object?> get props => [];
}

class CreateAccountLoading extends CreateAccountState {
  @override
  List<Object?> get props => [];
}

class CreateAccountSuccess extends CreateAccountState {
  @override
  List<Object?> get props => [];
}

class CreateAccountFailure extends CreateAccountState {
  final Failure failure;
  CreateAccountFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
}

class CreateAccountGetProfessionalRolesLoading extends CreateAccountState {
  @override
  List<Object?> get props => [];
}

class CreateAccountGetProfessionalRolesSuccess extends CreateAccountState {
  final List<ProfessionalRole> professionalRolesList;
  CreateAccountGetProfessionalRolesSuccess({
    required this.professionalRolesList,
  });

  @override
  List<Object?> get props => [professionalRolesList];
}

class CreateAccountGetProfessionalRolesFailure extends CreateAccountState {
  final Failure failure;
  CreateAccountGetProfessionalRolesFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
}

class CreateAccountOtpSending extends CreateAccountState {
  @override
  List<Object?> get props => [];
}

class CreateAccountOtpSendingFailure extends CreateAccountState {
  final Failure failure;
  CreateAccountOtpSendingFailure({required this.failure});
  @override
  List<Object?> get props => [failure];
}

class CreateAccountOtpSendingSuccess extends CreateAccountState {
  final String contact;
  CreateAccountOtpSendingSuccess({required this.contact});
  @override
  List<Object?> get props => [contact];
}

class CreateAccountContactVerified extends CreateAccountState {
  @override
  List<Object?> get props => [];
}

class CreateAccountEditContactSuccess extends CreateAccountState {
  @override
  List<Object?> get props => [];
}
