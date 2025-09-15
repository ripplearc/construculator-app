import 'package:construculator/libraries/time/interfaces/clock.dart';

/// Fake implementation of the [Clock] interface for testing purposes.
class FakeClockImpl implements Clock {
  DateTime _current;

  /// Constructor for fake clock implementation, initializes clock to 1st Jan 2000.
  FakeClockImpl([DateTime? initial])
    : _current = initial ?? DateTime(2000, 1, 1);

  @override
  DateTime now() => _current;

  /// Advances the clock by a specified duration.
  void advance(Duration duration) {
    _current = _current.add(duration);
  }

  /// Sets the clock to a specific time.
  void set(DateTime newTime) {
    _current = newTime;
  }
}
