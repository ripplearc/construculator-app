import 'package:construculator/app/shell/widgets/notification_icon.dart';
import 'package:construculator/app/shell/widgets/profile_avatar.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

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

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;

    return PhysicalModel(
      color: colors.pageBackground,
      elevation: 0,
      borderRadius: BorderRadius.zero,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: CoreShadows.medium,
          color: colors.pageBackground,
        ),
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: CoreSpacing.space4),
        child: AppBar(
          backgroundColor: colors.pageBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 0,
          title: InkWell(
            onTap: onProjectTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    context.l10n.appTitle,
                    style: typography.titleMediumSemiBold.copyWith(
                      color: colors.textHeadline,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: CoreSpacing.space1),
                CoreIconWidget(
                  icon: CoreIcons.arrowDown,
                  color: colors.iconGrayMid,
                  size: CoreIconSize.size24,
                ),
              ],
            ),
          ),
          actions: [
            CoreIconWidget(
              key: const Key('header_row_search_button'),
              icon: CoreIcons.search,
              size: CoreIconSize.size24,
              padding: const EdgeInsets.all(CoreSpacing.space3),
              onTap: onSearchTap,
              color: colors.iconDark,
              semanticLabel: context.l10n.dashboardSearchSemanticLabel,
            ),
            NotificationIcon(
              key: const Key('header_row_notification_icon'),
              unreadCount: unreadNotificationCount,
              onTap: onNotificationTap,
            ),
            ProfileAvatar(
              key: const Key('header_row_profile_avatar'),
              name: userName,
              imageUrl: avatarImageUrl,
              onTap: onProfileTap,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
