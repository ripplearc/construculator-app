/// A simple abstraction for retrieving the current time.
///
/// ## Why use [Clock] instead of [DateTime.now]?
/// Directly calling `DateTime.now()` makes your code hard to test because
/// the value of "now" changes every time the code runs. By depending on a
/// [Clock], you can:
///
/// - **Inject a [SystemClock] in production** to get the real current time.
/// - **Inject a [FakeClock] in tests** to control and simulate time without
///   waiting in real-time.
/// - **Avoid flakiness** in time-sensitive unit tests, integration tests, and
///   UI tests.
/// This approach ensures consistent, testable, and maintainable handling of
/// time across your entire codebase.
abstract class Clock {
  /// Returns the current date and time according to this [Clock].
  ///
  /// Implementations may return:
  /// - The system time ([SystemClock]).
  /// - A fixed or simulated time ([FakeClock]) for testing purposes.
  DateTime now();
}
