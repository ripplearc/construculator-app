import 'package:construculator/features/members/presentation/widgets/member_invitation_widget.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/screenshot/font_loader.dart';

void main() {
  const title = 'Invite people for Material of building';
  const subtitle = 'You can invite other people by email';

  Widget buildWidget(ThemeData theme) {
    return MaterialApp(
      theme: theme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: MemberInvitationWidget(
          title: title,
          subtitle: subtitle,
          onInvite: (_) {},
        ),
      ),
    );
  }

  group('MemberInvitationWidget – accessibility', () {
    testWidgets('invite button meets tap-target and label guidelines in both themes', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(createTestTheme()));
      await tester.pumpAndSettle();
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        buildWidget,
        find.byKey(const Key('member_invitation_invite_button')),
      );
    });

    testWidgets('remove chip button meets tap-target and label guidelines in both themes', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(createTestTheme()));
      await tester.pumpAndSettle();
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        buildWidget,
        find.byKey(const Key('remove_chip_a@b.com')),
        setupAfterPump: (t) async {
          await t.enterText(
            find.byKey(const Key('member_invitation_email_input')),
            'a@b.com',
          );
          await t.testTextInput.receiveAction(TextInputAction.done);
          await t.pump();
        },
      );
    });
  });
}
