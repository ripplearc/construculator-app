import 'dart:math' as math;

import 'package:construculator/features/estimation/presentation/widgets/confirmation_dialog.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Guards a cost form sheet against closing by accident.
///
/// A tap on the dimmed background, the back arrow, a swipe down and the
/// phone's back gesture all arrive here as a blocked pop. The sheet turns off
/// its built-in swipe, which closes without asking, and this widget turns a
/// downward swipe into the same pop. A swipe counts when it starts on the sheet
/// above a form that does not scroll, or when it pulls a scrolling form down
/// past its top.
///
/// While the keyboard is up, the first of these only closes the keyboard, even
/// when nothing was typed. After that, a sheet with something typed in it asks
/// "Discard this line?". Tapping outside the dialog, or the back gesture on it,
/// means keep editing.
///
/// [B] is the form's bloc and [S] its state. [hasUnsavedChanges] says whether a
/// state has something typed in it, and [itemNameOf] gives the name the dialog
/// shows, empty when nothing was named yet.
class DiscardLineGuard<B extends StateStreamable<S>, S> extends StatefulWidget {
  final bool Function(S state) hasUnsavedChanges;
  final String Function(S state) itemNameOf;
  final Widget child;

  const DiscardLineGuard({
    super.key,
    required this.hasUnsavedChanges,
    required this.itemNameOf,
    required this.child,
  });

  @override
  State<DiscardLineGuard<B, S>> createState() => _DiscardLineGuardState<B, S>();
}

class _DiscardLineGuardState<B extends StateStreamable<S>, S>
    extends State<DiscardLineGuard<B, S>> {
  static const double _swipeDownVelocity = 700;
  static const double _pullDownDistance = 64;

  double _pulledDown = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<B, S>(
      buildWhen: (previous, current) =>
          widget.hasUnsavedChanges(previous) !=
          widget.hasUnsavedChanges(current),
      builder: (context, state) {
        final isKeyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;
        return PopScope(
          canPop: !widget.hasUnsavedChanges(state) && !isKeyboardUp,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _askBeforeClosing(context, isKeyboardUp);
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: _onFormScrolled,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragEnd: (details) {
                if ((details.primaryVelocity ?? 0) > _swipeDownVelocity) {
                  Navigator.of(context).maybePop();
                }
              },
              child: widget.child,
            ),
          ),
        );
      },
    );
  }

  bool _onFormScrolled(ScrollNotification notification) {
    final isDragging = notification is ScrollUpdateNotification
        ? notification.dragDetails != null
        : notification is OverscrollNotification &&
              notification.dragDetails != null;
    final isClampedPullPastTop =
        notification is OverscrollNotification &&
        isDragging &&
        notification.overscroll < 0;
    final isBouncingPullPastTop =
        notification is ScrollUpdateNotification &&
        isDragging &&
        notification.metrics.pixels < 0;
    if (isClampedPullPastTop) {
      _pulledDown -= notification.overscroll;
    } else if (isBouncingPullPastTop) {
      _pulledDown = math.max(_pulledDown, -notification.metrics.pixels);
    } else if (notification is ScrollEndNotification) {
      final pulledPastTop = _pulledDown >= _pullDownDistance;
      _pulledDown = 0;
      if (pulledPastTop) Navigator.of(context).maybePop();
    }
    return false;
  }

  Future<void> _askBeforeClosing(
    BuildContext context,
    bool isKeyboardUp,
  ) async {
    if (isKeyboardUp) {
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }
    final l10n = context.l10n;
    final name = widget.itemNameOf(context.read<B>().state).trim();
    final keepEditing = await ConfirmationDialog.show(
      context,
      title: l10n.discardLineDialogTitle,
      body: TextSpan(
        text: name.isEmpty
            ? l10n.discardLineDialogBodyUnnamed
            : l10n.discardLineDialogBody(name),
      ),
      secondaryLabel: l10n.discardLineDiscardButton,
      primaryLabel: l10n.discardLineKeepEditingButton,
    );
    if (keepEditing == false && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
