import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:construculator/libraries/time/system_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ClockModule extends Module {
  @override
  void exportedBinds(Injector i) {
    i.add<Clock>(() => SystemClockImpl());
  }
}
