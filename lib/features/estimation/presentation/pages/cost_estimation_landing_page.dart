import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/presentation/bloc/add_cost_estimation_bloc/add_cost_estimation_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/change_lock_status_bloc/change_lock_status_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_estimation_list_bloc/cost_estimation_list_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_estimation_log_bloc/cost_estimation_log_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/delete_cost_estimation_bloc/delete_cost_estimation_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/rename_estimation_bloc/rename_estimation_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_empty_widget.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_logs_list.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_tile.dart';
import 'package:construculator/features/estimation/presentation/widgets/delete_estimation_confirmation_sheet.dart';
import 'package:construculator/features/estimation/presentation/widgets/estimation_actions_sheet.dart';
import 'package:construculator/features/estimation/presentation/widgets/estimation_rename_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/estimation_routes.dart';
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

class _CostEstimationLandingPageState extends State<CostEstimationLandingPage> {
  late final AppRouter _router;
  late final ScrollController _scrollController;

  static const double _loadMoreThreshold = 200.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _router = Modular.get<AppRouter>();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (maxScroll - currentScroll <= _loadMoreThreshold) {
      final bloc = BlocProvider.of<CostEstimationListBloc>(context);
      final state = bloc.state;

      if (state is CostEstimationListWithData &&
          state.hasMore &&
          !state.isLoadingMore) {
        bloc.add(CostEstimationListLoadMore(projectId: widget.projectId));
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _createEstimation() {
    final bloc = BlocProvider.of<AddCostEstimationBloc>(context);
    final l10n = context.l10n;

    bloc.add(
      AddCostEstimationSubmitted(
        estimationName: l10n.untitledEstimation,
        projectId: widget.projectId,
      ),
    );
  }

  void _showEstimationActionsSheet(
    CostEstimate estimation,
    AppColorsExtension colorTheme,
  ) async {
    final changeLockStatusBloc = BlocProvider.of<ChangeLockStatusBloc>(context);

    final lockStatusNotifier = ValueNotifier<bool>(
      estimation.lockStatus.isLocked,
    );
    // TODO: [CA-472] Use `CoreQuickSheet.show` to standardize bottom sheets  https://ripplearc.youtrack.cloud/issue/CA-472/CoreUI-Standardize-bottom-sheets-with-CoreQuickSheet-component (Standardize bottom sheets with CoreQuickSheet component)
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorTheme.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return BlocProvider.value(
          value: changeLockStatusBloc,
          child: BlocListener<ChangeLockStatusBloc, ChangeLockStatusState>(
            listener: (context, state) {
              if (state is ChangeLockStatusSuccess) {
                lockStatusNotifier.value = state.isLocked;
              } else if (state is ChangeLockStatusFailure) {
                lockStatusNotifier.value = state.originalValue;
              }
            },
            child: EstimationActionsSheet(
              lockStatusNotifier: lockStatusNotifier,
              estimationName: estimation.estimateName,
              onRename: () {
                _router.pop();
                _showRenameSheet(estimation, colorTheme);
              },
              onFavourite: () {
                _router.pop();
                // TODO: [CA-88] Implement favourite functionality,  https://ripplearc.youtrack.cloud/issue/CA-88
              },
              onRemove: () {
                _router.pop();
                _showDeleteConfirmationSheet(estimation, colorTheme);
              },
              onLockToggle: (bool isLocked) {
                changeLockStatusBloc.add(
                  ChangeLockStatusRequested(
                    estimationId: estimation.id,
                    isLocked: isLocked,
                    projectId: widget.projectId,
                  ),
                );
              },
              onLogs: () {
                CoreQuickSheet.show(
                  context: context,
                  child: BlocProvider.value(
                    value: Modular.get<CostEstimationLogBloc>(),
                    child: CostEstimationLogsList(
                      estimateId: estimation.id,
                      estimateName: estimation.estimateName,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    lockStatusNotifier.dispose();
  }

  void _showRenameSheet(
    CostEstimate estimation,
    AppColorsExtension colorTheme,
  ) {
    final renameEstimationBloc = BlocProvider.of<RenameEstimationBloc>(context);

    renameEstimationBloc.add(const RenameEstimationReset());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorTheme.transparent,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return BlocProvider.value(
          value: renameEstimationBloc,
          child: EstimationRenameSheet(
            estimationId: estimation.id,
            currentName: estimation.estimateName,
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationSheet(
    CostEstimate estimation,
    AppColorsExtension colorTheme,
  ) {
    final deleteCostEstimationBloc = BlocProvider.of<DeleteCostEstimationBloc>(
      context,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorTheme.transparent,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return DeleteEstimationConfirmationSheet(
          estimationName: estimation.estimateName,
          // TODO: https://ripplearc.youtrack.cloud/issue/CA-269/ConstruculatorCost-Estimation-Cost-Detailss
          imagesAttachedCount: 10,
          documentsAttachedCount: 10,
          onConfirm: () {
            _router.pop();
            // TODO: https://ripplearc.youtrack.cloud/issue/CA-467/Refactor-Cost-Estimation-Landing-Page-to-retrieve-Project-ID-via-Bloc
            deleteCostEstimationBloc.add(
              DeleteCostEstimationRequested(
                estimationId: estimation.id,
                projectId: widget.projectId,
              ),
            );
          },
          onCancel: () {
            _router.pop();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final l10n = context.l10n;

    return MultiBlocListener(
      listeners: [
        BlocListener<AddCostEstimationBloc, AddCostEstimationState>(
          listener: (context, state) {
            if (state is AddCostEstimationFailure) {
              final message = _mapFailureToMessage(l10n, state.failure);
              CoreToast.showError(context, message, l10n.closeLabel);
            }
          },
        ),
        BlocListener<DeleteCostEstimationBloc, DeleteCostEstimationState>(
          listener: (context, state) {
            final l10n = context.l10n;

            if (state is DeleteCostEstimationSuccess) {
              CoreToast.showSuccess(
                context,
                l10n.estimationDeletedSuccess,
                l10n.closeLabel,
              );
            }

            if (state is DeleteCostEstimationFailure) {
              CoreToast.showError(
                context,
                _mapFailureToMessage(l10n, state.failure),
                l10n.closeLabel,
              );
            }
          },
        ),
        BlocListener<ChangeLockStatusBloc, ChangeLockStatusState>(
          listener: (context, state) {
            final l10n = context.l10n;
            if (state is ChangeLockStatusSuccess) {
              if (state.isLocked) {
                CoreToast.showWarning(
                  context,
                  l10n.estimationLockedSuccessTitle,
                  l10n.closeLabel,
                );
              } else {
                CoreToast.showSuccess(
                  context,
                  l10n.estimationUnlockedSuccessTitle,
                  l10n.closeLabel,
                );
              }
            }
            if (state is ChangeLockStatusFailure) {
              CoreToast.showError(
                context,
                _mapFailureToMessage(l10n, state.failure),
                l10n.closeLabel,
              );
            }
          },
        ),
        BlocListener<RenameEstimationBloc, RenameEstimationState>(
          listener: (context, state) {
            if (state is RenameEstimationFailure) {
              final message = _mapFailureToMessage(context.l10n, state.failure);
              CoreToast.showError(context, message, context.l10n.closeLabel);
            }
          },
        ),
      ],
      child: ColoredBox(
        color: colorTheme.pageBackground,
        child: _buildBody(l10n, colorTheme),
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
            ).add(CostEstimationListRefresh(projectId: widget.projectId));
          },
          color: colorTheme.buttonSurface,
          child: _buildContent(state, l10n),
        );
      },
    );
  }

  Widget _buildContent(CostEstimationListState state, AppLocalizations l10n) {
    if (state is CostEstimationListLoading) {
      return const Center(child: CoreLoadingIndicator());
    }

    if (state is CostEstimationListEmpty) {
      return _buildEmptyState();
    }

    if (state is CostEstimationListWithData) {
      return _buildEstimationsList(state.estimates);
    }

    return const Center(child: CoreLoadingIndicator());
  }

  Widget _buildPositionedAddButton() {
    final size = MediaQuery.of(context).size;
    final colorTheme = context.colorTheme;
    final l10n = context.l10n;

    return BlocBuilder<AddCostEstimationBloc, AddCostEstimationState>(
      builder: (context, state) {
        final isCreating = state is AddCostEstimationInProgress;
        return Positioned(
          bottom: size.height * CostEstimationLandingPage._buttonBottomRatio,
          right: size.width * CostEstimationLandingPage._buttonRightRatio,
          child: IntrinsicWidth(
            child: CoreButton(
              label: l10n.addEstimation,
              onPressed: _createEstimation,
              isDisabled: isCreating,
              variant: CoreButtonVariant.secondary,
              size: CoreButtonSize.medium,
              icon: CoreIconWidget(
                icon: CoreIcons.add,
                size: 20,
                color: colorTheme.buttonSurface,
              ),
              fullWidth: false,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final l10n = context.l10n;
    return Stack(
      children: [
        BlocBuilder<AddCostEstimationBloc, AddCostEstimationState>(
          builder: (context, state) {
            if (state is AddCostEstimationInProgress) {
              return const Center(child: CoreLoadingIndicator());
            }
            return CostEstimationEmptyWidget(
              message: l10n.costEstimationEmptyMessage,
            );
          },
        ),
        _buildPositionedAddButton(),
      ],
    );
  }

  Widget _buildEstimationsList(List<CostEstimate> estimations) {
    final colorTheme = context.colorTheme;
    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            BlocBuilder<AddCostEstimationBloc, AddCostEstimationState>(
              builder: (context, state) {
                if (state is AddCostEstimationInProgress) {
                  return const SliverPadding(
                    padding: EdgeInsets.only(top: 16),
                    sliver: SliverToBoxAdapter(
                      child: CoreLoadingIndicator(size: 50),
                    ),
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              sliver: SliverList.builder(
                itemCount: estimations.length,
                itemBuilder: (context, index) {
                  final estimation = estimations[index];
                  return CostEstimationTile(
                    estimation: estimation,
                    onTap: () => _navigateToDetails(estimation.id),
                    onMenuTap: () =>
                        _showEstimationActionsSheet(estimation, colorTheme),
                  );
                },
              ),
            ),

            BlocBuilder<CostEstimationListBloc, CostEstimationListState>(
              buildWhen: (previous, current) {
                if (previous is CostEstimationListWithData &&
                    current is CostEstimationListWithData) {
                  return previous.isLoadingMore != current.isLoadingMore;
                }
                return false;
              },
              builder: (context, state) {
                if (state is CostEstimationListWithData &&
                    state.isLoadingMore) {
                  return const SliverToBoxAdapter(
                    child: CoreLoadingIndicator(size: 50),
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),
          ],
        ),
        _buildPositionedAddButton(),
      ],
    );
  }

  void _navigateToDetails(String estimationId) {
    _router.pushNamed('$fullEstimationDetailsRoute/$estimationId');
  }

  String _mapFailureToMessage(AppLocalizations l10n, Failure failure) {
    if (failure is! EstimationFailure) {
      return l10n.unexpectedErrorMessage;
    }
    switch (failure.errorType) {
      case EstimationErrorType.timeoutError:
        return l10n.timeoutError;
      case EstimationErrorType.connectionError:
        return l10n.connectionError;
      case EstimationErrorType.authenticationError:
        return l10n.userIdNotAvailable;
      case EstimationErrorType.permissionDenied:
        return l10n.permissionDenied;
      default:
        return l10n.unexpectedErrorMessage;
    }
  }
}
