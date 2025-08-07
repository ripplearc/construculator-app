import 'package:construculator/libraries/either/interfaces/either.dart';

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
