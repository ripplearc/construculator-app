import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/members/domain/invited_member.dart';
import 'package:construculator/libraries/members/presentation/widgets/invited_members_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  Future<void> pumpWidget(
    WidgetTester tester, {
    required List<InvitedMember> members,
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
            members: members,
            onRemove: onRemove,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('InvitedMembersList', () {
    testWidgets('renders a tile for each member showing name when available', (
      tester,
    ) async {
      await pumpWidget(
        tester,
        members: [
          const InvitedMember(email: 'alice@example.com', name: 'Alice Example'),
          const InvitedMember(email: 'bob@example.com'),
        ],
      );

      expect(find.byKey(const Key('invited_member_alice@example.com')), findsOneWidget);
      expect(find.byKey(const Key('invited_member_bob@example.com')), findsOneWidget);
      expect(find.text('Alice Example'), findsOneWidget);
      expect(find.text('bob@example.com'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('calls onRemove with member email when remove icon tapped', (
      tester,
    ) async {
      String? removed;

      await pumpWidget(
        tester,
        members: [const InvitedMember(email: 'alice@example.com', name: 'Alice')],
        onRemove: (email) => removed = email,
      );

      await tester.tap(find.byKey(const Key('remove_member_alice@example.com')));
      await tester.pump();

      expect(removed, 'alice@example.com');
    });

    testWidgets('does not show remove button when onRemove is null', (
      tester,
    ) async {
      await pumpWidget(
        tester,
        members: [const InvitedMember(email: 'alice@example.com')],
        onRemove: null,
      );

      expect(find.byKey(const Key('remove_member_alice@example.com')), findsNothing);
    });
  });
}
