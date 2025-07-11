import 'package:construculator/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:construculator/features/auth/data/datasources/auth_remote_data_source_impl.dart';
import 'package:construculator/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:construculator/features/auth/domain/repositories/auth_repository.dart';
import 'package:construculator/features/auth/domain/usecases/check_email_availability_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/create_account_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/get_professional_roles_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/send_otp_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/login_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/set_new_password_usecase.dart';
import 'package:construculator/features/auth/presentation/bloc/otp_verification_bloc/otp_verification_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/register_with_email_bloc/register_with_email_bloc.dart';
import 'package:construculator/features/auth/presentation/pages/register_with_email_page.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/app/module_param.dart';
import 'package:construculator/libraries/guards/no_auth_guard.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:construculator/libraries/supabase/supabase_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';

class AuthModule extends Module {
  final ModuleParam moduleParam;
  AuthModule(this.moduleParam);
  @override
  List<Module> get imports => [
    AuthLibraryModule(moduleParam),
    SupabaseModule(moduleParam),
  ];

  @override
  void routes(RouteManager r) {
    r.child(
      registerWithEmailRoute,
      guards: [NoAuthGuard()],
      child: (context) {
        final email = r.args.data ?? '';
        return MultiBlocProvider(
          providers: [
            BlocProvider<RegisterWithEmailBloc>(
              create:
                  (BuildContext context) =>
                      Modular.get<RegisterWithEmailBloc>(),
            ),
            BlocProvider<OtpVerificationBloc>(
              create:
                  (BuildContext context) => Modular.get<OtpVerificationBloc>(),
            ),
          ],
          child: RegisterWithEmailPage(email: email),
        );
      },
    );
  }

  @override
  void binds(Injector i) {
    i.addSingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(supabaseWrapper: i()),
    );
    i.addSingleton<AuthRepository>(() => AuthRepositoryImpl(remoteDataSource: i()));
    i.addSingleton<ResetPasswordUseCase>(() => ResetPasswordUseCase(i()));
    i.addSingleton<GetProfessionalRolesUseCase>(
      () => GetProfessionalRolesUseCase(i()),
    );
    i.addSingleton<CheckEmailAvailabilityUseCase>(
      () => CheckEmailAvailabilityUseCase(i()),
    );
    i.addSingleton<CreateAccountUseCase>(() => CreateAccountUseCase(i()));
    i.addSingleton<SendOtpUseCase>(() => SendOtpUseCase(i()));
    i.addSingleton<VerifyOtpUseCase>(() => VerifyOtpUseCase(i()));
    i.addSingleton<LoginUseCase>(() => LoginUseCase(i()));
    i.addSingleton<SetNewPasswordUseCase>(() => SetNewPasswordUseCase(i()));

    i.addSingleton<RegisterWithEmailBloc>(
      () => RegisterWithEmailBloc(
        checkEmailAvailabilityUseCase: i(),
        sendOtpUseCase: i(),
      ),
    );

    i.addSingleton<OtpVerificationBloc>(
      () => OtpVerificationBloc(
        verifyOtpUseCase: i(),
        sendOtpUseCase: i(),
      ),
    );
  }
}
