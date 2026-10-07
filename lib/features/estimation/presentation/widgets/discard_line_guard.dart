import 'dart:math' as math;

import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/confirmation_dialog.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Guards the material sheet against closing by accident.
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
class DiscardLineGuard extends StatefulWidget {
  final Widget child;

  const DiscardLineGuard({super.key, required this.child});

  @override
  State<DiscardLineGuard> createState() => _DiscardLineGuardState();
}

class _DiscardLineGuardState extends State<DiscardLineGuard> {
  static const double _swipeDownVelocity = 700;
  static const double _pullDownDistance = 64;

  double _pulledDown = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MaterialCostFormBloc, MaterialCostFormState>(
      buildWhen: (previous, current) =>
          _hasUnsavedChanges(previous) != _hasUnsavedChanges(current),
      builder: (context, state) {
        final isKeyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;
        return PopScope(
          canPop: !_hasUnsavedChanges(state) && !isKeyboardUp,
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

  bool _hasUnsavedChanges(MaterialCostFormState state) =>
      (state is MaterialCostFormEditing || state is MaterialCostFormFailure) &&
      state.data.hasUnsavedChanges;

  bool _onFormScrolled(ScrollNotification notification) {
    final isDragging = notification is ScrollUpdateNotification
        ? notification.dragDetails != null
        : notification is OverscrollNotification &&
              notification.dragDetails != null;
    if (notification is OverscrollNotification &&
        isDragging &&
        notification.overscroll < 0) {
      // Clamping physics, as on Android, report the pull past the top here.
      _pulledDown -= notification.overscroll;
    } else if (notification is ScrollUpdateNotification &&
        isDragging &&
        notification.metrics.pixels < 0) {
      // Bouncing physics, as on iOS, scroll to a negative position instead.
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
    final name = context
        .read<MaterialCostFormBloc>()
        .state
        .data
        .itemName
        .trim();
    final keepEditing = await ConfirmationDialog.show(
      context,
      title: l10n.discardLineDialogTitle,
      body: name.isEmpty
          ? l10n.discardLineDialogBodyUnnamed
          : l10n.discardLineDialogBody(name),
      secondaryLabel: l10n.discardLineDiscardButton,
      primaryLabel: l10n.discardLineKeepEditingButton,
    );
    if (keepEditing == false && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
