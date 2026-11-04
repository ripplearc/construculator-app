import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/network_status/connectivity_sdk_impl.dart';
import 'package:construculator/libraries/network_status/interfaces/connectivity_sdk.dart';
import 'package:construculator/libraries/network_status/interfaces/internet_reachability_sdk.dart';
import 'package:construculator/libraries/network_status/interfaces/network_status_service.dart';
import 'package:construculator/libraries/network_status/internet_reachability_sdk_impl.dart';
import 'package:construculator/libraries/network_status/network_status_service_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Module providing [NetworkStatusService].
///
/// Bound as a lazy singleton so every caller sees the same status and the app
/// holds one set of subscriptions and one timer.
class NetworkStatusModule extends Module {
  // TODO: [CA-1420] Point this at the hosted Supabase health URL
  // https://ripplearc.youtrack.cloud/issue/CA-1420
  static const _reachabilityUrl = 'https://one.one.one.one';
  static const _reachabilityCheckInterval = Duration(seconds: 30);

  /// Bootstrap used to resolve the app lifecycle.
  final AppBootstrap appBootstrap;

  /// Creates a [NetworkStatusModule].
  NetworkStatusModule(this.appBootstrap);

  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<ConnectivitySdk>(
      () => ConnectivitySdkImpl(connectivity: Connectivity()),
    );
    i.addLazySingleton<InternetReachabilitySdkImpl>(
      () => InternetReachabilitySdkImpl(
        checkInterval: _reachabilityCheckInterval,
        connection: InternetConnection.createInstance(
          useDefaultOptions: false,
          customCheckOptions: [
            InternetCheckOption(uri: Uri.parse(_reachabilityUrl)),
          ],
        ),
      ),
      config: BindConfig(onDispose: (sdk) => sdk.dispose()),
    );
    i.addLazySingleton<InternetReachabilitySdk>(
      () => i.get<InternetReachabilitySdkImpl>(),
    );
    i.addLazySingleton<NetworkStatusServiceImpl>(
      () => NetworkStatusServiceImpl(
        connectivitySdk: i.get(),
        reachabilitySdk: i.get(),
        appLifecycle: appBootstrap.appLifecycleWrapper,
      ),
      config: BindConfig(onDispose: (service) => service.dispose()),
    );
    i.addLazySingleton<NetworkStatusService>(
      () => i.get<NetworkStatusServiceImpl>(),
    );
  }
}
