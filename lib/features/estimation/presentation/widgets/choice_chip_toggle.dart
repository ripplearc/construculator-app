import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// A single pill in a two-option choice toggle (e.g. Day/Job), matching the
/// Figma "Choice Chips, Options=2" component (nodes `65814:173087` /
/// `65814:173092`) exactly: light-blue fill + teal border/text when
/// selected, white fill + grey border/dark text otherwise.
///
/// [CoreChip]'s theme resolver can't produce this: its selected background
/// is always `colors.pageBackground` (see `core_chip_theme.dart`), so this
/// is a small standalone widget instead of a `CoreChip` configuration.
/// Reusable for any future two-option toggle in this feature, not just
/// Day/Job.
///
/// Mirrors [CoreChip]'s `selected`/`onTap` contract exactly: the caller owns
/// the [selected] notifier, and this widget toggles it right after [onTap]
/// returns. Also mirrors [CoreChip]'s `Material`+`InkWell` shell (rather
/// than a bare `GestureDetector`) so keyboard focus/traversal and
/// Enter/Space activation keep working, the same as the `CoreChip` this
/// replaces.
///
// TODO: [CA-1160] Replace with CoreChip once it supports a tinted selected background. https://ripplearc.youtrack.cloud/issue/CA-1160
class ChoiceChipToggle extends StatefulWidget {
  /// Text shown inside the pill.
  final String label;

  /// Whether this pill is the selected option. The caller owns this
  /// notifier; this widget flips it right after [onTap] returns.
  final ValueNotifier<bool> selected;

  /// Called when the pill is tapped, before [selected] is flipped.
  final VoidCallback? onTap;

  /// Focus node for keyboard traversal. A new one is created and disposed
  /// internally when omitted.
  final FocusNode? focusNode;

  /// Whether this pill should request focus as soon as it's built.
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
  static const double _pillHeight = 44;
  static const double _pillHorizontalPadding = 18;
  static const double _tapTargetPadding = 2;

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
                padding: const EdgeInsets.symmetric(
                  vertical: _tapTargetPadding,
                ),
                child: Container(
                  height: _pillHeight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: _pillHorizontalPadding,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
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
