import 'package:construculator/features/project_settings/presentation/widgets/project_action_area.dart';
import 'package:construculator/features/project_settings/presentation/widgets/project_name_text_field.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/features/project_settings/presentation/bloc/project_settings_bloc/project_settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Full-page form for creating a new project (DASH-023).
///
/// Connects [ProjectNameTextField] and [ProjectActionArea]. Dispatches
/// [ProjectSettingsCreationRequested] on submission and navigates back on
/// [ProjectSettingsCreated].
// TODO: [CA-733] Add CostFileSection
// TODO: [CA-734] Add ExportFolderSection
class ProjectCreationScreen extends StatefulWidget {
  final AuthManager authManager;

  const ProjectCreationScreen({super.key, required this.authManager});

  @override
  State<ProjectCreationScreen> createState() => _ProjectCreationScreenState();
}

class _ProjectCreationScreenState extends State<ProjectCreationScreen> {
  final TextEditingController _nameController = TextEditingController();

  bool _nameValid = false;

  bool get _canSubmit => _nameValid;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    context.read<ProjectSettingsBloc>().add(
      ProjectSettingsCreationRequested(
        name: _nameController.text.trim(),
        // TODO: [CA-175] Pass description once AddDescriptionSheet is implemented
        description: null,
        creatorUserId: widget.authManager.getCurrentCredentials().data?.id,
        exportStorageProvider: null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProjectSettingsBloc, ProjectSettingsState>(
      listener: (context, state) {
        if (state is ProjectSettingsCreated) {
          Navigator.of(context).pop();
        } else if (state is ProjectSettingsError) {
          CoreToast.showError(
            context,
            context.l10n.unexpectedErrorMessage,
            context.l10n.continueButton,
          );
        }
      },
      child: Scaffold(
        backgroundColor: context.colorTheme.pageBackground,
        appBar: _buildAppBar(context),
        body: _buildBody(context),
        bottomNavigationBar: _buildSubmitButton(context),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;
    final l10n = context.l10n;

    return AppBar(
      backgroundColor: colors.pageBackground,
      elevation: 2,
      shadowColor: colors.shadowGrey10,
      surfaceTintColor: colors.transparent,
      scrolledUnderElevation: 0,
      titleSpacing: CoreSpacing.space1,
      leading: CoreIconWidget(
        icon: const CoreIconData.material(Icons.arrow_back),
        size: CoreIconSize.size24,
        color: colors.iconDark,
        padding: const EdgeInsets.all(CoreSpacing.space4),
        visualDensity: VisualDensity.compact,
        semanticLabel: l10n.backLabel,
        onTap: () => Navigator.of(context).pop(),
      ),
      title: Text(
        l10n.createProjectScreenTitle,
        style: typography.titleLargeSemiBold.copyWith(color: colors.textHeadline),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        CoreSpacing.space4,
        CoreSpacing.space6,
        CoreSpacing.space4,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProjectNameTextField(
            controller: _nameController,
            onValidationChanged: (v) => setState(() => _nameValid = v),
          ),
          const SizedBox(height: CoreSpacing.space4),
          const ProjectActionArea(),
          const SizedBox(height: CoreSpacing.space20),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    final l10n = context.l10n;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(CoreSpacing.space4),
        child: BlocBuilder<ProjectSettingsBloc, ProjectSettingsState>(
          builder: (context, state) => CoreButton(
            key: const Key('create_project_button'),
            label: l10n.createProjectButton,
            isDisabled: !_canSubmit || state is ProjectSettingsCreating,
            onPressed: _onSubmit,
          ),
        ),
      ),
    );
  }
}
