import 'package:flutter/material.dart';

/// Abstract provider for building project-related UI components.
abstract class ProjectUIProvider {
  /// Builds the app bar widget used in project screens.
  ///
  /// Implementations should return a widget (typically a
  /// `ProjectHeaderAppBar`) that displays the project's title and common
  /// actions (search, notifications, avatar). This method centralizes the
  /// construction of the header so callers can obtain a ready-to-use
  /// widget without depending on the concrete implementation details.
  ///
  /// The avatar image is now fetched automatically from the user's profile
  /// via the GetProjectBloc, so it no longer needs to be passed as a parameter.
  ///
  /// Parameters:
  /// - [projectId]: Identifier to fetch the project's name shown in the header title.
  /// - [onProjectTap]: Optional callback invoked when the project title is
  ///   tapped (e.g., to open project details).
  /// - [onSearchTap]: Optional callback for the search action button.
  /// - [onNotificationTap]: Optional callback for the notifications action.
  ///
  /// Returns a [PreferredSizeWidget] that can be used directly as an `appBar` in a
  /// `Scaffold`.
  PreferredSizeWidget buildProjectHeaderAppbar({
    required String projectId,
    VoidCallback? onProjectTap,
    VoidCallback? onSearchTap,
    VoidCallback? onNotificationTap,
  });
}
