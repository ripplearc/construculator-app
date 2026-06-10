import 'dart:async';

import 'package:construculator/features/dashboard/presentation/widgets/recent_estimations_section.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
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
  final _notifier = Modular.get<AuthNotifier>();
  final _authManager = Modular.get<AuthManager>();
  String _userInfo = '...';
  final AppRouter _router = Modular.get<AppRouter>();
  StreamSubscription<dynamic>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = _notifier.onUserProfileChanged.listen((event) {
      if (event == null) {
        final cred = _authManager.getCurrentCredentials();
        _router.navigate(fullCreateAccountRoute, arguments: cred.data?.email);
      }
    });

    final cred = _authManager.getCurrentCredentials();
    if (cred.data?.id == null) {
      _router.navigate(fullLoginRoute);
    } else {
      _authManager
          .getUserProfile(cred.data?.id ?? '')
          .then((result) {
            if (result.isSuccess && result.data != null) {
              setState(() {
                _userInfo =
                    '${result.data?.firstName} ${result.data?.lastName}!';
              });
            }
          })
          .catchError((error) {
            if (!mounted) return;
            CoreToast.showError(
              context,
              context.l10n.dashboardLoadProfileError,
              context.l10n.closeButton,
            );
          });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typography = context.textTheme;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(CoreSpacing.space6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.dashboard,
                    size: CoreSpacing.space16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: CoreSpacing.space6),
                  Text(
                    'Welcome back, $_userInfo',
                    textAlign: TextAlign.center,
                    style: typography.headlineMediumSemiBold,
                  ),
                  const SizedBox(height: CoreSpacing.space2),
                  Text(
                    'You are now logged in to your account',
                    textAlign: TextAlign.center,
                    style: typography.bodyLargeRegular,
                  ),
                  const SizedBox(height: CoreSpacing.space8),
                ],
              ),
            ),
            const SizedBox(height: CoreSpacing.space8),
            const RecentEstimationsSection(),
            const SizedBox(height: CoreSpacing.space8),
            Center(
              child: CoreButton(
                onPressed: () {
                  _authManager.logout();
                  _router.navigate(fullLoginRoute);
                },
                label: 'Logout',
                centerAlign: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
