import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Which color treatment a [RateStatusBadge] renders.
enum RateStatusBadgeVariant {
  /// Peach fill, peach stroke, burnt-orange text. Used by the Rate/Amount
  /// field's "Sample rate" badge and the delivery row's "Estimated" badge —
  /// same component, different label text.
  orange,

  /// Mint fill, no stroke, dark-green text. Used by the Rate/Amount field's
  /// "✓ Your rate" badge.
  green,
}

/// A small pill-shaped status tag matching the Figma "Rate Status"
/// component set (node `65685:147068`) exactly:
/// - orange: fill `#FFF0E9` (`colorTheme.backgroundOrangeMid`), stroke
///   `#F7B999`, text `#CD5000` (`colorTheme.textWarning`).
/// - green: fill `#CFFCE4` (`colorTheme.backgroundGreenMid`), no stroke,
///   text `#007E57` (`colorTheme.textSuccess`).
///
/// Both variants: corner radius 8, SF Pro weight 590 at 12px — the closest
/// available step in this app's type scale is `bodySmallSemiBold` (w600),
/// used here rather than `bodySmallMedium` (w500) since 590 sits much
/// closer to 600 than 500.
///
/// One widget, not two: the orange variant is visually identical between
/// the Rate/Amount field's "Sample rate" badge and the delivery row's
/// "Estimated" badge (fix 6a/1 of the CA-1144 retrofit) — only the label
/// text differs, so callers pass their own [label].
///
/// a11y note: `#CD5000` text on `#FFF0E9` fill measures ~3.98:1 contrast,
/// short of WCAG AA's 4.5:1 minimum for 12px text (it would only need 3:1
/// if this counted as "large text", which 12px does not, bold or not). This
/// is the exact pairing the live Figma component specifies, confirmed
/// directly rather than inferred — see this pass's PR description for the
/// full account of why the Figma spec was kept as-is despite the failure.
/// The green variant passes AA at ~4.54:1.
///
// TODO: CA-1159 — replace with CoreUI's status badge once it exists
class RateStatusBadge extends StatelessWidget {
  final String label;
  final RateStatusBadgeVariant variant;

  const RateStatusBadge({
    super.key,
    required this.label,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    final isOrange = variant == RateStatusBadgeVariant.orange;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CoreSpacing.space2,
        vertical: CoreSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: isOrange
            ? colorTheme.backgroundOrangeMid
            : colorTheme.backgroundGreenMid,
        borderRadius: BorderRadius.circular(CoreSpacing.space2),
        border: isOrange
            ? Border.all(
                // #F7B999 (the Figma component's orange stroke) has no
                // matching named token in ripplearc_coreui 0.15.0 — every
                // other color in this widget maps to an exact theme token;
                // this is the sole literal, gone once CA-1159 lands.
                // ignore: avoid_static_colors
                color: const Color(0xFFF7B999),
              )
            : null,
      ),
      child: Text(
        label,
        style: textTheme.bodySmallSemiBold.copyWith(
          color: isOrange ? colorTheme.textWarning : colorTheme.textSuccess,
        ),
      ),
    );
  }
}
