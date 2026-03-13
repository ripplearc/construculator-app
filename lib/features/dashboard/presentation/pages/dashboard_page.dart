import 'dart:async';

import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/presentation/project_ui_provider.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const String _fallbackProjectId =
      '950e8400-e29b-41d4-a716-446655440001';

  final AuthNotifier _notifier = Modular.get<AuthNotifier>();
  final AuthManager _authManager = Modular.get<AuthManager>();
  final CurrentProjectNotifier _currentProjectNotifier =
      Modular.get<CurrentProjectNotifier>();
  final AppRouter _router = Modular.get<AppRouter>();

  StreamSubscription<String?>? _projectChangedSubscription;
  StreamSubscription? _userProfileChangedSubscription;
  late String _projectId;

  String _resolveProjectId(String? projectId) => projectId ?? _fallbackProjectId;

  @override
  void initState() {
    super.initState();
    _projectId = _resolveProjectId(_currentProjectNotifier.currentProjectId);

    _projectChangedSubscription = _currentProjectNotifier.onCurrentProjectChanged
        .listen((projectId) {
          if (!mounted) return;
          setState(() {
            _projectId = _resolveProjectId(projectId);
          });
        });

    _userProfileChangedSubscription = _notifier.onUserProfileChanged.listen((
      event,
    ) {
      if (event == null) {
        final credentials = _authManager.getCurrentCredentials();
        _router.navigate(
          fullCreateAccountRoute,
          arguments: credentials.data?.email,
        );
      }
    });

    final credentials = _authManager.getCurrentCredentials();
    final credentialId = credentials.data?.id;
    if (credentialId == null) {
      _router.navigate(fullLoginRoute);
      return;
    }

    _loadUserProfile(credentialId);
  }

  Future<void> _loadUserProfile(String credentialId) async {
    try {
      await _authManager.getUserProfile(credentialId);
    } catch (_) {
      if (!mounted) return;
      CoreToast.showError(context, 'Failed to load profile', 'Close');
    }
  }

  @override
  void dispose() {
    _projectChangedSubscription?.cancel();
    _userProfileChangedSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colors.pageBackground,
      appBar: Modular.get<ProjectUIProvider>().buildProjectHeaderAppbar(
        projectId: _projectId,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CoreIconWidget(icon: CoreIcons.emptyEstimation),
            const SizedBox(height: 24),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              child: Text(
                l10n.dashboardQuickAccessMessage,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMediumRegular.copyWith(
                  color: context.colorTheme.textHeadline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
