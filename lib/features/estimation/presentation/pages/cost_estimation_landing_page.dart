import 'package:construculator/features/auth/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/auth_bloc/auth_state.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_tile.dart';
import 'package:construculator/libraries/project/presentation/project_ui_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class CostEstimationLandingPage extends StatefulWidget {
  const CostEstimationLandingPage({super.key});

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
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      bloc: _authBloc,
      listener: (context, state) {
        if (state is AuthLoadSuccess) {
          setState(() {
            userAvatarUrl = state.avatarUrl ?? '';
          });
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
            backgroundColor: Theme.of(
              context,
            ).extension<AppColorsExtension>()?.pageBackground,
            appBar: Modular.get<ProjectUIProvider>().buildProjectHeaderAppbar(
              projectId: '',
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

  final List<CostEstimate> estimations = [];

  Widget _buildBody() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: CoreSpacing.space4),
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
