import 'package:construculator/features/estimation/presentation/widgets/project_header_app_bar.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

class CostEstimationLandingPage extends StatefulWidget {
  const CostEstimationLandingPage({super.key});

  @override
  State<CostEstimationLandingPage> createState() => _CostEstimationLandingPageState();
}

class _CostEstimationLandingPageState extends State<CostEstimationLandingPage> {
  final notifier = Modular.get<AuthNotifier>();
  final authManager = Modular.get<AuthManager>();
  String userAvatarUrl = "";
  final AppRouter _router = Modular.get<AppRouter>();
  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    notifier.onUserProfileChanged.listen((event) {
      if (event == null) {
        final cred = authManager.getCurrentCredentials();
        _router.navigate(fullCreateAccountRoute, arguments: cred.data?.email);
      }
    });
    final cred = authManager.getCurrentCredentials();
    if (cred.data?.id == null) {
      _router.navigate(fullLoginRoute);
    } else {
      authManager
          .getUserProfile(cred.data?.id ?? '')
          .then((result) {
            if (result.isSuccess && result.data != null) {
              setState(() {
                userAvatarUrl = '${result.data?.profilePhotoUrl}';
              });
            }
          })
          .catchError((error) {
            if (!mounted) return;
            CoreToast.showError(context, 'Failed to load profile', 'Close');
          });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ProjectHeaderAppBar(
        projectName: "My project",
        onProjectTap: () {},
        onSearchTap: () {},
        onNotificationTap: () {},
        avatarUrl: userAvatarUrl,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(),
    );
  }
}
