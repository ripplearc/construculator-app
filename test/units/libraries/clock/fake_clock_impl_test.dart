import 'package:construculator/libraries/clock/testing/clock_test_module.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/clock/interfaces/clock.dart';
import 'package:construculator/libraries/clock/testing/fake_clock_impl.dart';

void main() {
  late FakeClockImpl clock;

  setUp(() {
    Modular.init(_TestAppModule());
    clock = Modular.get<Clock>() as FakeClockImpl;
  });

  tearDown(() {
    Modular.destroy();
  });

  group('FakeClockImpl Tests', () {
    test('should return default time (Jan 1, 2000) when initialized', () {
      final expectedDate = DateTime(2000, 1, 1);
      expect(clock.now(), equals(expectedDate));
    });

    test('should advance time correctly', () {
      final initialTime = clock.now();
      final duration = Duration(hours: 2, minutes: 30);

      clock.advance(duration);

      final expectedTime = initialTime.add(duration);
      expect(clock.now(), equals(expectedTime));
    });

    test('should set time to specific value', () {
      final newTime = DateTime(2023, 6, 15, 10, 30, 45);

      clock.set(newTime);

      expect(clock.now(), equals(newTime));
    });

    test('should maintain state between operations', () {
      final initialTime = clock.now();

      clock.advance(Duration(hours: 1));
      final timeAfterAdvance = clock.now();

      clock.set(DateTime(2023, 6, 15));
      final timeAfterSet = clock.now();

      expect(timeAfterAdvance, equals(initialTime.add(Duration(hours: 1))));
      expect(timeAfterSet, equals(DateTime(2023, 6, 15)));
    });
  });
}

class _TestAppModule extends Module {
  @override
  List<Module> get imports => [ClockTestModule()];
}
