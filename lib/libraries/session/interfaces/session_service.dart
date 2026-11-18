// coverage:ignore-file
/// Starts and ends the session: the group of objects that exist only while one
/// user is signed in.
///
/// Objects in the group live in memory only, so ending the session throws them
/// away and the next user starts with new ones. Code that lives longer than a
/// session must look these objects up when it needs them and must not keep a
/// reference, because a kept reference still points at the removed object.
abstract class SessionService {
  /// Whether a session is started and not yet ended.
  bool get isActive;

  /// Adds the session's objects. Does nothing when a session is already active.
  void startSession();

  /// Removes the session's objects and disposes the ones that need it. Does
  /// nothing when no session is active.
  void endSession();
}
