import 'package:construculator/libraries/url_launcher/interfaces/url_launcher.dart';
import 'package:construculator/libraries/url_launcher/url_launcher_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';

class UrlLauncherModule extends Module {
  @override
  void exportedBinds(Injector i) {
    i.add<UrlLauncher>(() => UrlLauncherImpl());
  }
}
