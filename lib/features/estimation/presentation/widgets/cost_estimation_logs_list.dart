import 'package:construculator/features/estimation/presentation/bloc/cost_estimation_log_bloc/cost_estimation_log_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_log_tile.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class CostEstimationLogsList extends StatefulWidget {
  static const errorViewKey = Key('cost_estimation_logs_error_view');
  static const errorRetryButtonKey = Key('cost_estimation_logs_error_retry');
  static const loadMoreErrorViewKey = Key(
    'cost_estimation_logs_load_more_error_view',
  );
  static const loadMoreRetryButtonKey = Key(
    'cost_estimation_logs_load_more_retry',
  );
  static const logsScrollViewKey = Key('cost_estimation_logs_scroll_view');

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

  /// Distance in pixels from the bottom of the scroll extent at which
  /// the next page of logs should be loaded. A value of 200.0 provides
  /// a smooth user experience by preloading content before reaching the end.
  static const double _loadMoreScrollThreshold = 200.0;

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
    if (!mounted) return;
    if (!_scrollController.hasClients) return;

    final bloc = context.read<CostEstimationLogBloc>();
    final state = bloc.state;

    if (state is! CostEstimationLogLoaded) return;
    if (!state.hasMore || state.isLoadingMore) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (maxScroll - currentScroll <= _loadMoreScrollThreshold) {
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
        _buildHeader(context),
        Flexible(
          fit: FlexFit.loose,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: CoreSpacing.space4),
            child: BlocBuilder<CostEstimationLogBloc, CostEstimationLogState>(
              builder: (context, state) {
                if (state is CostEstimationLogLoading) {
                  return _buildLoadingState();
                }

                if (state is CostEstimationLogEmpty) {
                  return _buildRefreshable(child: _buildEmptyState(context));
                }

                if (state is CostEstimationLogError) {
                  return _buildErrorState(context, state);
                }

                // CostEstimationLogLoadMoreError extends CostEstimationLogWithData,
                // so it will be handled here while still showing the list with data
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

  // "Logs", then the estimate and the list order (CUJ 11 screen 5). A long
  // name is cut with an ellipsis, and "newest first" stays whole.
  Widget _buildHeader(BuildContext context) {
    final appColors = context.colorTheme;
    final typography = context.textTheme;
    final orderStyle = typography.bodySmallRegular.copyWith(
      color: appColors.textBody,
    );

    return BlocBuilder<CostEstimationLogBloc, CostEstimationLogState>(
      builder: (context, state) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: CoreSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: CoreSpacing.space4,
          children: [
            Text(
              context.l10n.logsAction,
              style: typography.titleMediumSemiBold.copyWith(
                color: appColors.textHeadline,
              ),
            ),
            Row(
              spacing: CoreSpacing.space2,
              children: [
                Flexible(
                  child: Text(
                    widget.estimateName,
                    overflow: TextOverflow.ellipsis,
                    style: orderStyle,
                  ),
                ),
                if (state is! CostEstimationLogEmpty) ...[
                  Container(
                    width: CoreSpacing.space1,
                    height: CoreSpacing.space1,
                    decoration: BoxDecoration(
                      color: appColors.lineDarkOutline,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(context.l10n.logsNewestFirst, style: orderStyle),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
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
    // Intentionally fire-and-forget: the RefreshIndicator dismisses immediately.
    // Loading feedback is provided by BlocBuilder transitioning through
    // CostEstimationLogLoading → CostEstimationLogWithData/Empty states.
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
        SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(CoreSpacing.space8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CoreIconWidget(icon: CoreIcons.emptyEstimation, size: 48),
                  const SizedBox(height: CoreSpacing.space4),
                  Text(
                    context.l10n.noActivityLogs,
                    style: typography.titleMediumSemiBold.copyWith(
                      color: appColors.textHeadline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: CoreSpacing.space2),
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

  // Sized to its content, so the sheet grows to fit the message (CUJ 11
  // screen 3) instead of filling to its height cap.
  Widget _buildErrorState(BuildContext context, CostEstimationLogError state) {
    final l10n = context.l10n;

    return Center(
      key: CostEstimationLogsList.errorViewKey,
      heightFactor: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: CoreSpacing.space10),
        child: _buildFailureNotice(
          context,
          message: state.isRepeatFailure
              ? l10n.errorLoadingLogsRepeat
              : l10n.errorLoadingLogs,
          retryButtonKey: CostEstimationLogsList.errorRetryButtonKey,
          onRetry: () {
            context.read<CostEstimationLogBloc>().add(
              CostEstimationLogFetchInitial(estimateId: widget.estimateId),
            );
          },
        ),
      ),
    );
  }

  // The failure block shared by the first load and the load of older events:
  // what failed, that the estimate is safe, and a way to try again.
  Widget _buildFailureNotice(
    BuildContext context, {
    required String message,
    required Key retryButtonKey,
    required VoidCallback onRetry,
  }) {
    final appColors = context.colorTheme;
    final typography = context.textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CoreIconWidget(
              icon: CoreIcons.error,
              size: CoreIconSize.size16,
              color: appColors.textError,
            ),
            const SizedBox(width: CoreSpacing.space2),
            Flexible(
              // Announced when it appears. Focus stays on Try again while the
              // result swaps in, so a screen reader would not otherwise hear
              // that the load failed.
              child: Semantics(
                liveRegion: true,
                child: Text(
                  message,
                  style: typography.bodySmallRegular.copyWith(
                    color: appColors.textError,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: CoreSpacing.space3),
        Text(
          context.l10n.logsLoadErrorReassurance,
          style: typography.bodySmallRegular.copyWith(
            color: appColors.textBody,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: CoreSpacing.space3),
        CoreButton(
          key: retryButtonKey,
          label: context.l10n.retryLoadLogsButton,
          onPressed: onRetry,
          variant: CoreButtonVariant.secondary,
          fullWidth: false,
        ),
      ],
    );
  }

  Widget _buildLoadedState(
    BuildContext context,
    CostEstimationLogWithData state,
  ) {
    return CustomScrollView(
      key: CostEstimationLogsList.logsScrollViewKey,
      controller: _scrollController,
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: CoreSpacing.space3),
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
          SliverToBoxAdapter(child: _buildLoadMoreFailure(context, state)),
      ],
    );
  }

  Widget _buildLoadMoreIndicator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CoreSpacing.space4),
      child: Center(child: CoreLoadingIndicator(size: 24)),
    );
  }

  Widget _buildLoadMoreFailure(
    BuildContext context,
    CostEstimationLogLoadMoreError state,
  ) {
    final l10n = context.l10n;

    return Padding(
      key: CostEstimationLogsList.loadMoreErrorViewKey,
      padding: const EdgeInsets.only(
        top: CoreSpacing.space5,
        bottom: CoreSpacing.space4,
      ),
      child: _buildFailureNotice(
        context,
        message: state.isRepeatFailure
            ? l10n.loadMoreLogsRepeatError
            : l10n.loadMoreLogsError,
        retryButtonKey: CostEstimationLogsList.loadMoreRetryButtonKey,
        onRetry: () {
          context.read<CostEstimationLogBloc>().add(
            CostEstimationLogLoadMore(estimateId: widget.estimateId),
          );
        },
      ),
    );
  }
}
