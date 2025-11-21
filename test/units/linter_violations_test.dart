import 'package:flutter_test/flutter_test.dart';

/// Test file to demonstrate linter rule violations
/// 
/// This file intentionally violates:
/// 1. forbid_forced_unwrapping - using ! operator
/// 2. no_optional_operators_in_tests - using ?. operator in tests

void main() {
  group('Linter Violations Test', () {
    test('violates forbid_forced_unwrapping rule', () {
      // Violation 1: Using forced unwrapping operator (!)
      String? nullableString = 'test';
      String nonNullable = nullableString!; // ❌ Violates forbid_forced_unwrapping
      
      expect(nonNullable, equals('test'));
    });

    test('violates no_optional_operators_in_tests rule', () {
      // Violation 2: Using optional operator (?.) in tests
      String? nullableString = 'test';
      int? length = nullableString?.length; // ❌ Violates no_optional_operators_in_tests
      
      expect(length, equals(4));
    });

    test('violates both rules in one test', () {
      // Violation 1: Using forced unwrapping
      String? nullableString = 'hello';
      String value = nullableString!; // ❌ Violates forbid_forced_unwrapping
      
      // Violation 2: Using optional operator
      int? result = value?.length; // ❌ Violates no_optional_operators_in_tests
      
      expect(result, equals(5));
    });
  });
}

