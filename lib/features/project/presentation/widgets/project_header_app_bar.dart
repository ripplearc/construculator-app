import 'dart:async';

import 'package:construculator/features/project/presentation/bloc/get_project_bloc/get_project_bloc.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class ProjectHeaderAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onProjectTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;

  const ProjectHeaderAppBar({
    super.key,
    this.onProjectTap,
    this.onSearchTap,
    this.onNotificationTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<ProjectHeaderAppBar> createState() => _ProjectHeaderAppBarState();
}

class _ProjectHeaderAppBarState extends State<ProjectHeaderAppBar> {
  late final GetProjectBloc _bloc;
  late final CurrentProjectNotifier _notifier;
  StreamSubscription<String?>? _subscription;

  @override
  void initState() {
    super.initState();
    _bloc = Modular.get<GetProjectBloc>();
    _notifier = Modular.get<CurrentProjectNotifier>();

    final initialId = _notifier.currentProjectId;
    if (initialId != null && initialId.isNotEmpty) {
      _bloc.add(GetProjectByIdLoadRequested(initialId));
    }

    _subscription = _notifier.onCurrentProjectChanged.listen((projectId) {
      if (projectId != null && projectId.isNotEmpty) {
        _bloc.add(GetProjectByIdLoadRequested(projectId));
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appColorTheme = context.colorTheme;
    return BlocProvider.value(
      value: _bloc,
      child: Builder(
        builder: (context) {
          return PhysicalModel(
            color: appColorTheme.pageBackground,
            elevation: 0,
            borderRadius: BorderRadius.zero,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: CoreShadows.medium,
                color: appColorTheme.pageBackground,
              ),
              height: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: CoreSpacing.space4),
              child: AppBar(
                backgroundColor: appColorTheme.pageBackground,
                elevation: 0,
                scrolledUnderElevation: 0,
                titleSpacing: 0,
                title: InkWell(
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
                actions: [
                  CoreIconWidget(
                    key: const Key('project_header_search_button'),
                    icon: CoreIcons.search,
                    size: 24,
                    padding: const EdgeInsets.all(CoreSpacing.space3),
                    onTap: widget.onSearchTap,
                    color: appColorTheme.iconDark,
                  ),
                  CoreIconWidget(
                    key: const Key('project_header_notification_button'),
                    onTap: widget.onNotificationTap,
                    icon: CoreIcons.notification,
                    size: 24,
                    padding: const EdgeInsets.all(CoreSpacing.space3),
                    color: appColorTheme.iconDark,
                  ),
                  _buildAvatar(),
                ],
              ),
            ),
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
