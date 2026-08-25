import 'package:construculator/features/auth/auth_module.dart';
import 'package:construculator/features/auth/presentation/bloc/create_account_bloc/create_account_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/enter_password_bloc/enter_password_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/forgot_password_bloc/forgot_password_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/login_with_email_bloc/login_with_email_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/otp_verification_bloc/otp_verification_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/register_with_email_bloc/register_with_email_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/set_new_password_bloc/set_new_password_bloc.dart';
import 'package:construculator/libraries/consent/domain/repositories/consent_repository.dart';
import 'package:construculator/libraries/consent/domain/usecases/check_consent_status_usecase.dart';
import 'package:construculator/libraries/consent/domain/usecases/record_consent_usecase.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  group('AuthModule', () {
    setUp(() {
      Modular.init(AuthModule(FakeAppBootstrapFactory.create()));
    });

    tearDown(Modular.destroy);

    // #551 N5: AuthTestModule hand-registers the consent binds that signup
    // now depends on, mirroring this module's wiring rather than exercising
    // it. That leaves the real graph unproven -- a mis-targeted i(), a
    // missing import, or a bind registered against the wrong type would
    // survive every bloc test and only fail when a user first opened the
    // signup page. This constructs the real module instead.
    test('CreateAccountBloc resolves with its consent dependencies', () {
      final bloc = Modular.get<CreateAccountBloc>();

      expect(bloc, isNotNull);
      // Resolved independently as well, so a failure names the missing bind
      // rather than surfacing as an opaque CreateAccountBloc failure.
      expect(Modular.get<CheckConsentStatusUseCase>(), isNotNull);
      expect(Modular.get<RecordConsentUseCase>(), isNotNull);

      bloc.close();
      Modular.get<ConsentRepository>().dispose();
    });

    test('every auth bloc bind resolves', () {
      // The consent import added to this module brings a second module graph
      // in with it; a clash there would break binds that have nothing to do
      // with consent, so the rest of the module is asserted too.
      final blocs = [
        Modular.get<RegisterWithEmailBloc>(),
        Modular.get<OtpVerificationBloc>(),
        Modular.get<LoginWithEmailBloc>(),
        Modular.get<EnterPasswordBloc>(),
        Modular.get<ForgotPasswordBloc>(),
        Modular.get<SetNewPasswordBloc>(),
      ];

      for (final bloc in blocs) {
        expect(bloc, isNotNull);
        bloc.close();
      }

      Modular.get<ConsentRepository>().dispose();
    });
  });
}
