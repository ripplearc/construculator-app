import 'package:construculator/features/dashboard/presentation/bloc/dashboard_bloc/dashboard_bloc.dart';
import 'package:construculator/features/dashboard/presentation/widgets/recent_estimations_section.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class DashboardPage extends StatelessWidget {
  final AppRouter router;

  const DashboardPage({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    final typography = context.textTheme;
    return BlocConsumer<DashboardBloc, DashboardState>(
      listenWhen: (_, curr) =>
          curr is DashboardNavigateToLogin ||
          curr is DashboardNavigateToCreateAccount,
      listener: (context, state) {
        if (state is DashboardNavigateToLogin) {
          router.navigate(fullLoginRoute);
        } else if (state is DashboardNavigateToCreateAccount) {
          router.navigate(fullCreateAccountRoute, arguments: state.email);
        }
      },
      buildWhen: (_, curr) => curr is DashboardUserLoaded,
      builder: (context, state) {
        final userDisplayName =
            state is DashboardUserLoaded ? state.userDisplayName : '...';
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
                        'Welcome back, $userDisplayName',
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
                RecentEstimationsSection(router: router),
                const SizedBox(height: CoreSpacing.space8),
                Center(
                  child: CoreButton(
                    onPressed: () => context
                        .read<DashboardBloc>()
                        .add(const DashboardLogoutRequested()),
                    label: 'Logout',
                    centerAlign: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
