import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/members/domain/invited_member.dart';
import 'package:construculator/features/members/presentation/widgets/invited_members_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  Future<void> pumpWidget(
    WidgetTester tester, {
    required List<InvitedMember> members,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: InvitedMembersList(members: members),
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

    testWidgets('falls back to email initial when name is not provided', (
      tester,
    ) async {
      await pumpWidget(
        tester,
        members: [const InvitedMember(email: 'charlie@example.com')],
      );

      expect(find.text('charlie@example.com'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('renders Contributor badge for each tile', (tester) async {
      await pumpWidget(
        tester,
        members: [const InvitedMember(email: 'alice@example.com', name: 'Alice')],
      );

      expect(find.text('Contributor'), findsOneWidget);
    });
  });
}
