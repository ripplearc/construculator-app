import 'package:construculator/features/project_settings/presentation/pages/project_detail_screen.dart';
import 'package:construculator/libraries/router/routes/project_settings_routes.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ProjectSettingsModule extends Module {
  @override
  void routes(RouteManager r) {
    r.child(viewProjectRoute, child: (_) => const ProjectDetailScreen());
  }
}
