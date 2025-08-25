import 'package:construculator/libraries/clock/interfaces/clock.dart';
import 'package:construculator/libraries/clock/system_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ClockModule extends Module {

  @override
  void exportedBinds(Injector i) {
    i.add<Clock>(() => SystemClockImpl());
  }
}
