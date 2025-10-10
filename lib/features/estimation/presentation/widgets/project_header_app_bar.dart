import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:construculator/features/project_settings/domain/usecases/get_project_usecase.dart';
import 'package:construculator/features/project_settings/domain/entities/project_entity.dart';

class ProjectHeaderAppBar extends StatefulWidget
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
  State<ProjectHeaderAppBar> createState() => _ProjectHeaderAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _ProjectHeaderAppBarState extends State<ProjectHeaderAppBar> {
  Project? _project;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    try {
      final getProjectUseCase = Modular.get<GetProjectUseCase>();
      final result = await getProjectUseCase(widget.projectId);

      result.fold(
        (failure) {
          setState(() {
            _errorMessage = 'Failed to load project';
            _isLoading = false;
          });
        },
        (project) {
          setState(() {
            _project = project;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PhysicalModel(
      color: Colors.transparent,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.6),
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
              onTap: widget.onProjectTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: _buildProjectName()),
                  const SizedBox(width: 4),
                  CoreIconWidget(
                    icon: CoreIcons.arrowDown,
                    color: CoreIconColors.grayDark,
                    size: 20,
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                key: const Key('project_header_search_button'),
                onPressed: widget.onSearchTap,
                icon: CoreIconWidget(
                  icon: CoreIcons.search,
                  color: CoreIconColors.dark,
                ),
              ),
              IconButton(
                key: const Key('project_header_notification_button'),
                onPressed: widget.onNotificationTap,
                icon: CoreIconWidget(
                  icon: CoreIcons.notification,
                  color: CoreIconColors.dark,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 16, left: 8),
                child: CoreAvatar(
                  radius: 20,
                  backgroundColor: Colors.black,
                  // TODO: https://ripplearc.youtrack.cloud/issue/CA-392/Cost-Estimation-Use-letter-when-no-user-avatar-is-present
                  image: widget.avatarImage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectName() {
    if (_isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(CoreTextColors.dark),
        ),
      );
    }

    if (_errorMessage != null) {
      return Text(
        'Error loading project',
        style: CoreTypography.bodyLargeSemiBold(
          color: CoreTextColors.error,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    }

    return Text(
      _project?.projectName ?? 'Unknown Project',
      style: CoreTypography.bodyLargeSemiBold(
        color: CoreTextColors.dark,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}
