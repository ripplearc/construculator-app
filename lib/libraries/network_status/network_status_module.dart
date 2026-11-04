import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:construculator/libraries/network_status/connectivity_sdk_impl.dart';
import 'package:construculator/libraries/network_status/interfaces/connectivity_sdk.dart';
import 'package:construculator/libraries/network_status/interfaces/network_status_service.dart';
import 'package:construculator/libraries/network_status/network_status_service_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Module providing [NetworkStatusService].
///
/// Bound as a lazy singleton so every caller sees the same status and the app
/// holds one subscription to the operating system.
class NetworkStatusModule extends Module {
  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<ConnectivitySdk>(
      () => ConnectivitySdkImpl(connectivity: Connectivity()),
    );
    i.addLazySingleton<NetworkStatusServiceImpl>(
      () => NetworkStatusServiceImpl(connectivitySdk: i.get()),
      config: BindConfig(onDispose: (service) => service.dispose()),
    );
    i.addLazySingleton<NetworkStatusService>(
      () => i.get<NetworkStatusServiceImpl>(),
    );
  }
}
