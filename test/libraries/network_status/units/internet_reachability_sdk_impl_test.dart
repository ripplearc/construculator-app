// ignore_for_file: no_direct_instantiation
import 'package:construculator/libraries/network_status/internet_reachability_sdk_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

void main() {
  final option = InternetCheckOption(uri: Uri.parse('https://example.test'));
  var isEndpointUp = true;
  late InternetReachabilitySdkImpl sdk;

  setUp(() {
    isEndpointUp = true;
    sdk = InternetReachabilitySdkImpl(
      checkInterval: const Duration(seconds: 30),
      connection: InternetConnection.createInstance(
        useDefaultOptions: false,
        customCheckOptions: [option],
        customConnectivityCheck: (option) async =>
            InternetCheckResult(option: option, isSuccess: isEndpointUp),
      ),
    );
    addTearDown(sdk.dispose);
  });

  group('InternetReachabilitySdkImpl', () {
    test('reports reachable when the endpoint answers', () async {
      expect(await sdk.checkReachable(), isTrue);
    });

    test('reports unreachable when the endpoint does not answer', () async {
      isEndpointUp = false;

      expect(await sdk.checkReachable(), isFalse);
    });
  });
}
