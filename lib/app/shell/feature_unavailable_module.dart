import 'package:construculator/app/shell/feature_unavailable_page.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Route module that renders [FeatureUnavailablePage] at its mount path.
///
/// `ShellModule` mounts this at an optional feature's base path on a build
/// that excludes that feature, so a deep link there resolves to a real page.
/// It mirrors the shape of the feature's own route module, which is what
/// keeps the destination reachable as a top-level route rather than a child
/// of the shell that has no outlet to mount into.
class FeatureUnavailableModule extends Module {
  @override
  void routes(RouteManager r) {
    r.child('/', child: (_) => const FeatureUnavailablePage());
  }
}
