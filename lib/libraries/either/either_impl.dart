import 'package:construculator/libraries/either/interfaces/either.dart';

/// This is the implementation of the Left class for the Either class.
/// It is used to represent the left value of the Either class.
/// It represents the failure case.
class Left<L, R> extends Either<L, R> {
  final L value;
  const Left(this.value);

  @override
  T fold<T>(T Function(L l) leftFn, T Function(R r) rightFn) => leftFn(value);

  @override
  bool isLeft() => true;

  @override
  bool isRight() => false;

  @override
  L? getLeftOrNull() => value;

  @override
  R? getRightOrNull() => null;
}

/// This is the implementation of the Right class for the Either class.
/// It is used to represent the right value of the Either class.
/// It represents the success case.
class Right<L, R> extends Either<L, R> {
  final R value;
  const Right(this.value);

  @override
  T fold<T>(T Function(L l) leftFn, T Function(R r) rightFn) => rightFn(value);

  @override
  bool isLeft() => false;

  @override
  bool isRight() => true;

  @override
  L? getLeftOrNull() => null;

  @override
  R? getRightOrNull() => value;
}
