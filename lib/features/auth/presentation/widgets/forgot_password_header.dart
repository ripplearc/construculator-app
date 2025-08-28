import 'package:core_ui/core_ui.dart';
import 'package:flutter/widgets.dart';

class ForgotPasswordHeader extends StatelessWidget {
  final String title;
  final String description;
  const ForgotPasswordHeader({super.key, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: CoreTypography.headlineLargeSemiBold(),
        ),
        const SizedBox(height: CoreSpacing.space2),
        Text(
          description,
          style: CoreTypography.bodyLargeRegular(),
        ),
      ],
    );
  }
}
