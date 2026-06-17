import 'package:construculator/features/members/presentation/pages/members_page.dart';
import 'package:construculator/features/members/data/member_invitation_provider_impl.dart';
import 'package:construculator/libraries/members/domain/member_invitation_provider.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Flutter Modular module for the Members feature.
class MembersModule extends Module {
  MembersModule();

  @override
  void exportedBinds(Injector i) {
    i.addSingleton<MemberInvitationProvider>(
      () => const MemberInvitationProviderImpl(),
    );
  }

  @override
  void routes(RouteManager r) {
    r.child('/', child: (_) => const MembersPage());
  }
}
