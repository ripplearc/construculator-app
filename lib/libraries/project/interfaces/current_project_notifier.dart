/// Allows consumers to read and update the currently selected project id.
abstract class CurrentProjectNotifier {
  /// Stream that emits when the selected project id changes.
  Stream<String?> get onCurrentProjectChanged;

  /// Current selected project id.
  String? get currentProjectId;

  /// Updates the selected project id.
  void setCurrentProjectId(String? projectId);
}
