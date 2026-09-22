// coverage:ignore-file
import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Reads and writes the five calculator settings (UX Design Doc term 2.20,
/// Appendix C) kept under the `calculator` key of the signed-in user's
/// `user_preferences`, which already syncs between devices.
abstract class CalculatorPreferencesRepository {
  /// The settings of the signed-in user: the current ones first, then a
  /// new value whenever the profile is read or written through the auth
  /// library, which is how a change made on another device arrives once
  /// the profile is next fetched. Emits the defaults while no profile has
  /// arrived, so the calculator never waits on the network to render.
  Stream<CalculatorPreferences> watchPreferences();

  /// Writes [preferences] under the `calculator` key of the signed-in
  /// user's profile and answers with what was saved, or a [Failure] when no
  /// profile is signed in or the profile could not be updated.
  Future<Either<Failure, CalculatorPreferences>> savePreferences(
    CalculatorPreferences preferences,
  );

  /// Ends the profile subscription. Streams handed out by
  /// [watchPreferences] end with it.
  void dispose();
}
