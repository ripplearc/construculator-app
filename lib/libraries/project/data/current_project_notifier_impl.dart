import 'dart:async';

import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:flutter_modular/flutter_modular.dart';

class CurrentProjectNotifierImpl implements CurrentProjectNotifier, Disposable {
  final _projectController = StreamController<String?>.broadcast();

  String? _currentProjectId;

  CurrentProjectNotifierImpl({String? initialProjectId})
    : _currentProjectId = initialProjectId;

  @override
  Stream<String?> get onCurrentProjectChanged => _projectController.stream;

  @override
  String? get currentProjectId => _currentProjectId;

  @override
  void setCurrentProjectId(String? projectId) {
    _currentProjectId = projectId;
    _projectController.add(projectId);
  }

  @override
  void dispose() {
    _projectController.close();
  }
}
