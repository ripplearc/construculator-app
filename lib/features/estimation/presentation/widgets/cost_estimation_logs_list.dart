import 'package:construculator/features/estimation/presentation/bloc/cost_estimation_log_bloc/cost_estimation_log_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_log_tile.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class CostEstimationLogsList extends StatefulWidget {
  final String estimateId;
  final String estimateName;

  final EdgeInsets? padding;

  const CostEstimationLogsList({
    super.key,
    required this.estimateId,
    required this.estimateName,
    this.padding,
  });

  @override
  State<CostEstimationLogsList> createState() => _CostEstimationLogsListState();
}

class _CostEstimationLogsListState extends State<CostEstimationLogsList> {
  final ScrollController _scrollController = ScrollController();

  static const double _loadMoreThreshold = 200.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<CostEstimationLogBloc>().add(
      CostEstimationLogFetchInitial(estimateId: widget.estimateId),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final bloc = context.read<CostEstimationLogBloc>();
    final state = bloc.state;

    if (state is! CostEstimationLogLoaded) return;
    if (!state.hasMore || state.isLoadingMore) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (maxScroll - currentScroll <= _loadMoreThreshold) {
      bloc.add(CostEstimationLogLoadMore(estimateId: widget.estimateId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: CoreSpacing.space4,
      children: [
        Container(
          decoration: BoxDecoration(
            boxShadow: CoreShadows.small,
            color: context.colorTheme.pageBackground,
          ),
          padding: EdgeInsets.symmetric(
            vertical: CoreSpacing.space3,
            horizontal: CoreSpacing.space4,
          ),
          child: Text(
            widget.estimateName,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleMediumSemiBold.copyWith(
              color: context.colorTheme.textHeadline,
            ),
          ),
        ),
        Flexible(
          fit: FlexFit.loose,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: CoreSpacing.space4),
            child: BlocConsumer<CostEstimationLogBloc, CostEstimationLogState>(
              listener: (context, state) {
                if (state is CostEstimationLogError) {
                  CoreToast.showError(
                    context,
                    _buildLogsErrorMessage(context, state.failure),
                    context.l10n.closeLabel,
                  );
                }

                if (state is CostEstimationLogLoadMoreError) {
                  CoreToast.showError(
                    context,
                    _buildLogsErrorMessage(
                      context,
                      state.failure,
                      isLoadMore: true,
                    ),
                    context.l10n.closeLabel,
                  );
                }
              },
              builder: (context, state) {
                if (state is CostEstimationLogLoading) {
                  return _buildLoadingState(context);
                }

                if (state is CostEstimationLogEmpty) {
                  return _buildRefreshable(child: _buildEmptyState(context));
                }

                if (state is CostEstimationLogWithData) {
                  return _buildRefreshable(
                    child: _buildLoadedState(context, state),
                  );
                }

                return _buildRefreshable(child: _buildEmptyState(context));
              },
            ),
          ),
        ),
        SizedBox(height: CoreSpacing.space2),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Center(child: CoreLoadingIndicator());
  }

  Widget _buildRefreshable({required Widget child}) {
    return RefreshIndicator.adaptive(
      onRefresh: _onRefresh,
      color: context.colorTheme.orientMid,
      child: child,
    );
  }

  Future<void> _onRefresh() async {
    final bloc = context.read<CostEstimationLogBloc>();
    bloc.add(CostEstimationLogFetchInitial(estimateId: widget.estimateId));
  }

  Widget _buildEmptyState(BuildContext context) {
    final appColors = context.colorTheme;
    final typography = context.textTheme;

    return CustomScrollView(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(CoreSpacing.space6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CoreIconWidget(icon: CoreIcons.emptyEstimation, size: 48),
                  SizedBox(height: CoreSpacing.space4),
                  Text(
                    context.l10n.noActivityLogs,
                    style: typography.titleMediumSemiBold.copyWith(
                      color: appColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: CoreSpacing.space2),
                  Text(
                    context.l10n.noActivityLogsDescription,
                    style: typography.bodyMediumRegular.copyWith(
                      color: appColors.textBody,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadedState(
    BuildContext context,
    CostEstimationLogWithData state,
  ) {
    return CustomScrollView(
      controller: _scrollController,
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            return Padding(
              padding: EdgeInsets.only(bottom: CoreSpacing.space4),
              child: CostEstimationLogTile(
                key: ValueKey(state.logs[index].id),
                log: state.logs[index],
              ),
            );
          }, childCount: state.logs.length),
        ),
        if (state.isLoadingMore)
          SliverToBoxAdapter(child: _buildLoadMoreIndicator(context)),
        if (state is CostEstimationLogLoadMoreError)
          SliverToBoxAdapter(child: _buildLoadMoreRetry(context)),
      ],
    );
  }

  Widget _buildLoadMoreIndicator(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: CoreSpacing.space4),
      child: Center(child: CoreLoadingIndicator(size: 24)),
    );
  }

  Widget _buildLoadMoreRetry(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: CoreSpacing.space4,
        right: CoreSpacing.space4,
        top: CoreSpacing.space2,
        bottom: CoreSpacing.space4,
      ),
      child: Center(
        child: CoreButton(
          label: context.l10n.retryButton,
          onPressed: () {
            context.read<CostEstimationLogBloc>().add(
              CostEstimationLogLoadMore(estimateId: widget.estimateId),
            );
          },
          variant: CoreButtonVariant.secondary,
          size: CoreButtonSize.small,
          fullWidth: false,
        ),
      ),
    );
  }

  String _mapFailureToMessage(BuildContext context, Failure failure) {
    final l10n = context.l10n;

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

  String _buildLogsErrorMessage(
    BuildContext context,
    Failure failure, {
    bool isLoadMore = false,
  }) {
    final l10n = context.l10n;
    final details = _mapFailureToMessage(context, failure);
    final prefix = isLoadMore ? l10n.loadMoreLogsError : l10n.errorLoadingLogs;
    return '$prefix: $details';
  }
}
