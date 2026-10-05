import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// The dark "Added to Bedroom 2" toast shown after a cost line is added.
// TODO: [CA-1256] use a CoreUI dark success toast instead of these hardcoded numbers. https://ripplearc.youtrack.cloud/issue/CA-1256
class AddedToEstimateToast extends StatelessWidget {
  // ignore: avoid_static_colors
  static const _fill = Color(0xFF1D2939);
  // ignore: avoid_static_colors
  static const _onFill = Color(0xFFFFFFFF);

  final String message;

  const AddedToEstimateToast({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _fill,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                // ignore: avoid_static_colors
                color: Color(0x47101828),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: const BoxDecoration(
                    // ignore: avoid_static_colors
                    color: Color(0xFF009E69),
                    shape: BoxShape.circle,
                  ),
                  child: CoreIconWidget(
                    icon: CoreIcons.checkMark,
                    size: CoreIconSize.size24,
                    color: _onFill,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    message,
                    style: context.textTheme.bodyMediumSemiBold.copyWith(
                      color: _onFill,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
