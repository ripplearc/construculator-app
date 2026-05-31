import 'dart:async';

import 'package:construculator/features/dashboard/presentation/widgets/recent_estimations_section.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class DashboardPage extends StatefulWidget {
  /// Notifies the widget of changes in user authentication or profile state.
  final AuthNotifier authNotifier;

  /// Manages user credentials and profile loading.
  final AuthManager authManager;

  /// The router used to navigate to other pages (e.g. login, create account).
  final AppRouter router;

  const DashboardPage({
    super.key,
    required this.authNotifier,
    required this.authManager,
    required this.router,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _userInfo = '...';
  StreamSubscription<dynamic>? _profileSubscription;

  @override
  void initState() {
    super.initState();
    _profileSubscription = widget.authNotifier.onUserProfileChanged.listen((
      event,
    ) {
      if (event == null) {
        final cred = widget.authManager.getCurrentCredentials();
        widget.router.navigate(
          fullCreateAccountRoute,
          arguments: cred.data?.email,
        );
      }
    });

    final cred = widget.authManager.getCurrentCredentials();
    if (cred.data?.id == null) {
      widget.router.navigate(fullLoginRoute);
    } else {
      widget.authManager
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
    _profileSubscription?.cancel();
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
                  widget.authManager.logout();
                  widget.router.navigate(fullLoginRoute);
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
