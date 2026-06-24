import 'package:construculator/app/shell/app_shell_bloc/app_shell_bloc.dart';
import 'package:construculator/app/shell/module_model.dart';
import 'package:construculator/features/dashboard/presentation/bloc/recent_estimations_bloc/recent_estimations_bloc.dart';
import 'package:construculator/features/dashboard/presentation/widgets/estimation_card.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/estimation_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Displays the recent cost estimations section on the dashboard,
/// including a horizontally scrollable list of [EstimationCard]s
/// and navigation to the full estimations list.
class RecentEstimationsSection extends StatelessWidget {
  /// The router used for navigation (e.g., to the full estimations list or estimation details).
  final AppRouter router;

  const RecentEstimationsSection({
    super.key,
    required this.router,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.recentCostEstimationsTitle,
              style: typography.titleMediumSemiBold.copyWith(
                color: colors.textDark,
              ),
            ),
            TextButton(
              onPressed: () => _openAllEstimations(context),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                context.l10n.viewAllButton,
                style: typography.bodyMediumSemiBold.copyWith(
                  color: colors.textLink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: CoreSpacing.space4),
        SizedBox(
          height: CoreSpacing.space32 - CoreSpacing.space2,
          child: BlocBuilder<RecentEstimationsBloc, RecentEstimationsState>(
            builder: (context, state) {
              if (state is RecentEstimationsLoading &&
                  state.lastKnownEstimations == null) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    return Container(
                      width: CoreSpacing.space40,
                      margin: const EdgeInsets.only(right: CoreSpacing.space3),
                      decoration: BoxDecoration(
                        color: colors.backgroundGrayLight,
                        borderRadius: BorderRadius.circular(CoreSpacing.space3),
                      ),
                    );
                  },
                );
              } else if (state is RecentEstimationsError) {
                return Center(
                  child: Text(
                    context.l10n.recentEstimationsLoadError,
                    style: typography.bodyMediumRegular.copyWith(
                      color: colors.statusError,
                    ),
                  ),
                );
              }

              List<CostEstimate> estimations = [];
              if (state is RecentEstimationsLoaded) {
                estimations = state.estimations;
              } else if (state is RecentEstimationsLoading) {
                estimations = state.lastKnownEstimations ?? [];
              }

              if (estimations.isEmpty) {
                return Center(
                  child: Text(
                    context.l10n.recentEstimationsEmptyState,
                    style: typography.bodyMediumRegular.copyWith(
                      color: colors.textBody,
                    ),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: estimations.length,
                itemBuilder: (context, index) {
                  final estimation = estimations[index];
                  return EstimationCard(
                    estimation: estimation,
                    onTap: () => _openEstimationDetails(estimation.id),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _openAllEstimations(BuildContext context) {
    final projectId =
        context.read<RecentEstimationsBloc>().currentProjectId;
    if (projectId == null || projectId.isEmpty) {
      return;
    }

    context.read<AppShellBloc>().add(const AppShellTabSelected(ShellTab.estimation));
  }

  void _openEstimationDetails(String estimationId) {
    router.pushNamed('$fullEstimationDetailsRoute/$estimationId');
  }
}
