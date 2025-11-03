import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_estimation_list_bloc/cost_estimation_list_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/auth_bloc/auth_state.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_tile.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_empty_page.dart';
import 'package:construculator/features/estimation/presentation/widgets/project_header_app_bar.dart';
import 'package:construculator/features/estimation/presentation/widgets/add_estimation_button.dart';
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

class _CostEstimationLandingPageState extends State<CostEstimationLandingPage> {
  late final AuthBloc _authBloc;
  String userAvatarUrl = '';

  @override
  void initState() {
    super.initState();
    _authBloc = Modular.get<AuthBloc>();
    _authBloc.initialize();
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      bloc: _authBloc,
      listener: (context, state) {
        if (state is AuthLoadSuccess) {
          setState(() {
            userAvatarUrl = state.avatarUrl ?? '';
          });
        } else if (state is AuthLoadFailure) {
          if (mounted) {
            CoreToast.showError(context, state.message, 'Close');
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
    return BlocConsumer<CostEstimationListBloc, CostEstimationListState>(
      listener: (context, state) {
        if (state is CostEstimationListError) {
          CoreToast.showError(context, state.message, 'Close');
        }
      },
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            BlocProvider.of<CostEstimationListBloc>(
              context,
            ).add(CostEstimationListRefreshEvent(projectId: widget.projectId));
          },
          child: _buildContent(state),
        );
      },
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
        const CostEstimationEmptyPage(
          message:
              'No estimation added. To add an estimation please click on add button',
        ),
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.135,
          right: MediaQuery.of(context).size.width * 0.05,
          child: AddEstimationButton(onPressed: () {}),
        ),
      ],
    );
  }

  Widget _buildEstimationsList(List<CostEstimate> estimations) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: CoreSpacing.space4, vertical: CoreSpacing.space4),
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
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.135,
          right: MediaQuery.of(context).size.width * 0.05,
          child: AddEstimationButton(onPressed: () {}),
        ),
      ],
    );
  }
}
