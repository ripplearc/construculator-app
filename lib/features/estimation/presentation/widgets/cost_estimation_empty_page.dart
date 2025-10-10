import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

class CostEstimationEmptyPage extends StatelessWidget {
  final String message;
  final String iconPath;
  final double? iconWidth;
  final double? iconHeight;
  final double? textWidthFactor;

  const CostEstimationEmptyPage({
    super.key,
    required this.message,
    this.iconPath = 'assets/icons/empty_state_icon.png',
    this.iconWidth = 140,
    this.iconHeight = 112.5,
    this.textWidthFactor = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            iconPath,
            width: iconWidth ?? 140,
            height: iconHeight ?? 112.5,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: MediaQuery.of(context).size.width * (textWidthFactor ?? 0.7),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: CoreTextColors.body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
