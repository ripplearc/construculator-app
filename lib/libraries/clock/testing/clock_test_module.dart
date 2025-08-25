import 'package:construculator/libraries/clock/interfaces/clock.dart';
import 'package:construculator/libraries/clock/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ClockTestModule extends Module {

  @override
  void exportedBinds(Injector i) {
    i.add<Clock>(() => FakeClockImpl());
  }
}
