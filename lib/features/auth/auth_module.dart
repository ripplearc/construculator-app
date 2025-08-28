import 'package:construculator/features/auth/domain/usecases/check_email_availability_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/create_account_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/get_professional_roles_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/send_otp_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/login_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/set_new_password_usecase.dart';
import 'package:construculator/features/auth/presentation/bloc/create_account_bloc/create_account_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/enter_password_bloc/enter_password_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/forgot_password_bloc/forgot_password_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/login_with_email_bloc/login_with_email_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/otp_verification_bloc/otp_verification_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/register_with_email_bloc/register_with_email_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/set_new_password_bloc/set_new_password_bloc.dart';
import 'package:construculator/features/auth/presentation/pages/create_account_page.dart';
import 'package:construculator/features/auth/presentation/pages/enter_password_page.dart';
import 'package:construculator/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:construculator/features/auth/presentation/pages/login_with_email_page.dart';
import 'package:construculator/features/auth/presentation/pages/register_with_email_page.dart';
import 'package:construculator/features/auth/presentation/pages/set_new_password_page.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/time/clock_module.dart';
import 'package:construculator/libraries/router/guards/no_auth_guard.dart';
import 'package:construculator/libraries/router/guards/auth_guard.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:construculator/libraries/supabase/supabase_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';

class AuthModule extends Module {
  final AppBootstrap appBootstrap;
  AuthModule(this.appBootstrap);
  @override
  List<Module> get imports => [
    AuthLibraryModule(appBootstrap),
    SupabaseModule(appBootstrap),
    ClockModule(),
  ];

  @override
  void routes(RouteManager r) => _registerRoutes(r);

  @override
  void binds(Injector i) => _registerDependencies(i);
}
void _registerRoutes(RouteManager r) {
  r.child(
    registerWithEmailRoute,
    guards: [NoAuthGuard()],
    child: (context) {
      final email = r.args.data ?? '';
      return MultiBlocProvider(
        providers: [
          BlocProvider<RegisterWithEmailBloc>(
            create: (BuildContext context) =>
                Modular.get<RegisterWithEmailBloc>(),
          ),
          BlocProvider<OtpVerificationBloc>(
            create: (BuildContext context) =>
                Modular.get<OtpVerificationBloc>(),
          ),
        ],
        child: RegisterWithEmailPage(email: email),
      );
    },
  );
  r.child(
    createAccountRoute,
    guards: [AuthGuard()],
    child: (context) => MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => Modular.get<CreateAccountBloc>()),
        BlocProvider<OtpVerificationBloc>(
          create: (BuildContext context) => Modular.get<OtpVerificationBloc>(),
        ),
      ],
      child: CreateAccountPage(email: r.args.data as String),
    ),
  );
  r.child(
    loginWithEmailRoute,
    guards: [NoAuthGuard()],
    child: (context) {
      final email = r.args.data ?? '';
      return BlocProvider(
        create: (context) => Modular.get<LoginWithEmailBloc>(),
        child: LoginWithEmailPage(email: email),
      );
    },
  );
  r.child(
    enterPasswordRoute,
    guards: [NoAuthGuard()],
    child: (context) => BlocProvider(
      create: (context) => Modular.get<EnterPasswordBloc>(),
      child: EnterPasswordPage(email: r.args.data as String),
    ),
  );
  r.child(
    forgotPasswordRoute,
    guards: [NoAuthGuard()],
    child: (context) => MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => Modular.get<ForgotPasswordBloc>()),
        BlocProvider(create: (context) => Modular.get<OtpVerificationBloc>()),
      ],
      child: ForgotPasswordPage(),
    ),
  );
  r.child(
    setNewPasswordRoute,
    guards: [AuthGuard()],
    child: (context) {
      final email = r.args.data ?? '';
      return BlocProvider(
        create: (context) => Modular.get<SetNewPasswordBloc>(),
        child: SetNewPasswordPage(email: email),
      );
    },
  );
}

void _registerDependencies(Injector i) {
  i.addLazySingleton<ResetPasswordUseCase>(() => ResetPasswordUseCase(i()));
  i.addLazySingleton<GetProfessionalRolesUseCase>(
    () => GetProfessionalRolesUseCase(i()),
  );
  i.addLazySingleton<CheckEmailAvailabilityUseCase>(
    () => CheckEmailAvailabilityUseCase(i()),
  );
  i.addLazySingleton<CreateAccountUseCase>(() => CreateAccountUseCase(i(), i()));
  i.addLazySingleton<SendOtpUseCase>(() => SendOtpUseCase(i()));
  i.addLazySingleton<VerifyOtpUseCase>(() => VerifyOtpUseCase(i()));
  i.addLazySingleton<LoginUseCase>(() => LoginUseCase(i()));
  i.addLazySingleton<SetNewPasswordUseCase>(() => SetNewPasswordUseCase(i()));

  i.add<RegisterWithEmailBloc>(
    () => RegisterWithEmailBloc(
      checkEmailAvailabilityUseCase: i(),
      sendOtpUseCase: i(),
    ),
  );

  i.add<OtpVerificationBloc>(
    () => OtpVerificationBloc(verifyOtpUseCase: i(), sendOtpUseCase: i()),
  );

  i.add<CreateAccountBloc>(
    () => CreateAccountBloc(
      createAccountUseCase: i(),
      getProfessionalRolesUseCase: i(),
      sendOtpUseCase: i(),
    ),
  );
  i.add<LoginWithEmailBloc>(
    () => LoginWithEmailBloc(checkEmailAvailabilityUseCase: i()),
  );
  i.add<EnterPasswordBloc>(() => EnterPasswordBloc(loginUseCase: i()));
  i.add<ForgotPasswordBloc>(
    () => ForgotPasswordBloc(resetPasswordUseCase: i()),
  );
  i.add<SetNewPasswordBloc>(
    () => SetNewPasswordBloc(setNewPasswordUseCase: i()),
  );
}
