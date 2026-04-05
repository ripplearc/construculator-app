import 'package:construculator/features/calculations/presentation/pages/calculations_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../utils/screenshot/font_loader.dart';

void main() {
  testWidgets('renders calculations placeholder', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: createTestTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CalculationsPage(),
      ),
    );

    expect(find.text('Calculations'), findsOneWidget);
  });
}
