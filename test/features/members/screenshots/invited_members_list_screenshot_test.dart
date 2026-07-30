import 'package:construculator/features/members/presentation/widgets/invited_members_list.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/members/domain/invited_member.dart';
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

  Future<void> pumpWidget(
    WidgetTester tester,
    Widget widget, {
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (ctx) => Scaffold(
            backgroundColor: ctx.colorTheme.pageBackground,
            body: widget,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const goldenDir = 'goldens/member_invitation';

  group('InvitedMembersList Screenshot Tests - Light', () {
    testWidgets('renders list with two invited members', (tester) async {
      await pumpWidget(
        tester,
        const InvitedMembersList(
          members: [
            InvitedMember(email: 'alice@example.com', name: 'Alice Example'),
            InvitedMember(email: 'bob@example.com', name: 'Bob Example'),
          ],
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('$goldenDir/${size.width}x${size.height}/invited_members_list.png'),
      );
    });
  });

  group('InvitedMembersList Screenshot Tests - Dark', () {
    testWidgets('renders list with two invited members', (tester) async {
      await pumpWidget(
        tester,
        const InvitedMembersList(
          members: [
            InvitedMember(email: 'alice@example.com', name: 'Alice Example'),
            InvitedMember(email: 'bob@example.com', name: 'Bob Example'),
          ],
        ),
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('$goldenDir/${size.width}x${size.height}/invited_members_list_dark.png'),
      );
    });
  });
}
