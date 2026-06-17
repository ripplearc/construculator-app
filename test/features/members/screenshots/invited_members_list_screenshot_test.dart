import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/members/presentation/widgets/invited_members_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 270);
  const ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFonts();
  });

  Future<void> pumpWidget(WidgetTester tester, Widget widget) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = ratio;

    await tester.pumpWidget(
      MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: widget,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const goldenDir = 'goldens/member_invitation';

  group('InvitedMembersList Screenshot Tests', () {
    testWidgets('renders list with two invited members', (tester) async {
      await pumpWidget(
        tester,
        InvitedMembersList(
          emails: ['alice@example.com', 'bob@example.com'],
          onRemove: (_) {},
        ),
      );

      await expectLater(
        find.byType(InvitedMembersList),
        matchesGoldenFile('$goldenDir/${size.width}x${size.height}/invited_members_list.png'),
      );
    });
  });
}
