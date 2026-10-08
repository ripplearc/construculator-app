// coverage:ignore-file
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// The memory drawers (UX Design Doc term 2.11, rule 4.16): the values a
/// function key offers back, one drawer per length key and one shared
/// drawer for anything that reads as degrees or D:M:S, because a rafter
/// angle typed under Sine is the same thing when Pitch wants it. Kept on
/// the phone only.
///
/// A drawer is a list, newest first. Which values it keeps — three deep,
/// no duplicates, a reused value moved to the front — is the engine's
/// rule; the repository stores the list it is given and answers with it.
/// Every `watch` emits the drawer as it is now and again after each
/// change; every write answers with a [Failure] rather than a throw.
abstract class RecentsRepository {
  /// The drawer every angle is filed in, whichever key asked for it.
  static const String angleDrawer = 'angle';

  /// The values of [drawer], newest first; empty when nothing was filed.
  Stream<List<Quantity>> watchRecents(String drawer);

  /// Replaces the values of [drawer] with [values], newest first.
  Future<Either<Failure, void>> saveRecents(
    String drawer,
    List<Quantity> values,
  );

  /// Ends every stream handed out.
  void dispose();
}
