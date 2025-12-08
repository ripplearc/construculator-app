import 'package:flutter/material.dart';
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: CoreIconWidget(icon: CoreIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Estimation Details',
          style: CoreTypography.bodyLargeSemiBold(color: CoreTextColors.dark),
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
                color: CoreTextColors.disable,
              ),
              const SizedBox(height: CoreSpacing.space8),
              Text(
                'Cost estimation details will be available in a future update.',
                textAlign: TextAlign.center,
                style: CoreTypography.bodyLargeMedium(
                  color: CoreTextColors.body,
                ),
              ),
              const SizedBox(height: CoreSpacing.space4),
              Text(
                'Estimation ID: $estimationId',
                style: CoreTypography.bodySmallMedium(
                  color: CoreTextColors.disable,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
