import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:construculator/libraries/router/routes/estimation_routes.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final notifier = Modular.get<AuthNotifier>();
  final authManager = Modular.get<AuthManager>();
  String userInfo = '...';
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
                userInfo =
                    '${result.data?.firstName} ${result.data?.lastName}!';
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
      appBar: AppBar(
        title: const Text('Construculator'),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: Container(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.dashboard,
                size: 64,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome back, $userInfo',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You are now logged in to your account',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              CoreButton(
                onPressed: () {
                  final authManager = Modular.get<AuthManager>();
                  authManager.logout();
                  _router.navigate(fullLoginRoute);
                },
                label: 'Logout',
                centerAlign: true,
              ),
              CoreButton(
                onPressed: () {
                  _router.navigate(fullEstimationLandingRoute);
                },
                label: 'Cost Estimation',
                centerAlign: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
