// coverage:ignore-file
part of 'get_project_bloc.dart';

/// Base class for all Get Project states.
sealed class GetProjectState extends Equatable {
  const GetProjectState();

  @override
  List<Object?> get props => [];
}

class GetProjectInitial extends GetProjectState {
  @override
  List<Object?> get props => [];
}

class GetProjectByIdLoading extends GetProjectState {
  @override
  List<Object?> get props => [];
}

class GetProjectByIdLoadSuccess extends GetProjectState {
  final ProjectHeaderData headerData;

  const GetProjectByIdLoadSuccess({required this.headerData});

  /// Convenience getter for backward compatibility
  Project get project => headerData.project;

  /// Convenience getter for user avatar URL
  String? get userAvatarUrl => headerData.userAvatarUrl;

  /// Convenience getter for user avatar ImageProvider
  ImageProvider? get userAvatarImage => headerData.userAvatarImage;

  @override
  List<Object?> get props => [headerData];
}

class GetProjectByIdLoadFailure extends GetProjectState {
  final Failure failure;

  const GetProjectByIdLoadFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
}
