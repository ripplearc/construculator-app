import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

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
