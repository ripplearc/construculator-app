import 'package:equatable/equatable.dart';

/// Where the sign-in check stands. Everything that reacts to a session waits
/// for a finished value.
sealed class CheckState extends Equatable {
  const CheckState();

  /// Whether a reader may now read user data.
  bool get isFinished => false;

  @override
  List<Object?> get props => const [];
}

/// A check has not finished, or a different user's event just arrived. A
/// loading screen covers the app.
final class Checking extends CheckState {
  /// The state the app starts in, before the first screen.
  const Checking();
}

/// A delete or a check failed or timed out. Readers stay held back, and the
/// loading screen stays until a retry screen exists.
final class Blocked extends CheckState {
  /// The user whose check failed, or null when nobody was signed in.
  final String? userId;

  /// A failure for [userId].
  const Blocked(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// The app must restart before anything reads data. Final.
final class RestartRequired extends CheckState {
  /// The final state.
  const RestartRequired();
}

/// The check finished and [userId] owns the data on the phone.
final class FinishedFor extends CheckState {
  /// The signed-in user.
  final String userId;

  /// A finished check for [userId].
  const FinishedFor(this.userId);

  @override
  bool get isFinished => true;

  @override
  List<Object?> get props => [userId];
}

/// The check finished and nobody is signed in.
final class FinishedNobodySignedIn extends CheckState {
  /// A finished check with no session.
  const FinishedNobodySignedIn();

  @override
  bool get isFinished => true;
}
