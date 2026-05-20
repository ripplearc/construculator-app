import 'package:construculator/features/dashboard/presentation/widgets/recent_estimations_section.dart';
import 'package:construculator/features/global_search/presentation/pages/global_search_page.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class DashboardPage extends StatefulWidget {
  final AuthNotifier authNotifier;
  final AuthManager authManager;
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
  String userInfo = '...';
  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    widget.authNotifier.onUserProfileChanged.listen((event) {
      if (event == null) {
        final cred = widget.authManager.getCurrentCredentials();
        widget.router.navigate(fullCreateAccountRoute, arguments: cred.data?.email);
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
    final typography = context.textTheme;
    final colors = context.colorTheme;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboardTitle),
        centerTitle: true,
        backgroundColor: colors.pageBackground,
        actions: [
          CoreIconWidget(
            icon: CoreIcons.search,
            semanticLabel: l10n.dashboardSearchSemanticLabel,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const GlobalSearchPage(),
              ),
            ),
          ),
          const SizedBox(width: CoreSpacing.space4),
        ],
      ),
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
                    'Welcome back, $userInfo',
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
