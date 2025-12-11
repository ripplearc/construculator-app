import 'package:construculator/features/project/presentation/bloc/get_project_bloc/get_project_bloc.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class ProjectHeaderAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String projectId;
  final VoidCallback? onProjectTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;
  final ImageProvider? avatarImage;

  const ProjectHeaderAppBar({
    super.key,
    required this.projectId,
    this.onProjectTap,
    this.onSearchTap,
    this.onNotificationTap,
    this.avatarImage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColorTheme = theme.extension<AppColorsExtension>();
    return BlocProvider.value(
      value: Modular.get<GetProjectBloc>()
        ..add(GetProjectByIdLoadRequested(projectId)),
      child: Builder(
        builder: (context) {
          return PhysicalModel(
            color: appColorTheme?.pageBackground ?? theme.colorScheme.surface,
            elevation: 0,
            borderRadius: BorderRadius.zero,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: CoreShadows.medium,
                color: appColorTheme?.pageBackground,
              ),
              height: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: CoreSpacing.space2,
                horizontal: CoreSpacing.space4,
              ),
              child: AppBar(
                backgroundColor: appColorTheme?.pageBackground,
                elevation: 0,
                titleSpacing: 0,
                title: InkWell(
                  onTap: onProjectTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: _buildProjectName()),
                      const SizedBox(width: 4),
                      CoreIconWidget(
                        icon: CoreIcons.arrowDown,
                        color: appColorTheme?.iconGrayMid,
                        size: 24,
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    key: const Key('project_header_search_button'),
                    onPressed: onSearchTap,
                    icon: CoreIconWidget(
                      icon: CoreIcons.search,
                      size: 24,
                      color: appColorTheme?.iconDark,
                    ),
                  ),
                  IconButton(
                    key: const Key('project_header_notification_button'),
                    onPressed: onNotificationTap,
                    icon: CoreIconWidget(
                      icon: CoreIcons.notification,
                      size: 24,
                      color: appColorTheme?.iconDark,
                    ),
                  ),
                  SizedBox(width: CoreSpacing.space2),
                  CoreAvatar(
                    radius: 20,
                    backgroundColor: appColorTheme?.backgroundDarkGray,
                    // TODO: https://ripplearc.youtrack.cloud/issue/CA-392/Cost-Estimation-Use-letter-when-no-user-avatar-is-present
                    image: avatarImage,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProjectName() {
    return BlocBuilder<GetProjectBloc, GetProjectState>(
      builder: (context, state) {
        final appColorTheme = Theme.of(context).extension<AppColorsExtension>();
        final appTypographyTheme = Theme.of(
          context,
        ).extension<TypographyExtension>();
        if (state is GetProjectByIdLoading || state is GetProjectInitial) {
          return SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: appColorTheme?.textDark,
            ),
          );
        }

        if (state is GetProjectByIdLoadSuccess) {
          return Text(
            state.project.projectName,
            style: appTypographyTheme?.titleMediumSemiBold.copyWith(
              color: appColorTheme?.textHeadline,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          );
        } else {
          final l10n = AppLocalizations.of(context);
          return Text(
            l10n?.projectLoadError ?? 'Unable to load project',
            style: appTypographyTheme?.bodyLargeSemiBold.copyWith(
              color: appColorTheme?.textError,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          );
        }
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
