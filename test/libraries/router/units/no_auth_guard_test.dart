import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_manager.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/router/guards/no_auth_guard.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoAuthGuardTestModule extends Module {
  final FakeAuthManager _authManager;

  _NoAuthGuardTestModule(this._authManager);

  @override
  void binds(Injector i) {
    i.addLazySingleton<AuthManager>(() => _authManager);
  }

  ModularRoute emptyRoute() => ParallelRoute.empty();
}

void main() {
  late FakeAuthManager authManager;
  late FakeClockImpl clock;
  late _NoAuthGuardTestModule testModule;

  setUp(() {
    clock = FakeClockImpl();
    final fakeSupabase = FakeSupabaseWrapper(clock: clock);
    final authNotifier = FakeAuthNotifier();
    final authRepository = FakeAuthRepository(clock: clock);
    authManager = FakeAuthManager(
      authNotifier: authNotifier,
      authRepository: authRepository,
      wrapper: fakeSupabase,
      clock: clock,
    );
    testModule = _NoAuthGuardTestModule(authManager);
    Modular.init(testModule);
  });

  tearDown(() {
    Modular.destroy();
  });

  group('NoAuthGuard', () {
    test('canActivate returns true when user is not authenticated', () async {
      final guard = NoAuthGuard();

      final result = await guard.canActivate('/', testModule.emptyRoute());

      expect(result, isTrue);
    });

    test('canActivate returns false when user is authenticated', () async {
      authManager.setCurrentCredential(
        UserCredential(
          id: 'user-1',
          email: 'user@example.com',
          metadata: const {},
          createdAt: clock.now(),
        ),
      );
      final guard = NoAuthGuard();

      final result = await guard.canActivate('/', testModule.emptyRoute());

      expect(result, isFalse);
    });
  });
}
