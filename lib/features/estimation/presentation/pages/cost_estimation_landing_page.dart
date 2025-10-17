import 'package:construculator/features/auth/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/auth_bloc/auth_state.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_tile.dart';
import 'package:construculator/features/estimation/presentation/widgets/project_header_app_bar.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';

class CostEstimationLandingPage extends StatefulWidget {
  final String? projectId;
  
  const CostEstimationLandingPage({super.key, this.projectId});

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
              avatarUrl: userAvatarUrl,
            ),
            body: _buildBody(),
          );
        },
      ),
    );
  }

  final estimations = [];

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ...estimations.map(
            (estimation) => CostEstimationTile(estimation: estimation),
          ),
        ],
      ),
    );
  }
}
