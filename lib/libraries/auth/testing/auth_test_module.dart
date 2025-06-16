import 'package:construculator/libraries/auth/auth_manager_impl.dart';
import 'package:construculator/libraries/auth/auth_notifier_impl.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/repositories/supabase_repository_impl.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/supabase/testing/supabase_test_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

class AuthTestModule extends Module {
  @override
  List<Module> get imports => [SupabaseTestModule()];
  @override
  void exportedBinds(Injector i) {
    i.add<AuthRepository>(
      () => FakeAuthRepository(),
      key: 'fakeAuthRepository',
    );
    i.add<AuthRepository>(
      () => SupabaseRepositoryImpl(supabaseWrapper: i()),
      key: 'authRepositoryWithFakeDep',
    );
    i.add<AuthNotifier>(
      () => FakeAuthNotifier(),
      key: 'fakeAuthNotifier',
    );
    i.add<AuthNotifier>(
      () => AuthNotifierImpl(),
      key: 'authNotifier',
    );
    i.add<AuthManager>(
      () => AuthManagerImpl(
        wrapper: i(),
        authRepository: i(),
        authNotifier: i(),
      ),
      key: 'authManagerWithFakeDep',
    );
  }
}
