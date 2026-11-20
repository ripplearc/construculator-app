import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A cost sheet while the app's own number pad is up: [header] pinned at the
/// top, [controls] (the pad) at the bottom, [panel] pinned on top of the pad,
/// and the form scrolling in the height left (storyboard CUJ 4, "When a
/// keyboard comes up").
///
/// On a phone too short to pin the panel and still show [minFormHeight] of
/// the form, the panel scrolls with the form instead (Sabona, 2026-11-17).
/// It is pinned again as soon as it fits: when the sheet grows, when the
/// card gets shorter, or when the save-error line drawn with [controls] goes
/// away.
class NumberPadSheetLayout extends StatefulWidget {
  /// The sheet's title row, pinned at the top.
  final Widget header;

  /// Builds the scrolling form. While the panel does not fit it gets
  /// [panel] as `scrollingPanel`, to put at the end of the form; otherwise
  /// null.
  final Widget Function(Widget? scrollingPanel) form;

  /// The summary card, pinned on top of [controls] while it fits.
  final Widget panel;

  /// The number pad and anything drawn with it, pinned at the bottom.
  final Widget controls;

  /// The least height of the form to keep in view, about one field row.
  final double minFormHeight;

  const NumberPadSheetLayout({
    super.key,
    required this.header,
    required this.form,
    required this.panel,
    required this.controls,
    required this.minFormHeight,
  });

  @override
  State<NumberPadSheetLayout> createState() => _NumberPadSheetLayoutState();
}

class _NumberPadSheetLayoutState extends State<NumberPadSheetLayout> {
  bool _panelScrolls = false;
  final _scrolledPanel = _PanelHeight();

  @override
  Widget build(BuildContext context) {
    return CustomMultiChildLayout(
      delegate: _PinnedLayout(
        widget.minFormHeight,
        _panelScrolls ? _scrolledPanel : null,
        _scrolledPanel.resizes,
        _setPanelScrolls,
      ),
      children: [
        LayoutId(id: _Slot.header, child: widget.header),
        LayoutId(
          id: _Slot.form,
          child: widget.form(
            _panelScrolls
                ? _MeasuredPanel(
                    height: _scrolledPanel,
                    onResized: _relayoutLater,
                    child: widget.panel,
                  )
                : null,
          ),
        ),
        if (!_panelScrolls) LayoutId(id: _Slot.panel, child: widget.panel),
        LayoutId(id: _Slot.controls, child: widget.controls),
      ],
    );
  }

  void _setPanelScrolls(bool scrolls) =>
      _relayoutLater(() => _panelScrolls = scrolls);

  void _relayoutLater([VoidCallback? change]) {
    // Called during layout, where setState is not allowed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(change ?? () {});
    });
  }
}

enum _Slot { header, form, panel, controls }

class _PanelHeight {
  double value = 0;
  int resizes = 0;
}

class _MeasuredPanel extends SingleChildRenderObjectWidget {
  final _PanelHeight height;
  final VoidCallback onResized;

  const _MeasuredPanel({
    required this.height,
    required this.onResized,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasuredPanel(height, onResized);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderMeasuredPanel renderObject,
  ) {
    renderObject
      ..height = height
      ..onResized = onResized;
  }
}

class _RenderMeasuredPanel extends RenderProxyBox {
  _PanelHeight height;
  VoidCallback onResized;

  _RenderMeasuredPanel(this.height, this.onResized);

  @override
  void performLayout() {
    super.performLayout();
    if (size.height == height.value) return;
    height
      ..value = size.height
      ..resizes += 1;
    // The form is a relayout boundary, so the sheet's layout does not run
    // again by itself when only the card changes.
    onResized();
  }
}

class _PinnedLayout extends MultiChildLayoutDelegate {
  final double minFormHeight;
  final _PanelHeight? scrolledPanel;
  final int panelResizes;
  final ValueChanged<bool> onPanelScrollsChanged;

  _PinnedLayout(
    this.minFormHeight,
    this.scrolledPanel,
    this.panelResizes,
    this.onPanelScrollsChanged,
  );

  @override
  void performLayout(Size size) {
    // Unbounded height, as a Column gives its fixed children.
    final rows = BoxConstraints.tightFor(width: size.width);
    final header = layoutChild(_Slot.header, rows).height;
    final controls = layoutChild(_Slot.controls, rows).height;
    final scrolled = scrolledPanel;
    final double panel;
    final double form;
    if (scrolled == null) {
      panel = layoutChild(_Slot.panel, rows).height;
      form = math.max(0.0, size.height - header - panel - controls);
      layoutChild(_Slot.form, BoxConstraints.tight(Size(size.width, form)));
    } else {
      // The card is inside the form: laying the form out measures it, so
      // the fit test uses its height from this same layout.
      form = math.max(0.0, size.height - header - controls);
      layoutChild(_Slot.form, BoxConstraints.tight(Size(size.width, form)));
      panel = scrolled.value;
    }
    final fits = size.height - header - panel - controls >= minFormHeight;
    if (fits == (scrolled != null)) onPanelScrollsChanged(!fits);
    positionChild(_Slot.header, Offset.zero);
    positionChild(_Slot.form, Offset(0, header));
    if (scrolled == null) positionChild(_Slot.panel, Offset(0, header + form));
    positionChild(_Slot.controls, Offset(0, size.height - controls));
  }

  @override
  bool shouldRelayout(_PinnedLayout oldDelegate) =>
      minFormHeight != oldDelegate.minFormHeight ||
      panelResizes != oldDelegate.panelResizes;
}
