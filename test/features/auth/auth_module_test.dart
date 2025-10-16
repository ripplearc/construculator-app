import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/testing/fake_app_bootstrap.dart';
import 'package:construculator/features/auth/auth_module.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/modular/testing/fake_injector.dart';
import 'package:construculator/libraries/router/testing/fake_route_manager.dart';
import 'package:construculator/libraries/supabase/supabase_module.dart';
import 'package:construculator/libraries/time/clock_module.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppBootstrap fakeBootstrap;
  late AuthModule module;

  setUp(() {
    fakeBootstrap = FakeAppBootstrap();
    module = AuthModule(fakeBootstrap);
  });

  group('AuthModule', () {
    group('constructor', () {
      test('should create instance with appBootstrap', () {
        expect(module.appBootstrap, same(fakeBootstrap));
      });
    });

    group('imports', () {
      test('should contain required modules', () {
        final imports = module.imports;

        expect(imports, hasLength(3));
        expect(imports.any((m) => m is AuthLibraryModule), isTrue);
        expect(imports.any((m) => m is SupabaseModule), isTrue);
        expect(imports.any((m) => m is ClockModule), isTrue);
      });

      test('should pass appBootstrap to AuthLibraryModule', () {
        final imports = module.imports;

        final authLibraryModule = imports.whereType<AuthLibraryModule>().first;

        expect(authLibraryModule.appBootstrap, same(fakeBootstrap));
      });

      test('should pass appBootstrap to SupabaseModule', () {
        final imports = module.imports;

        final supabaseModule = imports.whereType<SupabaseModule>().first;

        expect(supabaseModule.appBootstrap, same(fakeBootstrap));
      });
    });

    group('routes', () {
      test('should register all auth routes', () {
        final fakeRouteManager = FakeRouteManager();

        module.routes(fakeRouteManager);

        expect(fakeRouteManager.addedRoutes.length, 6);
      });

      test('should register routes without throwing exceptions', () {
        final fakeRouteManager = FakeRouteManager();

        expect(() => module.routes(fakeRouteManager), returnsNormally);
      });
    });

    group('binds', () {
      test('should register dependencies without throwing exceptions', () {
        final fakeInjector = FakeInjector();

        expect(() => module.binds(fakeInjector), returnsNormally);
      });

      test('should call dependency registration methods', () {
        final fakeInjector = FakeInjector();

        module.binds(fakeInjector);

        expect(fakeInjector.addLazySingletonCalls, greaterThan(0));
        expect(fakeInjector.addCalls, greaterThan(0));
      });

      test('should execute use case factory functions', () {
        final fakeInjector = FakeInjector();

        module.binds(fakeInjector);

        expect(fakeInjector.executedUseCaseFactories, greaterThan(0));
        expect(fakeInjector.executedBlocFactories, greaterThan(0));
      });

      test('should register correct number of dependencies', () {
        final fakeInjector = FakeInjector();

        module.binds(fakeInjector);

        expect(fakeInjector.addLazySingletonCalls, 8);
        expect(fakeInjector.addCalls, 7);
        expect(fakeInjector.totalDependencies, 15);
      });

      test('should create specific use case instances', () {
        final fakeInjector = FakeInjector();

        module.binds(fakeInjector);

        expect(fakeInjector.createdUseCases, contains('ResetPasswordUseCase'));
        expect(
          fakeInjector.createdUseCases,
          contains('GetProfessionalRolesUseCase'),
        );
        expect(
          fakeInjector.createdUseCases,
          contains('CheckEmailAvailabilityUseCase'),
        );
        expect(fakeInjector.createdUseCases, contains('CreateAccountUseCase'));
        expect(fakeInjector.createdUseCases, contains('SendOtpUseCase'));
        expect(fakeInjector.createdUseCases, contains('VerifyOtpUseCase'));
        expect(fakeInjector.createdUseCases, contains('LoginUseCase'));
        expect(fakeInjector.createdUseCases, contains('SetNewPasswordUseCase'));
      });

      test('should create specific bloc instances', () {
        final fakeInjector = FakeInjector();

        module.binds(fakeInjector);

        expect(fakeInjector.createdBlocs, contains('RegisterWithEmailBloc'));
        expect(fakeInjector.createdBlocs, contains('OtpVerificationBloc'));
        expect(fakeInjector.createdBlocs, contains('CreateAccountBloc'));
        expect(fakeInjector.createdBlocs, contains('LoginWithEmailBloc'));
        expect(fakeInjector.createdBlocs, contains('EnterPasswordBloc'));
        expect(fakeInjector.createdBlocs, contains('ForgotPasswordBloc'));
        expect(fakeInjector.createdBlocs, contains('SetNewPasswordBloc'));
      });
    });

    group('internal methods', () {
      test('should execute _registerRoutes method', () {
        final fakeRouteManager = FakeRouteManager();

        module.routes(fakeRouteManager);

        expect(fakeRouteManager.addedRoutes.length, 6);
      });

      test('should execute _registerDependencies method', () {
        final fakeInjector = FakeInjector();

        module.binds(fakeInjector);

        expect(fakeInjector.addLazySingletonCalls, 8);
        expect(fakeInjector.addCalls, 7);
      });
    });
  });
}
