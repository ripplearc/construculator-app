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
  /// When [currentProjectNotifier] reports a selected project, delegates to
  /// the project header provided by [projectUIProvider]. Otherwise shows the
  /// [HeaderRow] home header on the home tab ([isHomeTab] true) or a
  /// [TitleSearchAppBar] on other tabs, with search navigation wired through
  /// [router] to the global search route in both cases. [onProjectTap] is
  /// forwarded to the home header's project selector.
  ///
  /// Dependencies are passed in by the caller (resolved once at
  /// field-initialisation time) rather than looked up via `Modular.get()`
  /// here, since this runs inside `build()` on every shell rebuild.
  static PreferredSizeWidget buildHeader({
    required bool isHomeTab,
    required CurrentProjectNotifier currentProjectNotifier,
    required AppRouter router,
    required ProjectUIProvider projectUIProvider,
    VoidCallback? onProjectTap,
  }) {
    final projectId = currentProjectNotifier.currentProjectId;
    if (projectId != null && projectId.isNotEmpty) {
      return projectUIProvider.buildProjectHeaderAppbar();
    }

    void onSearchTap() => router.pushNamed(fullGlobalSearchRoute);

    if (isHomeTab) {
      return HeaderRow(
        onSearchTap: onSearchTap,
        onProjectTap: onProjectTap,
        // TODO: [CA-731] Wire NotificationBloc when NotificationModule is ready.
        // https://ripplearc.youtrack.cloud/issue/CA-731
        // TODO: [CA-732] Wire ProfileBloc when ProfileModule is ready.
        // https://ripplearc.youtrack.cloud/issue/CA-732
      );
    }
    return TitleSearchAppBar(onSearchTap: onSearchTap);
  }
}
