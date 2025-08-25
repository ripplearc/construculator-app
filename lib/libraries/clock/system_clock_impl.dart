// coverage:ignore-file
import 'package:construculator/libraries/clock/interfaces/clock.dart';

/// Implementation of the [Clock] interface using the system clock.
class SystemClockImpl implements Clock {
  @override
  DateTime now() => DateTime.now();
}
