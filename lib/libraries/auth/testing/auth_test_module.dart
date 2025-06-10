import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/interfaces/auth_service.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_service.dart';
import 'package:construculator/libraries/supabase/testing/supabase_test_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

class AutTestModule extends Module {
  @override
  List<Module> get imports => [SupabaseTestModule()];
  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<AuthRepository>(() => FakeAuthRepository());
    i.addLazySingleton<AuthNotifier>(() => FakeAuthNotifier());
    i.addLazySingleton<AuthService>(() => FakeAuthService(notifier: i()));
  }
}
