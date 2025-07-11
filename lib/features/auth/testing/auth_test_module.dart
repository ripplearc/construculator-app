// coverage:ignore-file
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/auth/domain/usecases/check_email_availability_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/create_account_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/get_professional_roles_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/send_otp_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/login_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/set_new_password_usecase.dart';
import 'package:construculator/features/auth/presentation/bloc/create_account_bloc/create_account_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/otp_verification_bloc/otp_verification_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/register_with_email_bloc/register_with_email_bloc.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/router/testing/router_test_module.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:flutter_modular/flutter_modular.dart';

class AuthTestModule extends Module {
  @override
  List<Module> get imports => [
    AuthLibraryModule(
      AppBootstrap(
        envLoader: FakeEnvLoader(),
        config: FakeAppConfig(),
        supabaseWrapper: FakeSupabaseWrapper(),
      ),
    ),
    RouterTestModule(),
  ];

  @override
  void binds(Injector i) {
    i.add<ResetPasswordUseCase>(() => ResetPasswordUseCase(i()));
    i.add<GetProfessionalRolesUseCase>(
      () => GetProfessionalRolesUseCase(i()),
    );
    i.add<CheckEmailAvailabilityUseCase>(
      () => CheckEmailAvailabilityUseCase(i()),
    );
    i.add<CreateAccountUseCase>(() => CreateAccountUseCase(i()));
    i.add<SendOtpUseCase>(() => SendOtpUseCase(i()));
    i.add<VerifyOtpUseCase>(() => VerifyOtpUseCase(i()));
    i.add<LoginUseCase>(() => LoginUseCase(i()));
    i.add<SetNewPasswordUseCase>(() => SetNewPasswordUseCase(i()));
    i.add<OtpVerificationBloc>(
      () => OtpVerificationBloc(
        verifyOtpUseCase: i(),
        sendOtpUseCase: i(),
      ),
    );
    i.add<RegisterWithEmailBloc>(
      () => RegisterWithEmailBloc(
        checkEmailAvailabilityUseCase: i(),
        sendOtpUseCase: i(),
      ),
    );
    i.add<CreateAccountBloc>(
      () => CreateAccountBloc(
        createAccountUseCase: i(),
        getProfessionalRolesUseCase: i(),
        sendOtpUseCase: i(),
      ),
    );
  }
}
