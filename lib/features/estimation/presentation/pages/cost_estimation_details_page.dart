import 'package:flutter/material.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// A placeholder page for cost estimation details.
///
/// This page will be implemented in a future sprint.
/// TODO: https://ripplearc.youtrack.cloud/issue/CA-367/Cost-Estimation-Scaffold-Cost-Details-Section
class CostEstimationDetailsPage extends StatelessWidget {
  final String estimationId;

  const CostEstimationDetailsPage({super.key, required this.estimationId});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colorTheme = context.colorTheme;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Estimation Details',
          style: textTheme.bodyLargeSemiBold.copyWith(
            color: colorTheme.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CoreIconWidget(
                icon: CoreIcons.divide,
                size: 64,
                color: colorTheme.textDisable,
              ),
              const SizedBox(height: CoreSpacing.space8),
              Text(
                'Cost estimation details will be available in a future update.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLargeMedium,
              ),
              const SizedBox(height: CoreSpacing.space4),
              Text(
                'Estimation ID: $estimationId',
                style: textTheme.bodySmallMedium.copyWith(
                  color: colorTheme.textDisable,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
