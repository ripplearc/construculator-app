import 'package:construculator/features/app_header/presentation/widgets/header_row.dart';
import 'package:construculator/features/app_header/presentation/widgets/title_search_app_bar.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/presentation/project_ui_provider.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/global_search_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Feature module that owns the app shell's header and all of its
/// business-logic wiring, keeping `ShellModule` a pure navigation
/// coordinator.
class AppHeaderModule extends Module {
  @override
  void binds(Injector i) {
    // TODO: [CA-731] Register NotificationBloc when NotificationModule is ready.
    // https://ripplearc.youtrack.cloud/issue/CA-731
    // TODO: [CA-732] Register ProfileBloc when ProfileModule is ready.
    // https://ripplearc.youtrack.cloud/issue/CA-732
  }

  /// Builds the shell's app bar for the current header context.
  ///
  /// When a project is selected, delegates to the project header provided by
  /// [ProjectUIProvider]. Otherwise shows the [HeaderRow] home header on the
  /// home tab ([isHomeTab] true) or a [TitleSearchAppBar] on other tabs, with
  /// search navigation wired to the global search route in both cases.
  static PreferredSizeWidget buildHeader({required bool isHomeTab}) {
    final projectId = Modular.get<CurrentProjectNotifier>().currentProjectId;
    if (projectId != null && projectId.isNotEmpty) {
      return Modular.get<ProjectUIProvider>().buildProjectHeaderAppbar();
    }

    final router = Modular.get<AppRouter>();
    void onSearchTap() => router.pushNamed(fullGlobalSearchRoute);

    if (isHomeTab) {
      return HeaderRow(
        onSearchTap: onSearchTap,
        // TODO: [CA-731] Wire NotificationBloc when NotificationModule is ready.
        // https://ripplearc.youtrack.cloud/issue/CA-731
        // TODO: [CA-732] Wire ProfileBloc when ProfileModule is ready.
        // https://ripplearc.youtrack.cloud/issue/CA-732
      );
    }
    return TitleSearchAppBar(onSearchTap: onSearchTap);
  }
}
