import 'package:construculator/features/dashboard/presentation/bloc/recent_estimations_bloc/recent_estimations_bloc.dart';
import 'package:construculator/features/dashboard/presentation/widgets/estimation_card.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';

class RecentEstimationsSection extends StatefulWidget {
  const RecentEstimationsSection({super.key});

  @override
  State<RecentEstimationsSection> createState() =>
      _RecentEstimationsSectionState();
}

class _RecentEstimationsSectionState extends State<RecentEstimationsSection> {
  late RecentEstimationsBloc _bloc;
  late CurrentProjectNotifier _projectNotifier;

  @override
  void initState() {
    super.initState();
    _bloc = Modular.get<RecentEstimationsBloc>();
    _projectNotifier = Modular.get<CurrentProjectNotifier>();

    // Start watching immediately if a project is selected
    if (_projectNotifier.currentProjectId != null) {
      _bloc.add(
        RecentEstimationsWatchStarted(_projectNotifier.currentProjectId!),
      );
    }

    // Re-watch when project changes
    _projectNotifier.onCurrentProjectChanged.listen((projectId) {
      if (projectId != null && mounted) {
        _bloc.add(RecentEstimationsWatchStarted(projectId));
      }
    });
  }

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
              'Recent cost estimations',
              style: typography.titleMediumSemiBold.copyWith(
                color: colors.textDark,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to full list
                // For now, we can just log or implement route
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View all',
                style: typography.bodyMediumSemiBold.copyWith(
                  color: colors.textLink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120, // Approximate height for the card
          child: BlocBuilder<RecentEstimationsBloc, RecentEstimationsState>(
            bloc: _bloc,
            builder: (context, state) {
              if (state is RecentEstimationsLoading &&
                  state.lastKnownEstimations == null) {
                // Initial loading skeleton
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: colors.backgroundGrayLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    );
                  },
                );
              } else if (state is RecentEstimationsError) {
                return Center(
                  child: Text(
                    'Failed to load recent estimations.',
                    style: typography.bodyMediumRegular.copyWith(
                      color: colors.statusError,
                    ),
                  ),
                );
              }

              // Loaded or Loading with previous data
              List<CostEstimate> estimations = [];
              if (state is RecentEstimationsLoaded) {
                estimations = state.estimations;
              } else if (state is RecentEstimationsLoading) {
                estimations = state.lastKnownEstimations ?? [];
              }

              if (estimations.isEmpty) {
                return Center(
                  child: Text(
                    'No recent estimations found.',
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
                    onTap: () {
                      // Navigate to estimation details
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
