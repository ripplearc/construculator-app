import 'package:construculator/features/members/presentation/pages/members_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../utils/screenshot/font_loader.dart';

void main() {
  testWidgets('renders members placeholder', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: createTestTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MembersPage(),
      ),
    );

    expect(find.text('Members'), findsOneWidget);
  });
}
