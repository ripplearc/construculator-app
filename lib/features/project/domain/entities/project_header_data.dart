import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Entity that combines project information with user profile data
/// specifically for rendering the project header UI.
///
/// This entity encapsulates all the data needed by the project header,
/// including the project details and the current user's profile information.
class ProjectHeaderData extends Equatable {
  /// The project information
  final Project project;

  /// The user's profile information (may be null if not available)
  final User? userProfile;

  const ProjectHeaderData({
    required this.project,
    this.userProfile,
  });

  /// Helper getter to access the user's profile photo URL
  String? get userAvatarUrl => userProfile?.profilePhotoUrl;

  /// Computed property that returns an ImageProvider for the user avatar.
  /// Returns null if the profile photo URL is null or empty.
  ///
  /// This encapsulates the logic for determining whether a network image
  /// should be used, removing the need for UI-layer guards.
  ImageProvider? get userAvatarImage {
    final url = userAvatarUrl;
    if (url != null && url.isNotEmpty) {
      return NetworkImage(url);
    }
    return null;
  }

  @override
  List<Object?> get props => [project, userProfile];
}
