import 'dart:async';

import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_estimation_list_bloc/cost_estimation_list_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/add_cost_estimation_bloc/add_cost_estimation_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/delete_cost_estimation_bloc/delete_cost_estimation_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_empty_widget.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_tile.dart';
import 'package:construculator/features/estimation/presentation/widgets/delete_estimation_confirmation_sheet.dart';
import 'package:construculator/features/estimation/presentation/widgets/estimation_actions_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/project/presentation/project_ui_provider.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/estimation_routes.dart';
import 'package:construculator/libraries/ui/core_icon_sizes.dart';
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
  late final AuthNotifier _authNotifier;
  StreamSubscription? _userProfileSub;
  String userAvatarUrl = '';

  void fetchUserProfile() async {
    final authManager = Modular.get<AuthManager>();
    final cred = authManager.getCurrentCredentials();
    if (cred.data?.id != null) {
      authManager.getUserProfile(cred.data?.id ?? '');
    }
  }

  @override
  void initState() {
    _authNotifier = Modular.get<AuthNotifier>();

    _userProfileSub = _authNotifier.onUserProfileChanged.listen((user) {
      //TODO: https://ripplearc.youtrack.cloud/issue/CA-466/CostEstimation-State-Synchronization-in-costestimationlandingpage.dart (move this logic to project usecase)
      if (!mounted) return;
      setState(() {
        userAvatarUrl = user?.profilePhotoUrl ?? '';
      });
    });

    fetchUserProfile();

    _router = Modular.get<AppRouter>();
    super.initState();
  }

  @override
  void dispose() {
    _userProfileSub?.cancel();
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
  ) {
    // TODO: https://ripplearc.youtrack.cloud/issue/CA-472/CoreUI-Standardize-bottom-sheets-with-CoreQuickSheet-component (Standardize bottom sheets with CoreQuickSheet component)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorTheme.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => EstimationActionsSheet(
        estimationName: estimation.estimateName,
        onRename: () {
          _router.pop();
          // TODO:https://ripplearc.youtrack.cloud/issue/CA-100
        },
        onFavourite: () {
          _router.pop();
          // TODO:https://ripplearc.youtrack.cloud/issue/CA-88
        },
        onRemove: () {
          _router.pop();
          _showDeleteConfirmationSheet(estimation, colorTheme);
        },
        onLock: (bool isLocked) {
          // TODO:https://ripplearc.youtrack.cloud/issue/CA-88
        },
        isLocked: estimation.lockStatus.isLocked,
      ),
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
              if (message != null) {
                CoreToast.showError(context, message, l10n.closeLabel);
              }
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
      ],
      child: Scaffold(
        backgroundColor: colorTheme.pageBackground,
        appBar: Modular.get<ProjectUIProvider>().buildProjectHeaderAppbar(
          projectId: widget.projectId,
          avatarImage: userAvatarUrl.isNotEmpty
              ? NetworkImage(userAvatarUrl)
              : null,
        ),
        body: _buildBody(l10n, colorTheme),
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
            ).add(CostEstimationListStartWatching(projectId: widget.projectId));
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
          child: CoreButton(
            label: l10n.addEstimation,
            onPressed: _createEstimation,
            isDisabled: isCreating,
            variant: CoreButtonVariant.secondary,
            size: CoreButtonSize.medium,
            icon: CoreIconWidget(
              icon: CoreIcons.add,
              size: CoreIconSizes.small,
              color: colorTheme.buttonSurface,
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
    return Stack(
      children: [
        BlocBuilder<AddCostEstimationBloc, AddCostEstimationState>(
          builder: (context, state) {
            final colorTheme = context.colorTheme;

            final isCreating = state is AddCostEstimationInProgress;
            final itemCount = estimations.length + (isCreating ? 1 : 0);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: ListView.builder(
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  final isLoadingItem = isCreating && index == itemCount - 1;
                  if (isLoadingItem) {
                    return const CoreLoadingIndicator(size: 50);
                  }

                  final estimation = estimations[index];
                  return CostEstimationTile(
                    estimation: estimation,
                    onTap: () => _navigateToDetails(estimation.id),
                    onMenuTap: () =>
                        _showEstimationActionsSheet(estimation, colorTheme),
                  );
                },
              ),
            );
          },
        ),
        _buildPositionedAddButton(),
      ],
    );
  }

  void _navigateToDetails(String estimationId) {
    _router.pushNamed('$fullEstimationDetailsRoute/$estimationId');
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
      case EstimationErrorType.authenticationError:
        return l10n.userIdNotAvailable;
      default:
        return l10n.unexpectedErrorMessage;
    }
  }
}
