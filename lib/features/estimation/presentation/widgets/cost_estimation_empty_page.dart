import 'package:ripplearc_coreui/ripplearc_coreui.dart';
import 'package:flutter/material.dart';

class CostEstimationEmptyPage extends StatelessWidget {
  final String message;
  final double? textWidthFactor;

  const CostEstimationEmptyPage({
    super.key,
    required this.message,
    this.textWidthFactor = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CoreIconWidget(icon: CoreIcons.emptyEstimation),
          const SizedBox(height: 24),
          SizedBox(
            width: MediaQuery.of(context).size.width * (textWidthFactor ?? 0.7),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .extension<AppTypographyExtension>()
                  ?.bodyMediumRegular
                  .copyWith(
                    color: Theme.of(
                      context,
                    ).extension<AppColorsExtension>()?.textHeadline,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
