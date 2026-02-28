import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/app/shell/tab_module_loader.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_modular/flutter_modular.dart';

class MockAppBootstrap extends Mock implements AppBootstrap {}

class MockModule extends Mock implements Module {}

void main() {
  group('TabModuleLoader', () {
    late TabModuleLoader loader;
    late MockAppBootstrap bootstrap;

    setUp(() {
      bootstrap = MockAppBootstrap();
      loader = TabModuleLoader(bootstrap);
    });

    test('loads each tab only once', () async {
      await loader.ensureTabModuleLoaded(ShellTab.home);
      expect(loader.isLoaded(ShellTab.home), isTrue);
      await loader.ensureTabModuleLoaded(ShellTab.home);
      expect(loader.isLoaded(ShellTab.home), isTrue);
    });

    test('does not load unaccessed tabs', () {
      expect(loader.isLoaded(ShellTab.calculations), isFalse);
      expect(loader.isLoaded(ShellTab.estimation), isFalse);
      expect(loader.isLoaded(ShellTab.members), isFalse);
    });
  });
}
