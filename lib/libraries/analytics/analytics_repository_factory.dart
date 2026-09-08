import 'package:construculator/libraries/analytics/current_screen_tracker.dart';
import 'package:construculator/libraries/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:construculator/libraries/analytics/data/repositories/no_op_analytics_repository.dart';
import 'package:construculator/libraries/analytics/domain/repositories/analytics_repository.dart';
import 'package:construculator/libraries/analytics/interfaces/posthog_wrapper.dart';
import 'package:construculator/libraries/config/env_constants.dart';
import 'package:construculator/libraries/config/interfaces/env_loader.dart';

/// Builds the [PosthogWrapper] backing [AnalyticsRepositoryImpl].
///
/// Deferred so the PostHog SDK is never touched when analytics is disabled.
typedef PosthogWrapperBuilder = PosthogWrapper Function();

/// Resolves the [AnalyticsRepository] used for the lifetime of the app.
///
/// Returns [NoOpAnalyticsRepository] unless `ANALYTICS_ENABLED` is exactly
/// `'true'`; otherwise builds an [AnalyticsRepositoryImpl] and initializes it
/// before handing it to the caller.
///
/// Split out of `main.dart` so the selection is unit-testable; it remains
/// composition-root code and must only be called from bootstrap.
Future<AnalyticsRepository> createAnalyticsRepository({
  required EnvLoader envLoader,
  required PosthogWrapperBuilder buildPosthogWrapper,
  required CurrentScreenTracker currentScreenTracker,
  required String appVersion,
}) async {
  if (envLoader.get(analyticsEnabledKey) != 'true') {
    return const NoOpAnalyticsRepository();
  }
  // The lint exempts main.dart as the composition root; this function is that
  // same bootstrap step, only extracted to make it testable.
  // ignore: no_direct_instantiation
  final repository = AnalyticsRepositoryImpl(
    envLoader: envLoader,
    posthogWrapper: buildPosthogWrapper(),
    currentScreenTracker: currentScreenTracker,
    appVersion: appVersion,
  );
  await repository.initialize();
  return repository;
}
