import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_estimation_list_bloc/cost_estimation_list_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/add_cost_estimation_bloc/add_cost_estimation_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/auth_bloc/auth_state.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_empty_widget.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_tile.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/mixins/localization_mixin.dart';
import 'package:construculator/libraries/project/presentation/project_ui_provider.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/estimation_routes.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class CostEstimationLandingPage extends StatefulWidget {
  final String projectId;

  static const double _buttonBottomRatio = 0.135;
  static const double _buttonRightRatio = 0.05;

  const CostEstimationLandingPage({super.key, required this.projectId});

  @override
  State<CostEstimationLandingPage> createState() =>
      _CostEstimationLandingPageState();
}

class _CostEstimationLandingPageState extends State<CostEstimationLandingPage>
    with LocalizationMixin {
  late final AuthBloc _authBloc;
  String userAvatarUrl = '';
  String? userId;

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

  void _createEstimation() {
    final currentUserId = userId;
    if (currentUserId == null) {
      CoreToast.showError(context, l10n.userIdNotAvailable, l10n.closeLabel);
      return;
    }

    final bloc = BlocProvider.of<AddCostEstimationBloc>(context);

    bloc.add(
      AddCostEstimationSubmitted(
        estimationName: l10n.untitledEstimation,
        projectId: widget.projectId,
        creatorUserId: currentUserId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = AppColorsExtension.of(context);

    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          bloc: _authBloc,
          listener: (context, state) {
            if (state is AuthLoadSuccess) {
              setState(() {
                userAvatarUrl = state.avatarUrl ?? '';
                userId = state.user?.id;
              });
            }
          },
        ),
        BlocListener<AddCostEstimationBloc, AddCostEstimationState>(
          listener: (context, state) {
            if (state is AddCostEstimationFailure) {
              CoreToast.showError(
                context,
                _mapFailureToMessage(l10n, state.failure),
                l10n.closeLabel,
              );
            }

            if (state is AddCostEstimationSuccess) {
              BlocProvider.of<CostEstimationListBloc>(context).add(
                CostEstimationListRefreshEvent(projectId: widget.projectId),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        bloc: _authBloc,
        builder: (context, state) {
          if (state is AuthLoadUnauthenticated) {
            return const Scaffold(
              // TODO: https://ripplearc.youtrack.cloud/issue/CA-458/CostEstimation-Refactor-Loading-Indicators-in-Construculator-App
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            backgroundColor: colorTheme.pageBackground,
            appBar: Modular.get<ProjectUIProvider>().buildProjectHeaderAppbar(
              projectId: widget.projectId,
              avatarImage: userAvatarUrl.isNotEmpty
                  ? NetworkImage(userAvatarUrl)
                  : null,
            ),
            body: _buildBody(l10n, colorTheme),
          );
        },
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, AppColorsExtension colorTheme) {
    return BlocConsumer<CostEstimationListBloc, CostEstimationListState>(
      listener: (context, state) {
        if (state is CostEstimationListError) {
          final message = _mapFailureToMessage(l10n, state.failure);
          CoreToast.showError(context, message, l10n.closeLabel);
        }
      },
      builder: (context, state) {
        // TODO: https://ripplearc.youtrack.cloud/issue/CA-459/CoreUI-Implement-Custom-Branded-Pull-to-Refresh
        return RefreshIndicator.adaptive(
          onRefresh: () async {
            BlocProvider.of<CostEstimationListBloc>(
              context,
            ).add(CostEstimationListRefreshEvent(projectId: widget.projectId));
          },
          color: colorTheme.buttonSurface,
          child: _buildContent(state, l10n),
        );
      },
    );
  }

  Widget _buildContent(CostEstimationListState state, AppLocalizations l10n) {
    if (state is CostEstimationListLoading) {
      // TODO: https://ripplearc.youtrack.cloud/issue/CA-458/CostEstimation-Refactor-Loading-Indicators-in-Construculator-App
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

  Widget _buildPositionedAddButton(AppLocalizations l10n) {
    final size = MediaQuery.of(context).size;
    final colorTheme = Theme.of(context).extension<AppColorsExtension>();
    return BlocBuilder<AddCostEstimationBloc, AddCostEstimationState>(
      builder: (context, state) {
        final isCreating = state is AddCostEstimationInProgress;
        return Positioned(
          bottom: size.height * CostEstimationLandingPage._buttonBottomRatio,
          right: size.width * CostEstimationLandingPage._buttonRightRatio,
          child: CoreButton(
            label: l10n.addEstimation,
            onPressed: _createEstimation,
            isDisabled: isCreating,
            variant: CoreButtonVariant.secondary,
            size: CoreButtonSize.medium,
            icon: CoreIconWidget(
              icon: CoreIcons.add,
              size: 20,
              color: colorTheme?.buttonSurface,
            ),
            fullWidth: false,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Stack(
      children: [
        BlocBuilder<AddCostEstimationBloc, AddCostEstimationState>(
          builder: (context, state) {
            if (state is AddCostEstimationInProgress) {
              // TODO: https://ripplearc.youtrack.cloud/issue/CA-458/CostEstimation-Refactor-Loading-Indicators-in-Construculator-App
              return const Center(child: CircularProgressIndicator());
            }
            return CostEstimationEmptyWidget(
              message: l10n.costEstimationEmptyMessage,
            );
          },
        ),
        _buildPositionedAddButton(l10n),
      ],
    );
  }

  Widget _buildEstimationsList(List<CostEstimate> estimations) {
    return Stack(
      children: [
        BlocBuilder<AddCostEstimationBloc, AddCostEstimationState>(
          builder: (context, state) {
            final isCreating = state is AddCostEstimationInProgress;
            final itemCount = estimations.length + (isCreating ? 1 : 0);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: ListView.builder(
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  final isLoadingItem = isCreating && index == itemCount - 1;
                  if (isLoadingItem) {
                    return Center(
                      child: const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  final estimation = estimations[index];
                  return CostEstimationTile(
                    estimation: estimation,
                    onTap: () => _navigateToDetails(estimation.id),
                  );
                },
              ),
            );
          },
        ),
        _buildPositionedAddButton(l10n),
      ],
    );
  }

  void _navigateToDetails(String estimationId) {
    final router = Modular.get<AppRouter>();
    router.pushNamed('$fullEstimationDetailsRoute/$estimationId');
  }

  String? _mapFailureToMessage(AppLocalizations l10n, Failure failure) {
    if (failure is! EstimationFailure) {
      return l10n.unexpectedErrorMessage;
    }
    switch (failure.errorType) {
      case EstimationErrorType.timeoutError:
        return l10n.timeoutError;
      case EstimationErrorType.connectionError:
        return l10n.connectionError;
      default:
        return l10n.unexpectedErrorMessage;
    }
  }
}
