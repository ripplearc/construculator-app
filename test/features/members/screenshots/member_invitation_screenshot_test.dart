import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/features/members/presentation/widgets/member_invitation_widget.dart';
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
          backgroundColor: const Color(0xFF003A54),
          body: Align(
            alignment: Alignment.bottomCenter,
            child: widget,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const goldenDir = 'goldens/member_invitation';

  group('MemberInvitationWidget Screenshot Tests', () {
    testWidgets('renders empty state', (tester) async {
      await pumpWidget(
        tester,
        const MemberInvitationWidget(
          title: 'Invite people for Material of building',
          subtitle: 'You can invite other people by email',
        ),
      );

      await expectLater(
        find.byType(MemberInvitationWidget),
        matchesGoldenFile('$goldenDir/${size.width}x${size.height}/member_invitation_empty.png'),
      );
    });

    testWidgets('renders with one email chip', (tester) async {
      final widget = MemberInvitationWidget(
        title: 'Invite people for Material of building',
        subtitle: 'You can invite other people by email',
        onInvite: (_) {},
      );

      await pumpWidget(tester, widget);

      await tester.enterText(
        find.byKey(const Key('member_invitation_email_input')),
        'alice@example.com',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MemberInvitationWidget),
        matchesGoldenFile('$goldenDir/${size.width}x${size.height}/member_invitation_one_chip.png'),
      );
    });

    testWidgets('renders with multiple email chips', (tester) async {
      const multiSize = Size(390, 340);
      tester.view.physicalSize = multiSize;
      tester.view.devicePixelRatio = ratio;

      final widget = MemberInvitationWidget(
        title: 'Invite people for Material of building',
        subtitle: 'You can invite other people by email',
        onInvite: (_) {},
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            backgroundColor: const Color(0xFF003A54),
            body: Align(
              alignment: Alignment.bottomCenter,
              child: widget,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final email in ['alice@example.com', 'bob@example.com', 'carol@example.com']) {
        await tester.enterText(
          find.byKey(const Key('member_invitation_email_input')),
          email,
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
      }

      await expectLater(
        find.byType(MemberInvitationWidget),
        matchesGoldenFile('$goldenDir/${multiSize.width}x${multiSize.height}/member_invitation_multiple_chips.png'),
      );
    });

    testWidgets('renders error state for invalid email', (tester) async {
      await pumpWidget(
        tester,
        MemberInvitationWidget(
          title: 'Invite people for Material of building',
          subtitle: 'You can invite other people by email',
          onInvite: (_) {},
        ),
      );

      await tester.enterText(
        find.byKey(const Key('member_invitation_email_input')),
        'not-valid',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MemberInvitationWidget),
        matchesGoldenFile('$goldenDir/${size.width}x${size.height}/member_invitation_error.png'),
      );
    });
  });
}
