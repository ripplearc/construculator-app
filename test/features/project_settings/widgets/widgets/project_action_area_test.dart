import 'package:construculator/features/project_settings/presentation/widgets/project_action_area.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/screenshot/font_loader.dart';

void main() {
  Widget buildWidget() => MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: ProjectActionArea()),
      );

  group('ProjectActionArea', () {
    testWidgets('renders add description and invite member buttons', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('add_description_button')), findsOneWidget);
      expect(find.byKey(const Key('invite_member_button')), findsOneWidget);
    });
  });
}
