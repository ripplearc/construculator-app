import 'package:construculator/libraries/network_status/interfaces/connectivity_sdk.dart';
import 'package:construculator/libraries/network_status/interfaces/network_status_service.dart';
import 'package:construculator/libraries/network_status/network_status_module.dart';
import 'package:construculator/libraries/network_status/network_status_service_impl.dart';
import 'package:construculator/libraries/network_status/testing/fake_connectivity_sdk.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

// A single module graph for the whole file: flutter_modular keeps bind
// registrations alive across destroy()/init() within one process, so
// re-initialising per test would resolve the service from the previous test.
void main() {
  final connectivity = FakeConnectivitySdk();

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    Modular.init(_NetworkStatusTestModule());
    Modular.replaceInstance<ConnectivitySdk>(connectivity);
  });

  tearDownAll(() {
    Modular.destroy();
    connectivity.dispose();
  });

  group('NetworkStatusModule', () {
    test('binds one shared NetworkStatusService', () {
      final first = Modular.get<NetworkStatusService>();
      final second = Modular.get<NetworkStatusService>();

      expect(first, same(second));
    });

    test('releases the service when its binding is disposed', () async {
      final service = Modular.get<NetworkStatusService>();
      await (service as NetworkStatusServiceImpl).ready;
      expect(connectivity.hasListener, isTrue);

      final closed = service.changes.toList();
      Modular.dispose<NetworkStatusServiceImpl>();
      await closed;

      expect(connectivity.hasListener, isFalse);
    });
  });
}

class _NetworkStatusTestModule extends Module {
  @override
  List<Module> get imports => [NetworkStatusModule()];
}
