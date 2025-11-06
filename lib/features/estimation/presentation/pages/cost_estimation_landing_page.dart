import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_estimation_list_bloc/cost_estimation_list_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/add_cost_estimation_bloc/add_cost_estimation_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/auth_bloc/auth_state.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_tile.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_empty_page.dart';
import 'package:construculator/features/estimation/presentation/widgets/project_header_app_bar.dart';
import 'package:construculator/features/estimation/presentation/widgets/add_estimation_button.dart';
import 'package:construculator/libraries/mixins/localization_mixin.dart';
import 'package:construculator/libraries/router/routes/estimation_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class CostEstimationLandingPage extends StatefulWidget {
  final String projectId;

  const CostEstimationLandingPage({super.key, required this.projectId});

  @override
  State<CostEstimationLandingPage> createState() =>
      _CostEstimationLandingPageState();
}

class _CostEstimationLandingPageState extends State<CostEstimationLandingPage>
    with LocalizationMixin {
  late final AuthBloc _authBloc;
  late final AddCostEstimationBloc _addCostEstimationBloc;
  String userAvatarUrl = '';
  String? userId;

  @override
  void initState() {
    super.initState();
    _authBloc = Modular.get<AuthBloc>();
    _addCostEstimationBloc = Modular.get<AddCostEstimationBloc>();
    _authBloc.initialize();
  }

  @override
  void dispose() {
    _authBloc.close();
    _addCostEstimationBloc.close();
    super.dispose();
  }

  void _createEstimation() {
    final currentUserId = userId;
    if (currentUserId == null) {
      CoreToast.showError(
        context,
        l10n?.userIdNotAvailable ?? 'User ID is not available',
        l10n?.closeLabel ?? 'Close',
      );
      return;
    }

    _addCostEstimationBloc.add(
      AddCostEstimationSubmitted(
        estimationName: l10n?.untitledEstimation ?? 'Untitled Estimation',
        projectId: widget.projectId,
        creatorUserId: currentUserId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      bloc: _authBloc,
      listener: (context, state) {
        if (state is AuthLoadSuccess) {
          setState(() {
            userAvatarUrl = state.avatarUrl ?? '';
            userId = state.user?.id;
          });
        } else if (state is AuthLoadFailure) {
          if (mounted) {
            CoreToast.showError(
              context,
              state.message,
              l10n?.closeLabel ?? 'Close',
            );
          }
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        bloc: _authBloc,
        builder: (context, state) {
          if (state is AuthLoadUnauthenticated) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: ProjectHeaderAppBar(
              projectId: 'My project',
              onProjectTap: () {},
              onSearchTap: () {},
              onNotificationTap: () {},
              avatarImage: userAvatarUrl.isNotEmpty
                  ? NetworkImage(userAvatarUrl)
                  : null,
            ),
            body: _buildBody(),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    return MultiBlocListener(
      listeners: [
        BlocListener<CostEstimationListBloc, CostEstimationListState>(
          listener: (context, state) {
            if (state is CostEstimationListError) {
              CoreToast.showError(
                context,
                state.message,
                l10n?.closeLabel ?? 'Close',
              );
            }
          },
        ),
        BlocListener<AddCostEstimationBloc, AddCostEstimationState>(
          bloc: _addCostEstimationBloc,
          listener: (context, state) {
            if (state is AddCostEstimationSuccess) {
              Modular.to.pushNamed(
                '$fullEstimationDetailsRoute/${state.costEstimation.id}',
              );

              BlocProvider.of<CostEstimationListBloc>(context).add(
                CostEstimationListRefreshEvent(projectId: widget.projectId),
              );
            } else if (state is AddCostEstimationFailure) {
              if (mounted) {
                CoreToast.showError(
                  context,
                  state.message,
                  l10n?.closeLabel ?? 'Close',
                );
              }
            }
          },
        ),
      ],
      child: BlocBuilder<CostEstimationListBloc, CostEstimationListState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              BlocProvider.of<CostEstimationListBloc>(context).add(
                CostEstimationListRefreshEvent(projectId: widget.projectId),
              );
            },
            child: _buildContent(state),
          );
        },
      ),
    );
  }

  Widget _buildContent(CostEstimationListState state) {
    if (state is CostEstimationListLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is CostEstimationListEmpty) {
      return _buildEmptyState();
    }

    if (state is CostEstimationListWithData) {
      return _buildEstimationsList(state.estimates);
    }

    // Fallback for initial state
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyState() {
    return Stack(
      children: [
        CostEstimationEmptyPage(
          message:
              l10n?.noEstimationAddedMessage ??
              'No estimation added. To add an estimation please click on add button',
        ),
        _buildAddEstimationButton(),
      ],
    );
  }

  Widget _buildEstimationsList(List<CostEstimate> estimations) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CoreSpacing.space4,
            vertical: CoreSpacing.space4,
          ),
          child: ListView.builder(
            itemCount: estimations.length,
            itemBuilder: (context, index) {
              final estimation = estimations[index];
              return CostEstimationTile(
                estimation: estimation,
                onMenuTap: () {},
              );
            },
          ),
        ),
        _buildAddEstimationButton(),
      ],
    );
  }

  Widget _buildAddEstimationButton() {
    return Positioned(
      bottom: MediaQuery.of(context).size.height * 0.135,
      right: MediaQuery.of(context).size.width * 0.05,
      child: Container(
        color: CoreBackgroundColors.pageBackground,
        child: AddEstimationButton(onPressed: () => _createEstimation()),
      ),
    );
  }
}
