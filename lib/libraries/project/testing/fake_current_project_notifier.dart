import 'dart:async';

import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// A fake implementation of [CurrentProjectNotifier] for testing purposes.
class FakeCurrentProjectNotifier implements CurrentProjectNotifier, Disposable {
  final _controller = StreamController<String?>.broadcast();

  /// The list of project id changes for test assertions.
  final List<String?> projectIdChangedEvents = [];

  String? _currentProjectId;

  /// Creates a new [FakeCurrentProjectNotifier] with optional initial project id.
  FakeCurrentProjectNotifier({String? initialProjectId})
    : _currentProjectId = initialProjectId {
    _controller.stream.listen((id) => projectIdChangedEvents.add(id));
  }

  @override
  Stream<String?> get onCurrentProjectChanged => _controller.stream;

  @override
  String? get currentProjectId => _currentProjectId;

  @override
  void setCurrentProjectId(String? projectId) {
    _currentProjectId = projectId;
    _controller.add(projectId);
  }

  /// Resets the notifier to its initial state.
  void reset({String? projectId}) {
    _currentProjectId = projectId;
    projectIdChangedEvents.clear();
  }

  @override
  void dispose() {
    _controller.close();
  }
}
