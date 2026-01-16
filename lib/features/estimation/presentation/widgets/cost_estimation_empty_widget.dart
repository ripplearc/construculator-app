import 'package:ripplearc_coreui/ripplearc_coreui.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';

class CostEstimationEmptyWidget extends StatelessWidget {
  final String message;

  const CostEstimationEmptyWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CoreIconWidget(icon: CoreIcons.emptyEstimation),
          const SizedBox(height: 24),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMediumRegular.copyWith(
                color: context.colorTheme.textHeadline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
