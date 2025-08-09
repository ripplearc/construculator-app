import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/either/either_impl.dart';
import 'package:construculator/libraries/either/interfaces/either.dart';

void main() {
  group('Either Implementation Tests', () {
    group('Left Tests', () {
      test('should create Left with value', () {
        const left = Left<String, int>('error');
        expect(left.value, equals('error'));
      });

      test('should return true for isLeft', () {
        const left = Left<String, int>('error');
        expect(left.isLeft(), isTrue);
      });

      test('should return false for isRight', () {
        const left = Left<String, int>('error');
        expect(left.isRight(), isFalse);
      });

      test('should return left value for getLeftOrNull', () {
        const left = Left<String, int>('error');
        expect(left.getLeftOrNull(), equals('error'));
      });

      test('should return null for getRightOrNull', () {
        const left = Left<String, int>('error');
        expect(left.getRightOrNull(), isNull);
      });

      test('should execute left function in fold', () {
        const left = Left<String, int>('error');
        final result = left.fold(
          (l) => 'Left: $l',
          (r) => 'Right: $r',
        );
        expect(result, equals('Left: error'));
      });

      test('should handle different types in fold', () {
        const left = Left<int, String>(42);
        final result = left.fold(
          (l) => l * 2,
          (r) => r.length,
        );
        expect(result, equals(84));
      });

      test('should be const constructible', () {
        const left1 = Left<String, int>('error');
        const left2 = Left<String, int>('error');
        expect(identical(left1, left2), isTrue);
      });
    });

    group('Right Tests', () {
      test('should create Right with value', () {
        const right = Right<String, int>(42);
        expect(right.value, equals(42));
      });

      test('should return false for isLeft', () {
        const right = Right<String, int>(42);
        expect(right.isLeft(), isFalse);
      });

      test('should return true for isRight', () {
        const right = Right<String, int>(42);
        expect(right.isRight(), isTrue);
      });

      test('should return null for getLeftOrNull', () {
        const right = Right<String, int>(42);
        expect(right.getLeftOrNull(), isNull);
      });

      test('should return right value for getRightOrNull', () {
        const right = Right<String, int>(42);
        expect(right.getRightOrNull(), equals(42));
      });

      test('should execute right function in fold', () {
        const right = Right<String, int>(42);
        final result = right.fold(
          (l) => 'Left: $l',
          (r) => 'Right: $r',
        );
        expect(result, equals('Right: 42'));
      });

      test('should handle different types in fold', () {
        const right = Right<String, int>(42);
        final result = right.fold(
          (l) => l.length,
          (r) => r * 2,
        );
        expect(result, equals(84)); // 42 * 2 = 84
      });

      test('should be const constructible', () {
        const right1 = Right<String, int>(42);
        const right2 = Right<String, int>(42);
        expect(identical(right1, right2), isTrue);
      });
    });

    group('Either Type Safety Tests', () {
      test('should handle complex types', () {
        final left = Left<Exception, Map<String, dynamic>>(
          Exception('Database error'),
        );
        expect(left.isLeft(), isTrue);
        expect(left.getLeftOrNull(), isA<Exception>());
        expect(left.getRightOrNull(), isNull);
      });

      test('should handle nullable types', () {
        const right = Right<String?, int?>(null);
        expect(right.isRight(), isTrue);
        expect(right.getRightOrNull(), isNull);
      });

      test('should handle generic types', () {
        const left = Left<List<String>, Set<int>>(['error1', 'error2']);
        expect(left.isLeft(), isTrue);
        expect(left.getLeftOrNull(), equals(['error1', 'error2']));
      });
    });

    group('Either Usage Pattern Tests', () {
      test('should handle success case pattern', () {
        Either<String, int> result = const Right<String, int>(42);
        
        if (result.isRight()) {
          final value = result.getRightOrNull();
          expect(value, equals(42));
        } else {
          fail('Should not reach here');
        }
      });

      test('should handle failure case pattern', () {
        Either<String, int> result = const Left<String, int>('error');
        
        if (result.isLeft()) {
          final error = result.getLeftOrNull();
          expect(error, equals('error'));
        } else {
          fail('Should not reach here');
        }
      });

      test('should handle fold pattern for success', () {
        Either<String, int> result = const Right<String, int>(42);
        
        final message = result.fold(
          (error) => 'Error: $error',
          (value) => 'Success: $value',
        );
        
        expect(message, equals('Success: 42'));
      });

      test('should handle fold pattern for failure', () {
        Either<String, int> result = const Left<String, int>('database_error');
        
        final message = result.fold(
          (error) => 'Error: $error',
          (value) => 'Success: $value',
        );
        
        expect(message, equals('Error: database_error'));
      });
    });

    group('Either Edge Cases', () {
      test('should handle empty string in Left', () {
        const left = Left<String, int>('');
        expect(left.isLeft(), isTrue);
        expect(left.getLeftOrNull(), equals(''));
      });

      test('should handle zero in Right', () {
        const right = Right<String, int>(0);
        expect(right.isRight(), isTrue);
        expect(right.getRightOrNull(), equals(0));
      });

      test('should handle negative numbers', () {
        const right = Right<String, int>(-42);
        expect(right.isRight(), isTrue);
        expect(right.getRightOrNull(), equals(-42));
      });

      test('should handle special characters in Left', () {
        const left = Left<String, int>('!@#\$%^&*()');
        expect(left.isLeft(), isTrue);
        expect(left.getLeftOrNull(), equals('!@#\$%^&*()'));
      });
    });
  });
} 