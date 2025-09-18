import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/router/testing/router_test_module.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:flutter_modular/flutter_modular.dart';

class EstimationTestModule extends Module {
  @override
  List<Module> get imports => [
    AuthLibraryModule(
      AppBootstrap(
        envLoader: FakeEnvLoader(),
        config: FakeAppConfig(),
        supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
      ),
    ),
    RouterTestModule(),
  ];

  @override
  void binds(Injector i) {}
}
