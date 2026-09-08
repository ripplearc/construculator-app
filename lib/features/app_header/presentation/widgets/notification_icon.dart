import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Bell icon button with an unread-count badge; displays "99+" when count exceeds 99.
class NotificationIcon extends StatelessWidget {
  final int unreadCount;
  final VoidCallback? onTap;

  const NotificationIcon({
    super.key,
    this.unreadCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CoreIconWidget(
          key: const Key('notification_icon_button'),
          icon: CoreIcons.notification,
          size: CoreIconSize.size24,
          color: colors.iconDark,
          padding: const EdgeInsets.all(CoreSpacing.space3),
          semanticLabel: context.l10n.notificationSemanticLabel,
          onTap: onTap,
        ),
        if (unreadCount > 0)
          Positioned(
            right: CoreSpacing.space1,
            top: CoreSpacing.space1,
            child: Container(
              key: const Key('notification_badge'),
              constraints: const BoxConstraints(
                minWidth: CoreSpacing.space4,
                minHeight: CoreSpacing.space4,
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(
                horizontal: CoreSpacing.space1,
              ),
              decoration: BoxDecoration(
                color: colors.statusError,
                borderRadius: BorderRadius.circular(CoreSpacing.space2),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: context.textTheme.bodySmallSemiBold.copyWith(
                  color: colors.textInverse,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
