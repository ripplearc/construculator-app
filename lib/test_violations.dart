/// Test file with intentional violations for CI testing.
/// DELETE THIS FILE AFTER TESTING.

// Violation 1: forbid_forced_unwrapping - using ! operator on nullable
String? getNullableValue() => null;

String getValueWithViolation() {
  final value = getNullableValue();
  if (value == null) {
    throw StateError('Value cannot be null');
  }
  return value;
}

