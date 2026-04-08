import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Empty state shown in the [GlobalSearchPage] when the user has no recent
/// searches.
class GlobalSearchEmptyRecentWidget extends StatelessWidget {
  const GlobalSearchEmptyRecentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/icons/search_icon.png',
            width: CoreSpacing.space32,
            height: CoreSpacing.space32,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox(width: CoreSpacing.space32, height: CoreSpacing.space32),
          ),
          const SizedBox(height: CoreSpacing.space6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CoreSpacing.space10),
            child: Text(
              context.l10n.globalSearchEmptyRecentMessage,
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
