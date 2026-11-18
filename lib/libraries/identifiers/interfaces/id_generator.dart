// coverage:ignore-file
/// Creates the ids that rows get on the phone before the server has seen them.
///
/// Code that writes a new row asks an [IdGenerator] for its id instead of
/// creating one inline, so a test can inject `FakeIdGeneratorImpl` and assert
/// the exact id that was written.
abstract class IdGenerator {
  /// Returns a new id, a version 4 UUID in production, that no earlier call
  /// returned.
  String newId();
}
