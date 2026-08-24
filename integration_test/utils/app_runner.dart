import 'package:construculator/main.dart' as app;
import 'package:patrol/patrol.dart';

/// Boots the real app and renders its first frame.
///
/// `app.main()` is awaited deliberately: it loads environment config,
/// initialises the Supabase wrapper and initialises Sentry before calling
/// `runApp`. Without the await, a bootstrap failure surfaces as an unhandled
/// asynchronous error and the test instead fails much later on a missing
/// widget, which hides the real cause.
///
/// Only a single [pump] follows: the app keeps frames scheduled after boot
/// (PowerSync connects and retries in the background), so waiting for the
/// frame scheduler to go quiet throws `pumpAndSettle timed out`. Patrol's
/// finders already pump while they wait for the widget they act on.
Future<void> startApp(PatrolIntegrationTester $) async {
  await app.main();
  await $.pump();
}
