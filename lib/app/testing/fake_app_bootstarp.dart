import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/config/interfaces/config.dart';
import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';

/// A fake implementation of [AppBootstrap] for testing purposes.
///
/// This fake provides mock implementations of all required dependencies:
/// - [EnvLoader]
/// - [Config]
/// - [SupabaseWrapper]
///
/// Use this in tests where you need an [AppBootstrap] instance but don't
/// need the actual functionality of the bootstrap dependencies.
class FakeAppBootstrap implements AppBootstrap {
  @override
  EnvLoader get envLoader => FakeEnvLoader();

  @override
  Config get config => FakeAppConfig();

  @override
  SupabaseWrapper get supabaseWrapper =>
      FakeSupabaseWrapper(clock: FakeClockImpl());
}
