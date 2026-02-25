import 'package:construculator/features/estimation/presentation/bloc/rename_estimation_bloc/rename_estimation_bloc.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class EstimationRenameSheet extends StatefulWidget {
  const EstimationRenameSheet({
    super.key,
    required this.estimationId,
    required this.projectId,
  });

  final String estimationId;
  final String projectId;

  @override
  State<EstimationRenameSheet> createState() => _EstimationRenameSheetState();
}

class _EstimationRenameSheetState extends State<EstimationRenameSheet> {
  late final TextEditingController _nameController;
  late final RenameEstimationBloc _bloc;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bloc = BlocProvider.of<RenameEstimationBloc>(context);
    _nameController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onTextChanged);
    _nameController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _bloc.add(RenameEstimationTextChanged(_nameController.text));
  }

  void _handleSave() {
    _bloc.add(
      RenameEstimationRequested(
        estimationId: widget.estimationId,
        newName: _nameController.text,
        projectId: widget.projectId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final typographyTheme = context.textTheme;
    final l10n = context.l10n;

    return BlocListener<RenameEstimationBloc, RenameEstimationState>(
      listener: (context, state) {
        if (state is RenameEstimationSuccess) {
          final router = Modular.get<AppRouter>();
          router.pop();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorTheme.pageBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + CoreSpacing.space4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(CoreSpacing.space4),
              child: Center(
                child: Container(
                  width: CoreSpacing.space10,
                  height: CoreSpacing.space1,
                  decoration: BoxDecoration(
                    color: colorTheme.textDisable,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: CoreSpacing.space3,
                horizontal: CoreSpacing.space4,
              ),
              child: Text(
                l10n.addCostName,
                style: typographyTheme.titleMediumSemiBold.copyWith(
                  color: colorTheme.textHeadline,
                ),
              ),
            ),
            SizedBox(height: CoreSpacing.space3),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: CoreSpacing.space3,
                horizontal: CoreSpacing.space4,
              ),
              child: CoreTextField(
                controller: _nameController,
                label: l10n.estimationNameLabel,
              ),
            ),
            SizedBox(height: CoreSpacing.space6),
            Container(
              decoration: BoxDecoration(
                boxShadow: CoreShadows.sticky,
                color: colorTheme.pageBackground,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: CoreSpacing.space4,
                vertical: CoreSpacing.space3,
              ),
              child: BlocBuilder<RenameEstimationBloc, RenameEstimationState>(
                builder: (context, state) {
                  final isLoading = state is RenameEstimationInProgress;
                  return CoreButton(
                    onPressed: isLoading ? null : _handleSave,
                    isDisabled: isLoading || !state.isSaveEnabled,
                    label: l10n.saveCostNameButton,
                    variant: CoreButtonVariant.primary,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
