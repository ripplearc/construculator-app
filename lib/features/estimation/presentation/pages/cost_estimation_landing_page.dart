import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/usecases/get_estimations_usecase.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_estimation_list_bloc/cost_estimation_list_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_tile.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_empty_page.dart';
import 'package:construculator/features/estimation/presentation/widgets/project_header_app_bar.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';

class CostEstimationLandingPage extends StatefulWidget {
  final String projectId;
  
  const CostEstimationLandingPage({super.key, required this.projectId});

  @override
  State<CostEstimationLandingPage> createState() =>
      _CostEstimationLandingPageState();
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
    return BlocProvider(
      create: (context) => CostEstimationListBloc(
        getEstimationsUseCase: Modular.get<GetEstimationsUseCase>(),
        projectId: widget.projectId,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: ProjectHeaderAppBar(
          projectId: widget.projectId,
          onProjectTap: () {},
          onSearchTap: () {},
          onNotificationTap: () {},
          avatarUrl: userAvatarUrl,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return BlocConsumer<CostEstimationListBloc, CostEstimationListState>(
      listener: (context, state) {
        if (state is CostEstimationListError) {
          CoreToast.showError(
            context, 
            state.message, 
            'Close',
          );
        }
      },
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            BlocProvider.of<CostEstimationListBloc>(context).add(
              const CostEstimationListRefreshEvent(),
            );
          },
          child: _buildContent(state),
        );
      },
    );
  }

  Widget _buildContent(CostEstimationListState state) {
    if (state is CostEstimationListLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state is CostEstimationListEmpty) {
      return _buildEmptyState();
    }

    if (state is CostEstimationListWithData) {
      return _buildEstimationsList(state.estimates);
    }

    // Fallback for initial state
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildEmptyState() {
    return const CostEstimationEmptyPage(
      message: 'No estimation added. To add an estimation please click on add button',
    );
  }

  Widget _buildEstimationsList(List<CostEstimate> estimations) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: ListView.builder(
        itemCount: estimations.length,
        itemBuilder: (context, index) {
          final estimation = estimations[index];
          return CostEstimationTile(
            estimation: estimation,
            onTap: () {},
            onMenuTap: () {},
          );
        },
      ),
    );
  }
}
