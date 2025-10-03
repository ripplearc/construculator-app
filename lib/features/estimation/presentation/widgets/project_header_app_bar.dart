import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:construculator/features/project_settings/domain/usecases/get_project_usecase.dart';
import 'package:construculator/features/project_settings/domain/entities/project_entity.dart';

class ProjectHeaderAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String projectId;
  final VoidCallback? onProjectTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;
  final String? avatarUrl;

  const ProjectHeaderAppBar({
    super.key,
    required this.projectId,
    this.onProjectTap,
    this.onSearchTap,
    this.onNotificationTap,
    this.avatarUrl,
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
              onTap: widget.onProjectTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: _buildProjectName(),
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
                onPressed: widget.onSearchTap,
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
                onPressed: widget.onNotificationTap,
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
                  backgroundColor: Colors.black,
                  backgroundImage: (widget.avatarUrl?.isNotEmpty ?? false)
                      ? NetworkImage(widget.avatarUrl ?? '')
                      : null,
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
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: Colors.red,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    }

    return Text(
      _project?.projectName ?? 'Unknown Project',
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: CoreTextColors.dark,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}
