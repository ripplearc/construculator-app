import 'package:construculator/main.dart' as app;
import 'package:patrol/patrol.dart';

Future<void> startApp(PatrolIntegrationTester $) async {
  app.main();
  await $.pumpAndSettle(timeout: const Duration(seconds: 5));
}
