import 'package:construculator/app/shell/widgets/notification_icon.dart';
import 'package:construculator/app/shell/widgets/profile_avatar.dart';
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
        padding: const EdgeInsets.only(
          left: CoreSpacing.space1,
          right: CoreSpacing.space4,
        ),
        child: AppBar(
          backgroundColor: colors.pageBackground,
          // elevation/scrolledUnderElevation are 0 intentionally — shadow comes
          // from the outer Container's BoxDecoration to avoid a double-shadow.
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 0,
          toolbarHeight: CoreSpacing.space16,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Expanded(
                child: Semantics(
                  label: context.l10n.projectDropdownSemanticLabel,
                  button: true,
                  child: InkWell(
                    onTap: onProjectTap,
                    child: SizedBox(
                      height: CoreSpacing.space12,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: CoreSpacing.space3,
                        ),
                        child: Row(
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
                              icon: CoreIcons.arrowDropDown,
                              color: colors.iconGrayMid,
                              size: CoreIconSize.size24,
                            ),
                          ],
                        ),
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
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(CoreSpacing.space16);
}
