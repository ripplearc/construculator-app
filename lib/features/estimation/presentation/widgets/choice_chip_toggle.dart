import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// A single pill in a two-option choice toggle (e.g. Day/Job), matching the
/// Figma "Choice Chips, Options=2" component (nodes `65814:173087` /
/// `65814:173092`) exactly: light-blue fill + teal border/text when
/// selected, white fill + grey border/dark text otherwise.
///
/// [CoreChip]'s theme resolver can't produce this — its selected background
/// is always `colors.pageBackground`, confirmed by reading
/// `core_chip_theme.dart` — so this is a small standalone widget instead of
/// a `CoreChip` configuration. Reusable for any future two-option toggle in
/// this feature, not just Day/Job.
///
/// Mirrors [CoreChip]'s `selected`/`onTap` contract exactly: the caller owns
/// the [selected] notifier, and this widget toggles it right after [onTap]
/// returns. Also mirrors [CoreChip]'s `Material`+`InkWell` shell (rather
/// than a bare `GestureDetector`) so keyboard focus/traversal and
/// Enter/Space activation keep working, the same as the `CoreChip` this
/// replaces.
///
// TODO: CA-1160 — replace this with CoreChip once it supports a tinted selected background
class ChoiceChipToggle extends StatefulWidget {
  final String label;
  final ValueNotifier<bool> selected;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool autofocus;

  const ChoiceChipToggle({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<ChoiceChipToggle> createState() => _ChoiceChipToggleState();
}

class _ChoiceChipToggleState extends State<ChoiceChipToggle> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleTap() {
    widget.onTap?.call();
    widget.selected.value = !widget.selected.value;
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    return ValueListenableBuilder<bool>(
      valueListenable: widget.selected,
      builder: (context, isSelected, _) {
        return Semantics(
          label: widget.label,
          button: true,
          selected: isSelected,
          child: Material(
            color: colorTheme.transparent,
            child: InkWell(
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              onTap: _handleTap,
              customBorder: const StadiumBorder(),
              child: Padding(
                // Invisible hit-area padding so the tap target still clears
                // Android's 48dp minimum without inflating the visible 44px
                // pill the Figma spec calls for.
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    // `pageBackground` is gray50 (#F9FAFB) in light mode —
                    // visually indistinguishable from the Figma spec's
                    // literal #FFFFFF — and, unlike a hardcoded white, it
                    // flips to a dark surface in dark mode along with
                    // `textDark` (the unselected label color), keeping
                    // contrast intact there. A literal white fill paired
                    // with `textDark` (which flips to a *light* color for
                    // dark backgrounds) fails contrast in dark mode —
                    // caught by this widget's own a11y test.
                    color: isSelected
                        ? colorTheme.backgroundBlueLight
                        : colorTheme.pageBackground,
                    border: Border.all(
                      color: isSelected
                          ? colorTheme.textLink
                          : colorTheme.lineMid,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: ExcludeSemantics(
                    child: Text(
                      widget.label,
                      style: isSelected
                          ? textTheme.bodyMediumSemiBold.copyWith(
                              color: colorTheme.textLink,
                            )
                          : textTheme.bodyMediumRegular.copyWith(
                              color: colorTheme.textDark,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
