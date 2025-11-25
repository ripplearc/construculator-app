/// Test file with intentional violations for CI testing.
/// DELETE THIS FILE AFTER TESTING.

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// Violation 1: prefer_fake_over_mock - using Mock instead of Fake
abstract class SomeRepository {
  Future<String> fetchData();
}

class MockSomeRepository extends Mock implements SomeRepository {}
// VIOLATION: prefer_fake_over_mock - should use Fake instead of Mock

void main() {
  group('Test violations', () {
    test('test with optional operator violation', () {
      final String? nullableValue = 'test';
      
      // Violation 2: no_optional_operators_in_tests - using ?. in tests
      final length = nullableValue?.length; // VIOLATION: no_optional_operators_in_tests
      
      expect(length, 4);
    });
  });
}

