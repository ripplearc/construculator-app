import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';

class ProjectHeaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String projectName;
  final VoidCallback? onProjectTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;
  final String? avatarUrl;

  const ProjectHeaderAppBar({
    super.key,
    required this.projectName,
    this.onProjectTap,
    this.onSearchTap,
    this.onNotificationTap,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return PhysicalModel(
      color: Colors.transparent,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      borderRadius: BorderRadius.zero,
      child: Container(
        color: CoreBackgroundColors.pageBackground,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            titleSpacing: 0,
            title: InkWell(
              onTap: onProjectTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    projectName,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: CoreTextColors.dark,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: CoreTextColors.dark,
                    size: 20,
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                onPressed: onSearchTap,
                icon: SizedBox(
                  width: 24,
                  height: 24,
                  child: Image.asset(
                    'assets/icons/search_icon.png',
                    package: null,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNotificationTap,
                icon: SizedBox(
                  width: 24,
                  height: 24,
                  child: Image.asset(
                    'assets/icons/bell_icon.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 16, left: 8),
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: (avatarUrl?.isNotEmpty ?? false)
                      ? NetworkImage(avatarUrl ?? '')
                      : const NetworkImage(
                          'https://via.placeholder.com/100'), // fallback
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
