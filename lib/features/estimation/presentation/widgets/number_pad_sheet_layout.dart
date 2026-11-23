import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A cost sheet while the app's own number pad is up: [header] pinned at the
/// top, [controls] (the pad) at the bottom, [panel] pinned on top of the pad,
/// and [form] scrolling in the height left (storyboard CUJ 4, "When a
/// keyboard comes up"). Needs a bounded height, as in a bottom sheet.
class NumberPadSheetLayout extends StatelessWidget {
  /// The sheet's title row, pinned at the top.
  final Widget header;

  /// The scrolling form, given the height left between [header] and [panel].
  final Widget form;

  /// The summary card, pinned on top of [controls].
  final Widget panel;

  /// The number pad and anything drawn with it, pinned at the bottom.
  final Widget controls;

  const NumberPadSheetLayout({
    super.key,
    required this.header,
    required this.form,
    required this.panel,
    required this.controls,
  });

  @override
  Widget build(BuildContext context) {
    return CustomMultiChildLayout(
      delegate: _PinnedLayout(),
      children: [
        LayoutId(id: _Slot.header, child: header),
        LayoutId(id: _Slot.form, child: form),
        LayoutId(id: _Slot.panel, child: panel),
        LayoutId(id: _Slot.controls, child: controls),
      ],
    );
  }
}

enum _Slot { header, form, panel, controls }

class _PinnedLayout extends MultiChildLayoutDelegate {
  @override
  void performLayout(Size size) {
    final rows = BoxConstraints.tightFor(width: size.width);
    final header = layoutChild(_Slot.header, rows).height;
    final controls = layoutChild(_Slot.controls, rows).height;
    final panel = layoutChild(_Slot.panel, rows).height;
    final form = math.max(0.0, size.height - header - panel - controls);
    layoutChild(_Slot.form, BoxConstraints.tight(Size(size.width, form)));
    positionChild(_Slot.header, Offset.zero);
    positionChild(_Slot.form, Offset(0, header));
    positionChild(_Slot.panel, Offset(0, header + form));
    positionChild(_Slot.controls, Offset(0, size.height - controls));
  }

  @override
  bool shouldRelayout(_PinnedLayout oldDelegate) => false;
}
