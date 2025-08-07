/// This is the interface for the Either class.
/// It is used to represent the result of a function that can either fail or succeed.
abstract class Either<L, R> {
  const Either();

  /// This method is used to fold the Either class into a single value.
  /// It takes two functions as parameters, one for the left value and one for the right value.
  /// It returns a value of type T.
  T fold<T>(T Function(L l) leftFn, T Function(R r) rightFn);

  /// This method is used to check if the Either class is a left value.
  bool isLeft();

  /// This method is used to check if the Either class is a right value.
  bool isRight();

  /// This method is used to get the left value of the Either class.
  L? getLeftOrNull();

  /// This method is used to get the right value of the Either class.
  R? getRightOrNull();
}
