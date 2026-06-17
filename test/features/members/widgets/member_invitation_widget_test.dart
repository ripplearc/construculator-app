import 'package:construculator/libraries/members/presentation/widgets/invited_members_list.dart';
import 'package:construculator/libraries/members/presentation/widgets/member_invitation_widget.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  const title = 'Invite people for Material of building';
  const subtitle = 'You can invite other people by email';

  Future<void> pumpInvitationWidget(
    WidgetTester tester, {
    void Function(List<String>)? onInvite,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MemberInvitationWidget(
            title: title,
            subtitle: subtitle,
            onInvite: onInvite,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> pumpInvitedMembersList(
    WidgetTester tester, {
    required List<String> emails,
    void Function(String)? onRemove,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: InvitedMembersList(
            emails: emails,
            onRemove: onRemove,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('MemberInvitationWidget', () {
    group('Rendering', () {
      testWidgets('renders title, subtitle, email input, and invite button', (
        tester,
      ) async {
        await pumpInvitationWidget(tester);

        expect(find.text(title), findsOneWidget);
        expect(find.text(subtitle), findsOneWidget);
        expect(find.byKey(const Key('member_invitation_email_input')), findsOneWidget);
        expect(find.byKey(const Key('member_invitation_invite_button')), findsOneWidget);
      });

      testWidgets('invite button is disabled when no emails have been added', (
        tester,
      ) async {
        await pumpInvitationWidget(tester);

        final button = tester.widget<CoreButton>(
          find.byKey(const Key('member_invitation_invite_button')),
        );
        expect(button.isDisabled, isTrue);
      });

      testWidgets('invite button is enabled after an email is added', (
        tester,
      ) async {
        await pumpInvitationWidget(tester);

        await tester.enterText(
          find.byKey(const Key('member_invitation_email_input')),
          'test@example.com',
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        final button = tester.widget<CoreButton>(
          find.byKey(const Key('member_invitation_invite_button')),
        );
        expect(button.isDisabled, isFalse);
      });
    });

    group('Validation', () {
      testWidgets('shows invalid email error for malformed email', (
        tester,
      ) async {
        await pumpInvitationWidget(tester);

        await tester.enterText(
          find.byKey(const Key('member_invitation_email_input')),
          'not-an-email',
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        expect(find.text('Please enter a valid email address'), findsOneWidget);
      });

      testWidgets('shows duplicate error when same email is added twice', (
        tester,
      ) async {
        await pumpInvitationWidget(tester);

        await tester.enterText(
          find.byKey(const Key('member_invitation_email_input')),
          'dup@example.com',
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        await tester.enterText(
          find.byKey(const Key('member_invitation_email_input')),
          'dup@example.com',
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        expect(find.text('Email exists'), findsOneWidget);
      });

      testWidgets('error is cleared after a successful add', (tester) async {
        await pumpInvitationWidget(tester);

        await tester.enterText(
          find.byKey(const Key('member_invitation_email_input')),
          'bad',
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        expect(find.text('Please enter a valid email address'), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('member_invitation_email_input')),
          'good@example.com',
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        expect(find.text('Please enter a valid email address'), findsNothing);
      });
    });

    group('Adding members', () {
      testWidgets('shows email chip and clears input after valid email added', (
        tester,
      ) async {
        await pumpInvitationWidget(tester);

        await tester.enterText(
          find.byKey(const Key('member_invitation_email_input')),
          'alice@example.com',
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        expect(find.byKey(const Key('email_chip_alice@example.com')), findsOneWidget);

        final input = tester.widget<TextField>(
          find.byKey(const Key('member_invitation_email_input')),
        );
        expect(input.controller!.text, isEmpty);
      });

      testWidgets('calls onInvite with the current email list', (
        tester,
      ) async {
        List<String>? captured;

        await pumpInvitationWidget(
          tester,
          onInvite: (emails) => captured = emails,
        );

        await tester.enterText(
          find.byKey(const Key('member_invitation_email_input')),
          'alice@example.com',
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        await tester.tap(find.byKey(const Key('member_invitation_invite_button')));
        await tester.pump();

        expect(captured, equals(['alice@example.com']));
      });
    });

    group('Removing members', () {
      testWidgets('removes chip when close icon is tapped', (tester) async {
        await pumpInvitationWidget(tester);

        await tester.enterText(
          find.byKey(const Key('member_invitation_email_input')),
          'bob@example.com',
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        expect(find.byKey(const Key('email_chip_bob@example.com')), findsOneWidget);

        await tester.tap(find.byKey(const Key('remove_chip_bob@example.com')));
        await tester.pump();

        expect(find.byKey(const Key('email_chip_bob@example.com')), findsNothing);
      });
    });
  });

  group('InvitedMembersList', () {
    testWidgets('renders a tile for each email with avatar initial', (
      tester,
    ) async {
      await pumpInvitedMembersList(
        tester,
        emails: ['alice@example.com', 'bob@example.com'],
      );

      expect(find.byKey(const Key('invited_member_alice@example.com')), findsOneWidget);
      expect(find.byKey(const Key('invited_member_bob@example.com')), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('calls onRemove with correct email when remove icon tapped', (
      tester,
    ) async {
      String? removed;

      await pumpInvitedMembersList(
        tester,
        emails: ['alice@example.com'],
        onRemove: (email) => removed = email,
      );

      await tester.tap(find.byKey(const Key('remove_member_alice@example.com')));
      await tester.pump();

      expect(removed, 'alice@example.com');
    });

    testWidgets('does not show remove button when onRemove is null', (
      tester,
    ) async {
      await pumpInvitedMembersList(
        tester,
        emails: ['alice@example.com'],
        onRemove: null,
      );

      expect(find.byKey(const Key('remove_member_alice@example.com')), findsNothing);
    });
  });
}
