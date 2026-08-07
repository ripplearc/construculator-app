// coverage:ignore-file
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/analytics/analytics_navigator_observer.dart';
import 'package:construculator/libraries/analytics/domain/repositories/analytics_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class AppWidget extends StatefulWidget {
  const AppWidget({required this.analyticsRepository, super.key});

  final AnalyticsRepository analyticsRepository;

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> {
  @override
  void initState() {
    super.initState();
    Modular.routerDelegate.setObservers([
      SentryNavigatorObserver(),
      AnalyticsNavigatorObserver(
        analyticsRepository: widget.analyticsRepository,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Construculator',
      locale: const Locale('en'),
      themeMode: ThemeMode.system,
      darkTheme: CoreTheme.dark(),
      theme: CoreTheme.light(),
      routerConfig: Modular.routerConfig,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
