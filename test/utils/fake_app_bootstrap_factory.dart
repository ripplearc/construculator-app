import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/config/interfaces/config.dart';
import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';

/// Factory for creating test AppBootstrap instances with fake dependencies.
///
/// Provides convenient methods to create AppBootstrap with sensible test
/// defaults, reducing boilerplate in test setup.
class FakeAppBootstrapFactory {
  /// Creates an AppBootstrap with fake dependencies for testing.
  ///
  /// All parameters are optional:
  /// - [supabaseWrapper]: Provide a specific FakeSupabaseWrapper to control
  ///   database state and assertions
  /// - [clock]: Provide a Clock to control time in tests. Note: [clock] is only
  ///   used when [supabaseWrapper] is omitted. If you supply your own
  ///   [supabaseWrapper], wire the clock into it directly.
  /// - [config]: Provide custom app configuration for the test
  /// - [envLoader]: Provide custom environment loading behavior
  ///
  /// When parameters are omitted, sensible test defaults are provided.
  ///
  /// Example:
  /// ```dart
  /// // Basic usage with all defaults
  /// final bootstrap = FakeAppBootstrapFactory.create();
  ///
  /// // With custom clock for time-dependent tests
  /// final clock = FakeClockImpl(DateTime(2025, 1, 1));
  /// final bootstrap = FakeAppBootstrapFactory.create(clock: clock);
  /// ```
  static AppBootstrap create({
    FakeSupabaseWrapper? supabaseWrapper,
    Clock? clock,
    Config? config,
    EnvLoader? envLoader,
  }) {
    final fakeClock = clock ?? FakeClockImpl();
    return AppBootstrap(
      supabaseWrapper: supabaseWrapper ?? FakeSupabaseWrapper(clock: fakeClock),
      config: config ?? FakeAppConfig(),
      envLoader: envLoader ?? FakeEnvLoader(),
    );
  }
}
