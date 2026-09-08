import 'package:construculator/features/members/presentation/widgets/invited_members_list.dart';
import 'package:construculator/features/members/presentation/widgets/member_invitation_widget.dart';
import 'package:construculator/features/members/testing/fake_member_invitation_provider.dart';
import 'package:construculator/libraries/members/domain/invited_member.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeMemberInvitationProvider', () {
    const provider = FakeMemberInvitationProvider();

    group('buildMemberInvitationWidget', () {
      test('returns a MemberInvitationWidget with the supplied arguments', () {
        void onInvite(List<String> emails) {}

        final widget = provider.buildMemberInvitationWidget(
          title: 'Invite people',
          subtitle: 'Enter emails below',
          onInvite: onInvite,
        );

        expect(widget, isA<MemberInvitationWidget>());
        final invitation = widget as MemberInvitationWidget;
        expect(invitation.title, 'Invite people');
        expect(invitation.subtitle, 'Enter emails below');
        expect(invitation.onInvite, same(onInvite));
      });

      test('passes through a null onInvite', () {
        final widget = provider.buildMemberInvitationWidget(
          title: 'Invite people',
          subtitle: 'Enter emails below',
        );

        expect(widget, isA<MemberInvitationWidget>());
        expect((widget as MemberInvitationWidget).onInvite, isNull);
      });
    });

    group('buildInvitedMembersList', () {
      test('returns an InvitedMembersList with the supplied members', () {
        const members = [
          InvitedMember(email: 'alice@example.com', name: 'Alice'),
          InvitedMember(email: 'bob@example.com'),
        ];

        final widget = provider.buildInvitedMembersList(members: members);

        expect(widget, isA<InvitedMembersList>());
        expect((widget as InvitedMembersList).members, same(members));
      });
    });
  });
}
