import 'package:construculator/libraries/config/interfaces/config.dart';
import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';

/// The application requires that certain services—such as the Supabase client—are fully
/// initialized before the [AppModule] is loaded. This is critical for features like
/// route guards and other components that depend on ready-to-use services.
///
/// ---
///
/// ### ❗ Why initialization can't happen inside the AppModule
///
/// While the `binds` method in a `Modular` module **can be marked as `async`**, this does **not**
/// cause Modular to `await` its completion. `Modular` expects `binds()` to be synchronous, and
/// will invoke it without waiting. This means:
///
/// - Any asynchronous initialization inside `binds()` or the module constructor will **not complete**
///   before routes are evaluated.
/// - Dependencies like the Supabase client—which may require reading environment variables,
///   setting up secure connections, or awaiting tokens—will still be initializing when Modular
///   begins handling routes or guards.
/// - This leads to race conditions, broken services, or route guards failing due to uninitialized state.
///
/// ---
///
/// ### ✅ The Solution: External Initialization
///
/// All async initialization must be done *outside* the module, typically in `main()` before calling `runApp()`.
/// Once initialized, these services are passed into the module using a dedicated wrapper class
/// named [AppBootstrap].
///
/// ---
///
/// ### Dependencies:
/// - [Config] — Manages environment selection and config loading
/// - [EnvLoader] — Loads `.env` or secret configuration
/// - [SupabaseWrapper] — Initializes and exposes the Supabase client
///
/// These are grouped into [AppBootstrap] and passed to the [AppModule].
///
/// ---
///
/// ### Example usage:
/// ```dart
/// final env = _getEnvironmentFromString(envName);
///
/// final envLoader = EnvLoaderImpl();
/// final config = AppConfigImpl(envLoader: envLoader);
/// await config.initialize(env);
///
/// final supabaseWrapper = SupabaseWrapperImpl(envLoader: envLoader);
/// await supabaseWrapper.initialize();
///
/// final bootstrap = AppBootstrap(
///   config: config,
///   envLoader: envLoader,
///   supabaseWrapper: supabaseWrapper,
/// );
///
/// runApp(ModularApp(
///   module: AppModule(bootstrap),
///   child: const AppWidget(),
/// ));
/// ```
///
/// ---
///
/// This guarantees all critical services are ready before any routing or dependency injection logic takes place.
class AppBootstrap {
  /// The environment loader, required by [Config] for initialization.
  final EnvLoader envLoader;

  /// The app config, required by supabase wrapper for initialization.
  final Config config;

  /// The supabase wrapper, has to be instantiated before passing to the app module.
  final SupabaseWrapper supabaseWrapper;

  AppBootstrap({
    required this.envLoader,
    required this.config,
    required this.supabaseWrapper,
  });
}