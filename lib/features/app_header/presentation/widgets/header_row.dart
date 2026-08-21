import 'package:construculator/features/app_header/presentation/widgets/notification_icon.dart';
import 'package:construculator/features/app_header/presentation/widgets/profile_avatar.dart';
import 'package:construculator/features/app_header/presentation/widgets/project_selector_title.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// App-shell header for the home tab, showing the project selector, search,
/// notification badge, and profile avatar.
class HeaderRow extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final String? avatarImageUrl;
  final int unreadNotificationCount;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onProjectTap;

  const HeaderRow({
    super.key,
    this.userName = '',
    this.avatarImageUrl,
    this.unreadNotificationCount = 0,
    this.onSearchTap,
    this.onNotificationTap,
    this.onProfileTap,
    this.onProjectTap,
  });

  static const double _height = CoreSpacing.space12;
  static const EdgeInsets _padding = EdgeInsets.only(
    left: CoreSpacing.space1,
    right: CoreSpacing.space4,
    top: CoreSpacing.space2,
    bottom: CoreSpacing.space2,
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;

    return CoreAppBar(
      height: _height,
      padding: _padding,
      titleSpacing: 0,
      title: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: CoreSpacing.space12,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CoreSpacing.space3,
                ),
                child: ProjectSelectorTitle(
                  selectorKey: const Key('header_row_project_selector'),
                  onProjectTap: onProjectTap,
                  textStyle: typography.titleMediumSemiBold.copyWith(
                    color: colors.textHeadline,
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CoreIconWidget(
                key: const Key('header_row_search_button'),
                icon: CoreIcons.search,
                size: CoreIconSize.size24,
                padding: const EdgeInsets.all(CoreSpacing.space3),
                onTap: onSearchTap,
                color: colors.iconDark,
                semanticLabel: context.l10n.dashboardSearchSemanticLabel,
              ),
              const SizedBox(width: CoreSpacing.space2),
              NotificationIcon(
                key: const Key('header_row_notification_icon'),
                unreadCount: unreadNotificationCount,
                onTap: onNotificationTap,
              ),
              const SizedBox(width: CoreSpacing.space2),
              ProfileAvatar(
                key: const Key('header_row_profile_avatar'),
                name: userName,
                imageUrl: avatarImageUrl,
                onTap: onProfileTap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(_height + _padding.vertical);
}
