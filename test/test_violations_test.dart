/// Test file with intentional violations for CI testing.
/// DELETE THIS FILE AFTER TESTING.

import 'package:flutter_test/flutter_test.dart';

// Violation 1: prefer_fake_over_mock - using Mock instead of Fake
abstract class SomeRepository {
  Future<String> fetchData();
}

/// Fake implementation of [SomeRepository] for testing purposes.
class FakeSomeRepository implements SomeRepository {
  /// Constructor for fake some repository.
  FakeSomeRepository();

  @override
  Future<String> fetchData() async => 'test';
}

void main() {
  group('Test violations', () {
    test('test with optional operator violation', () {
      final String? nullableValue = 'test';
      
      // Violation 2: no_optional_operators_in_tests - using ?. in tests
      if (nullableValue == null) {
        fail('nullableValue should not be null');
      }
      final length = nullableValue.length;
      
      expect(length, 4);
    });
  });
}

