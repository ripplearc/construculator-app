import 'package:construculator/libraries/toast/toast.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ToastModule extends Module {
  @override
  void exportedBinds(Injector i) {
    i.addSingleton<CToast>(CToast.new);
  }
}
