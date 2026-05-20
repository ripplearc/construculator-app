import 'dart:async';

import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Concrete implementation of [CurrentProjectNotifier] that maintains the
/// currently selected project ID and broadcasts changes via a stream.
class CurrentProjectNotifierImpl implements CurrentProjectNotifier, Disposable {
  final _projectController = StreamController<String?>.broadcast();

  String? _currentProjectId;

  /// Creates a [CurrentProjectNotifierImpl], optionally seeded with an
  /// [initialProjectId].
  CurrentProjectNotifierImpl({String? initialProjectId})
    : _currentProjectId = initialProjectId;

  @override

  /// Stream that emits the new project ID whenever [setCurrentProjectId] is called.
  Stream<String?> get onCurrentProjectChanged => _projectController.stream;

  @override

  /// The ID of the currently selected project, or `null` if none is selected.
  String? get currentProjectId => _currentProjectId;

  @override

  /// Updates the current project ID to [projectId] and notifies all listeners.
  void setCurrentProjectId(String? projectId) {
    _currentProjectId = projectId;
    _projectController.add(projectId);
  }

  @override

  /// Closes the underlying stream controller and releases resources.
  void dispose() {
    _projectController.close();
  }
}
