import 'package:construculator/features/project/presentation/bloc/get_project_bloc/get_project_bloc.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Shell header bar shown while a project is selected, with the project-name
/// selector, search, notification, and profile-avatar cluster.
///
/// Both bloc states render a [CoreAppBar] with the same geometry as
/// `TitleSearchAppBar`, so the shell's header slot keeps one height whether a
/// project is selected or not.
class ProjectHeaderAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  /// Creates the [GetProjectBloc] this bar owns for its lifetime.
  final GetProjectBloc Function() getProjectBlocFactory;

  /// Called when the project-name selector is tapped.
  final VoidCallback? onProjectTap;

  /// Called when the search icon is tapped.
  final VoidCallback? onSearchTap;

  /// Called when the notification icon is tapped.
  final VoidCallback? onNotificationTap;

  /// Creates a [ProjectHeaderAppBar].
  const ProjectHeaderAppBar({
    super.key,
    required this.getProjectBlocFactory,
    this.onProjectTap,
    this.onSearchTap,
    this.onNotificationTap,
  });

  // The content box the title and actions are laid out in. [CoreAppBar] adds
  // [_padding] around this rather than subtracting it from it, so every
  // control keeps a full 48x48 tap target in both bloc states (CA-822).
  static const double _height = CoreSpacing.space12;
  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: CoreSpacing.space4,
    vertical: CoreSpacing.space2,
  );

  @override
  Size get preferredSize => Size.fromHeight(_height + _padding.vertical);

  @override
  State<ProjectHeaderAppBar> createState() => _ProjectHeaderAppBarState();
}

class _ProjectHeaderAppBarState extends State<ProjectHeaderAppBar> {
  late final GetProjectBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = widget.getProjectBlocFactory();
    _bloc.add(const GetProjectWatchStarted());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appColorTheme = context.colorTheme;
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<GetProjectBloc, GetProjectState>(
        builder: (context, state) {
          if (state is GetProjectInitial) {
            return CoreAppBar(
              height: ProjectHeaderAppBar._height,
              padding: ProjectHeaderAppBar._padding,
              centerTitle: true,
              titleSpacing: 0,
              titleText: context.l10n.appTitle,
            );
          }
          return CoreAppBar(
            height: ProjectHeaderAppBar._height,
            padding: ProjectHeaderAppBar._padding,
            titleSpacing: 0,
            title: Semantics(
              label: context.l10n.projectDropdownSemanticLabel,
              button: widget.onProjectTap != null,
              child: SizedBox(
                height: ProjectHeaderAppBar._height,
                child: InkWell(
                  onTap: widget.onProjectTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: _buildProjectName()),
                      const SizedBox(width: 4),
                      CoreIconWidget(
                        icon: CoreIcons.arrowDown,
                        color: appColorTheme.iconGrayMid,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              CoreIconWidget(
                key: const Key('project_header_search_button'),
                icon: CoreIcons.search,
                size: 24,
                padding: const EdgeInsets.all(CoreSpacing.space3),
                onTap: widget.onSearchTap,
                color: appColorTheme.iconDark,
                semanticLabel: context.l10n.dashboardSearchSemanticLabel,
              ),
              CoreIconWidget(
                key: const Key('project_header_notification_button'),
                onTap: widget.onNotificationTap,
                icon: CoreIcons.notification,
                size: 24,
                padding: const EdgeInsets.all(CoreSpacing.space3),
                color: appColorTheme.iconDark,
                semanticLabel: context.l10n.notificationSemanticLabel,
              ),
              _buildAvatar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAvatar() {
    return BlocBuilder<GetProjectBloc, GetProjectState>(
      builder: (context, state) {
        final appColorTheme = context.colorTheme;

        final avatarImage = state is GetProjectByIdLoadSuccess
            ? state.userAvatarImage
            : null;

        return CoreAvatar(
          radius: 20,
          backgroundColor: appColorTheme.backgroundDarkGray,
          // TODO: https://ripplearc.youtrack.cloud/issue/CA-392/Cost-Estimation-Use-letter-when-no-user-avatar-is-present
          image: avatarImage,
        );
      },
    );
  }

  Widget _buildProjectName() {
    return BlocBuilder<GetProjectBloc, GetProjectState>(
      builder: (context, state) {
        final appColorTheme = context.colorTheme;
        final appTypographyTheme = context.textTheme;
        if (state is GetProjectByIdLoading || state is GetProjectInitial) {
          return SizedBox(width: 20, height: 20, child: CoreLoadingIndicator());
        }

        if (state is GetProjectByIdLoadSuccess) {
          return Text(
            state.project.projectName,
            style: appTypographyTheme.titleMediumSemiBold.copyWith(
              color: appColorTheme.textHeadline,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          );
        } else {
          final l10n = context.l10n;
          return Text(
            l10n.projectLoadError,
            style: appTypographyTheme.bodyLargeSemiBold.copyWith(
              color: appColorTheme.textError,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          );
        }
      },
    );
  }
}
