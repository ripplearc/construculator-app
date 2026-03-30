import 'package:construculator/features/members/presentation/pages/members_page.dart';
import 'package:flutter_modular/flutter_modular.dart';

class MembersModule extends Module {
  MembersModule();

  @override
  void routes(RouteManager r) {
    r.child('/', child: (_) => const MembersPage());
  }
}
