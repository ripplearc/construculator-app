import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/members/presentation/pages/members_page.dart';
import 'package:flutter_modular/flutter_modular.dart';

class MembersModule extends Module {
  final AppBootstrap appBootstrap;

  MembersModule(this.appBootstrap);

  @override
  void routes(RouteManager r) {
    r.child('/', child: (_) => const MembersPage());
  }
}
