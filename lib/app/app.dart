// coverage:ignore-file
import 'package:construculator/app/check_gate/check_gate.dart';
import 'package:construculator/app/check_gate/check_gate_bloc.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/analytics/analytics_navigator_observer.dart';
import 'package:construculator/libraries/analytics/current_screen_tracker.dart';
import 'package:construculator/libraries/analytics/domain/repositories/analytics_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class AppWidget extends StatefulWidget {
  const AppWidget({
    required this.analyticsRepository,
    required this.currentScreenTracker,
    required this.createCheckGateBloc,
    super.key,
  });

  /// Used to wire [AnalyticsNavigatorObserver] for screen-view tracking.
  final AnalyticsRepository analyticsRepository;
  final CurrentScreenTracker currentScreenTracker;

  /// Creates the bloc behind the loading screen that covers the app while the
  /// sign-in check runs.
  final CheckGateBloc Function() createCheckGateBloc;

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
        currentScreenTracker: widget.currentScreenTracker,
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
      builder: (context, child) => BlocProvider<CheckGateBloc>(
        create: (_) =>
            widget.createCheckGateBloc()..add(const CheckGateStarted()),
        child: CheckGate(child: child),
      ),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
