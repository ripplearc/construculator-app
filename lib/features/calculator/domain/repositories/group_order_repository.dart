// coverage:ignore-file
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// The order of the five function-key groups set in View all, as this
/// phone keeps it (UX Design Doc Section 1.3; Appendix E, "Stays on this
/// phone": each phone keeps its own keyboard order).
abstract class GroupOrderRepository {
  /// The group ids in the user's order, now and after every change; the
  /// default order while none was set, or when what was set no longer
  /// names this build's groups.
  Stream<List<String>> watchGroupOrder();

  /// Keeps [order] as the phone's order.
  Future<Either<Failure, void>> saveGroupOrder(List<String> order);

  /// Ends every watch handed out.
  void dispose();
}
