/// Test file with intentional violations for CI testing.
/// DELETE THIS FILE AFTER TESTING.

// Violation 1: forbid_forced_unwrapping - using ! operator on nullable
String? getNullableValue() => null;

String getValueWithViolation() {
  final value = getNullableValue();
  return value!; // VIOLATION: forbid_forced_unwrapping
}

