import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_details_tab_view.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// A placeholder page for cost estimation details.
///
/// This page will be implemented in a future sprint.
class CostEstimationDetailsPage extends StatelessWidget {
  final String estimationId;

  const CostEstimationDetailsPage({super.key, required this.estimationId});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colorTheme = context.colorTheme;
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: colorTheme.pageBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 5),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: CoreShadows.medium,
            color: colorTheme.pageBackground,
          ),
          child: AppBar(
            backgroundColor: colorTheme.pageBackground,
            elevation: 0,
            centerTitle: false,
            titleSpacing: CoreSpacing.space1,
            leading: CoreIconWidget(
              key: const Key('back_button'),
              icon: CoreIcons.backspaceLeft,
              color: colorTheme.iconDark,
              padding: EdgeInsets.all(CoreSpacing.space4),
              size: 24,
              visualDensity: VisualDensity.compact,
              semanticLabel: l10n.backLabel,
              onTap: () {
                final router = Modular.get<AppRouter>();
                router.pop();
              },
            ),
            // TODO: [CA-154] [Cost Estimation] Implement Rename Estimation Logic https://ripplearc.youtrack.cloud/issue/CA-154/Cost-Estimation-Implement-Rename-Estimation-Logic
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    'Estimation Details',
                    style: textTheme.titleMediumSemiBold.copyWith(
                      color: colorTheme.textHeadline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                CoreIconWidget(
                  key: const Key('edit_estimation_name_icon'),
                  icon: CoreIcons.edit,
                  padding: EdgeInsets.all(CoreSpacing.space4),
                  color: colorTheme.iconDark,
                  semanticLabel: l10n.editEstimationNameLabel,
                ),
              ],
            ),
            actions: [
              CoreIconWidget(
                key: const Key('more_options_icon'),
                icon: CoreIcons.moreVert,
                size: 24,
                padding: EdgeInsets.all(CoreSpacing.space4),
                color: colorTheme.iconDark,
                semanticLabel: l10n.moreOptionsLabel,
              ),
            ],
          ),
        ),
      ),
      body: const CostEstimationDetailsTabView(),
      // TODO: [CA-155] [Cost Estimation] Implement Add Material Cost Logic https://ripplearc.youtrack.cloud/issue/CA-155/Cost-Estimation-Implement-Add-Material-Cost-Logic
      floatingActionButton: CoreButton(
        key: const Key('add_material_cost_button'),
        label: l10n.addMaterialCostButton,
        variant: CoreButtonVariant.secondary,
        icon: CoreIconWidget(icon: CoreIcons.add),
        size: CoreButtonSize.medium,
        fullWidth: false,
        onPressed: () {},
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: CoreSpacing.space4,
            vertical: CoreSpacing.space2,
          ),
          decoration: BoxDecoration(
            boxShadow: CoreShadows.sticky,
            color: colorTheme.pageBackground,
          ),
          child: Row(
            spacing: CoreSpacing.space4,
            children: [
              // TODO: [CA-160] [Cost Estimation] Implement Lock/Unlock Button Logic
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colorTheme.lineLight),
                ),
                child: CoreIconWidget(
                  key: const Key('lock_icon'),
                  icon: CoreIcons.lock,
                  size: 24,
                  padding: EdgeInsets.all(CoreSpacing.space3),
                  color: colorTheme.iconDark,
                  semanticLabel: l10n.lockLabel,
                ),
              ),
              // TODO: [CA-186] [Cost Estimation] Implement Preview Button Logic https://ripplearc.youtrack.cloud/issue/CA-186/Cost-Estimation-Implement-Preview-Button-Logic
              Expanded(
                child: CoreButton(
                  key: const Key('preview_button'),
                  label: l10n.previewButton,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
