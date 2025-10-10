import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_estimation_list_bloc/cost_estimation_list_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/auth_bloc/auth_state.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_tile.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/project/presentation/project_ui_provider.dart';

import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_empty_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              projectId: widget.projectId,
              avatarImage: userAvatarUrl.isNotEmpty
                  ? NetworkImage(userAvatarUrl)
                  : null,
            ),
            body: _buildBody(l10n),
          );
        },
      ),
    );
  }

  Widget _buildBody(AppLocalizations? l10n) {
    return BlocConsumer<CostEstimationListBloc, CostEstimationListState>(
      listener: (context, state) {
        if (state is CostEstimationListError) {
          final message = _mapFailureToMessage(l10n, state.failure);
          CoreToast.showError(context, message, l10n?.closeLabel ?? '');
        }
      },
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            BlocProvider.of<CostEstimationListBloc>(
              context,
            ).add(CostEstimationListRefreshEvent(projectId: widget.projectId));
          },
          child: _buildContent(state, l10n),
        );
      },
    );
  }

  Widget _buildContent(CostEstimationListState state, AppLocalizations? l10n) {
    if (state is CostEstimationListLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is CostEstimationListEmpty) {
      return _buildEmptyState(l10n);
    }

    if (state is CostEstimationListWithData) {
      return _buildEstimationsList(state.estimates);
    }

    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyState(AppLocalizations? l10n) {
    return CostEstimationEmptyPage(
      message:
          l10n?.costEstimationEmptyMessage ??
          'No estimation added. To add an estimation please click on add button',
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

  String? _mapFailureToMessage(AppLocalizations? l10n, Failure failure) {
    if (failure is! EstimationFailure) {
      return l10n?.unexpectedErrorMessage;
    }
    switch (failure.errorType) {
      case EstimationErrorType.timeoutError:
        return l10n?.timeoutError;
      case EstimationErrorType.connectionError:
        return l10n?.connectionError;
      default:
        return l10n?.unexpectedErrorMessage;
    }
  }
}
