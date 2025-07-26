// coverage:ignore-file
import 'dart:async';

import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

class CToast implements Disposable {
  OverlayEntry? _entry;
  Timer? _timer;

  /// Shows an error toast.
  /// Accepts a context and an optional message as parameters.
  void showError(BuildContext context, String? message) {
    final loc = AppLocalizations.of(context);
    showCustomToast(
      context,
      (overlayContext) => Toast.error(
        description: message ?? 'An Error Occured',
        closeLabel: loc?.closeLabel ?? 'Close',
        onClose: () {
          _entry?.remove();
        },
      ),
    );
  }

  /// Shows a success toast.
  /// Accepts a context and an optional message as parameters.
  void showSuccess(BuildContext context, String? message) {
    final loc = AppLocalizations.of(context);
    showCustomToast(
      context,
      (overlayContext) => Toast.success(
        description: message ?? 'Request Successful',
        closeLabel: loc?.closeLabel ?? 'Close',
        onClose: () {
          _entry?.remove();
        },
      ),
    );
  }

  /// Shows a warning toast.
  /// Accepts a context and an optional message as parameters.
  void showWarning(BuildContext context, String? message) {
    final loc = AppLocalizations.of(context);
    showCustomToast(
      context,
      (overlayContext) => Toast.warning(
        description: message ?? 'Warning',
        closeLabel: loc?.closeLabel ?? 'Close',
        onClose: () {
          _entry?.remove();
        },
      ),
    );
  }

  /// Shows a custom toast.
  /// Accepts a context, a toast builder, and an optional duration as parameters.
  void showCustomToast(
    BuildContext context,
    Widget Function(BuildContext context) toastBuilder, {
    Duration duration = const Duration(seconds: 3),
  }) {
    // hides keyboard if visible
    FocusScope.of(context).unfocus();
    final overlay = Overlay.of(context);
    // removes previous entry
    if (_entry?.mounted ?? false) {
      _entry?.remove();
    }
    // cancels previous timer
    if (_timer != null) {
      _timer?.cancel();
    }
    _entry = OverlayEntry(
      builder:
          (context) => Positioned(
            bottom: 100,
            width: MediaQuery.of(context).size.width,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Material(child: toastBuilder(context)),
            ),
          ),
    );
    final entryToAdd = _entry;
    if (entryToAdd != null) {
      overlay.insert(entryToAdd);
    }
    _timer = Timer(duration, () {
      if (_entry?.mounted ?? false) {
        _entry?.remove();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    final entry = _entry;
    if (entry != null && entry.mounted) {
      entry.remove();
    }
  }
}
