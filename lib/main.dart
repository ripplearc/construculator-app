import 'package:construculator/app/app.dart';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/app_module.dart';
import 'package:construculator/libraries/analytics/analytics_repository_factory.dart';
import 'package:construculator/libraries/analytics/current_screen_tracker.dart';
import 'package:construculator/libraries/analytics/data/repositories/feature_flag_repository_impl.dart';
import 'package:construculator/libraries/analytics/data/repositories/no_op_feature_flag_repository.dart';
import 'package:construculator/libraries/analytics/domain/repositories/feature_flag_repository.dart';
import 'package:construculator/libraries/analytics/posthog_sdk_impl.dart';
import 'package:construculator/libraries/analytics/posthog_wrapper_impl.dart';
import 'package:construculator/libraries/config/app_config_impl.dart';
import 'package:construculator/libraries/config/env_constants.dart';
import 'package:construculator/libraries/config/env_loader_impl.dart';
import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/powersync/data/open_powersync_database.dart';
import 'package:construculator/libraries/sentry/sentry_sdk_impl.dart';
import 'package:construculator/libraries/sentry/sentry_wrapper_impl.dart';
import 'package:construculator/libraries/supabase/supabase_wrapper_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  // Must use Sentry's binding (not WidgetsFlutterBinding) so its frame
  // tracking integration can install before SentryFlutter.init runs.
  SentryWidgetsFlutterBinding.ensureInitialized();

  final appBootstrap = await _initializeApp();

  AppLogger.setSentryWrapper(appBootstrap.sentryWrapper);
  AppLogger.setConfig(appBootstrap.config);

  await appBootstrap.sentryWrapper.initialize(
    () => runApp(
      ModularApp(
        module: AppModule(appBootstrap),
        child: AppWidget(
          analyticsRepository: appBootstrap.analyticsRepository,
          currentScreenTracker: appBootstrap.currentScreenTracker,
        ),
      ),
    ),
  );
}

Future<AppBootstrap> _initializeApp() async {
  final String envName = const String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: devEnv,
  );

  final Environment env = _getEnvironmentFromString(envName);
  final envLoader = EnvLoaderImpl();
  final config = AppConfigImpl(envLoader: envLoader);
  await config.initialize(env);
  final wrapper = SupabaseWrapperImpl(envLoader: envLoader);
  await wrapper.initialize();
  final sentryWrapper = SentryWrapperImpl(
    envLoader: envLoader,
    config: config,
    sentrySdk: SentrySdkImpl(),
  );
  final powerSyncDatabase = await openPowerSyncDatabase();
  final currentScreenTracker = CurrentScreenTracker();
  final packageInfo = await PackageInfo.fromPlatform();
  final analyticsRepository = await createAnalyticsRepository(
    envLoader: envLoader,
    buildPosthogWrapper: () => PosthogWrapperImpl(posthogSdk: PosthogSdkImpl()),
    currentScreenTracker: currentScreenTracker,
    appVersion: packageInfo.version,
  );
  final featureFlagRepository = await _initializeFeatureFlagRepository(
    envLoader,
  );
  return AppBootstrap(
    config: config,
    envLoader: envLoader,
    supabaseWrapper: wrapper,
    sentryWrapper: sentryWrapper,
    analyticsRepository: analyticsRepository,
    powerSyncDatabase: powerSyncDatabase,
    featureFlagRepository: featureFlagRepository,
    currentScreenTracker: currentScreenTracker,
  );
}

Future<FeatureFlagRepository> _initializeFeatureFlagRepository(
  EnvLoader envLoader,
) async {
  if (envLoader.get(analyticsEnabledKey) != 'true') {
    return const NoOpFeatureFlagRepository();
  }
  // TODO: [CA-942] Once AnalyticsRepositoryImpl's bootstrap lands, share this
  // PosthogWrapperImpl instance with it instead of each constructing its own —
  // see docs/Logging/Posthog-Integration.md.
  final posthogWrapper = PosthogWrapperImpl(posthogSdk: PosthogSdkImpl());
  final apiKey = envLoader.get(posthogApiKeyKey) ?? '';
  if (apiKey.isEmpty) {
    final logger = AppLogger().tag('main');
    logger.warning(
      'ANALYTICS_ENABLED=true but POSTHOG_API_KEY is empty — feature flags '
      'will silently read as off.',
    );
  }
  await posthogWrapper.initialize(
    apiKey: apiKey,
    host: envLoader.get(posthogHostKey) ?? '',
    debug: envLoader.get(posthogDebugKey) == 'true',
  );
  final repository = FeatureFlagRepositoryImpl(posthogWrapper: posthogWrapper);
  await repository.reloadFeatureFlags();
  return repository;
}

Environment _getEnvironmentFromString(String? envName) {
  switch (envName?.toLowerCase()) {
    case prodEnv:
      return Environment.prod;
    case qaEnv:
      return Environment.qa;
    case devEnv:
      return Environment.dev;
    default:
      return Environment.dev;
  }
}
