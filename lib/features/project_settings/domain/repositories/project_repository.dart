import 'package:construculator/features/project_settings/domain/entities/project_entity.dart';

/// Abstract repository interface for project data operations.
///
/// This repository defines the contract for accessing project data from various
/// data sources (local storage, remote APIs, etc.). It follows the repository
/// pattern to abstract data access logic from the domain layer.
///
/// Details can be found in the detailed design document: https://docs.google.com/document/d/1iXnDtNoersQdjHARELluAMqb8sB96rhRmjMKCWUA3QY/edit?tab=t.9phj9ydk8mav#bookmark=id.2xm61l2g4vgi
abstract class ProjectRepository {
  /// Retrieves a project by its unique identifier.
  ///
  /// Returns a [Future] that completes with a [Project] entity containing
  /// all project details including name, description, creator, company,
  /// export settings, and status.
  Future<Project> getProject(String id);
}