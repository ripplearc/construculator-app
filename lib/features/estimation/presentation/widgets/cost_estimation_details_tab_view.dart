import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// A tabbed view displaying cost estimation details for Materials, Labours, and Equipments.
///
/// Shows empty states with appropriate messages when no costs have been added for each category.
class CostEstimationDetailsTabView extends StatefulWidget {
  const CostEstimationDetailsTabView({super.key});

  @override
  State<CostEstimationDetailsTabView> createState() =>
      _CostEstimationDetailsTabViewState();
}

class _CostEstimationDetailsTabViewState
    extends State<CostEstimationDetailsTabView> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    final l10n = context.l10n;

    return Column(
      key: const Key('cost_estimation_details_tab_view'),
      children: [
        Row(
          children: [
            Expanded(
              child: CoreTabs(
                key: const Key('cost_tabs'),
                tabs: [l10n.materialsTab, l10n.laboursTab, l10n.equipmentsTab],
                selectedIndex: _selectedIndex,
                onChanged: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
              ),
            ),
            SizedBox(width: CoreSpacing.space4),
            // TODO: [CA-188] [Cost Estimation] Implement Comment Button Logic https://ripplearc.youtrack.cloud/issue/CA-188/Cost-Estimation-Implement-Comment-Button-Logic
            CoreIconWidget(
              key: const Key('comment_icon'),
              icon: CoreIcons.message,
              color: colorTheme.iconDark,
              size: 24,
              semanticLabel: l10n.commentLabel,
            ),
          ],
        ),
        Expanded(
          // TODO: [CA-151] [Cost Estimation] Bind Data to Cost Estimation Details Screen https://ripplearc.youtrack.cloud/issue/CA-151/Cost-Estimation-Bind-Data-to-Cost-Estimation-Details-Screen
          child: IndexedStack(
            key: const Key('tab_content_stack'),
            index: _selectedIndex,
            children: [
              _buildEmptyState(
                keyPrefix: 'materials_empty_state',
                message: l10n.noMaterialCostMessage,
                colorTheme: colorTheme,
                textTheme: textTheme,
              ),
              _buildEmptyState(
                keyPrefix: 'labours_empty_state',
                message: l10n.noLabourCostMessage,
                colorTheme: colorTheme,
                textTheme: textTheme,
              ),
              _buildEmptyState(
                keyPrefix: 'equipments_empty_state',
                message: l10n.noEquipmentCostMessage,
                colorTheme: colorTheme,
                textTheme: textTheme,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required String keyPrefix,
    required String message,
    required AppColorsExtension colorTheme,
    required AppTypographyExtension textTheme,
  }) {
    return Center(
      key: Key(keyPrefix),
      child: Padding(
        padding: const EdgeInsets.all(CoreSpacing.space6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CoreIconWidget(
              key: Key('${keyPrefix}_icon'),
              icon: CoreIcons.emptyEstimation,
              size: 200,
            ),
            SizedBox(height: CoreSpacing.space6),
            Text(
              message,
              key: Key('${keyPrefix}_message'),
              style: textTheme.bodyMediumRegular.copyWith(
                color: colorTheme.textBody,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
